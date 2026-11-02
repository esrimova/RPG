import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_life_rpg/src/data/local_store.dart';
import 'package:personal_life_rpg/src/data/remote_store.dart';
import 'package:personal_life_rpg/src/domain/apply.dart';
import 'package:personal_life_rpg/src/domain/models.dart';
import 'package:personal_life_rpg/src/state/app_controller.dart';

/// Behaves like the real workflow: result appears after [pollsUntilDone] polls.
class FakeRemote implements RemoteStore {
  Snapshot data = Snapshot.empty;
  final Map<String, OpResult> results = {};
  final Map<String, int> polls = {};
  final List<Operation> dispatched = [];
  int pollsUntilDone = 2;
  bool offline = false;

  @override
  Future<void> dispatch(Operation op) async {
    if (offline) throw RemoteException('No connection');
    dispatched.add(op);
    final r = applyOperation(data, op);
    if (r.ok) {
      data = r.snapshot;
      results[op.id] = const OpResult(OpOutcome.success, 'ok');
    } else {
      results[op.id] = OpResult(OpOutcome.rejected, r.error!);
    }
  }

  @override
  Future<OpResult> status(String id) async {
    final n = polls[id] = (polls[id] ?? 0) + 1;
    if (n < pollsUntilDone) return const OpResult(OpOutcome.pending, '');
    return results[id] ?? const OpResult(OpOutcome.pending, '');
  }

  @override
  Future<Snapshot> pull() async => data;

  @override
  Future<ConnectionReport> check() async => const ConnectionReport(ok: true, message: 'ok', workflowInstalled: true, canWrite: true);
}

Branch branch([String id = 'b1', String name = 'Physical']) =>
    Branch(id: id, name: name, color: 1, iconCodePoint: 1, createdAt: DateTime(2026));

Future<(AppController, FakeRemote)> setup({bool connected = true}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs, MemorySecretStore());
  if (connected) await store.saveGithub(const GithubConfig(repo: 'o/r', pat: 't'));
  final remote = FakeRemote();
  final c = AppController(store, (_) => remote, pollDelays: [0, 0, 0, 0], pollUnit: Duration.zero);
  await c.init();
  await Future<void>.delayed(Duration.zero);
  return (c, remote);
}

void main() {
  test('local-only mode stores data without GitHub', () async {
    final (c, _) = await setup(connected: false);
    final r = await c.saveBranch(branch(), isNew: true);
    expect(r.ok, isTrue);
    expect(c.state.view.branches, hasLength(1));
  });

  test('connected create waits for GitHub and ends in sync (the original bug)', () async {
    final (c, remote) = await setup();
    final r = await c.saveBranch(branch(), isNew: true);
    expect(r.outcome, OpOutcome.success);
    expect(remote.data.branches, hasLength(1));
    expect(c.state.ops, isEmpty);
    expect(c.state.base.branches, hasLength(1));
    expect(c.state.view.branches.single.name, 'Physical');
  });

  test('server rejection is reported and rolled back', () async {
    final (c, remote) = await setup();
    remote.data = Snapshot(branches: [branch('other', 'Physical')]);
    await c.syncNow();
    // locally unknown name clash is caught before sending
    final r = await c.saveBranch(branch('b2', 'physical'), isNew: true);
    expect(r.outcome, OpOutcome.rejected);
    expect(c.state.view.branches, hasLength(1));
  });

  test('server-side rejection removes the optimistic change', () async {
    final (c, remote) = await setup();
    // remote has an entity the app has not pulled yet
    remote.data = Snapshot(branches: [branch('x', 'Physical')]);
    final r = await c.saveBranch(branch('b2', 'Physical'), isNew: true);
    expect(r.outcome, OpOutcome.rejected);
    expect(c.state.ops, isEmpty);
    expect(c.state.view.branches.map((b) => b.id), ['x']);
    expect(c.state.notice, contains('not saved'));
  });

  test('offline keeps the change queued and visible', () async {
    final (c, remote) = await setup();
    remote.offline = true;
    final r = await c.saveBranch(branch(), isNew: true);
    expect(r.outcome, OpOutcome.failed);
    expect(c.state.ops, hasLength(1));
    expect(c.state.view.branches, hasLength(1));
    remote.offline = false;
    await c.syncNow();
    expect(c.state.ops, isEmpty);
    expect(remote.data.branches, hasLength(1));
  });

  test('connecting uploads data created before GitHub was linked', () async {
    final (c, remote) = await setup(connected: false);
    await c.saveBranch(branch(), isNew: true);
    final report = await c.connect(const GithubConfig(repo: 'o/r', pat: 't'));
    expect(report.ok, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(remote.data.branches, hasLength(1));
    expect(c.state.view.branches, hasLength(1));
  });

  test('data never disappears from the view while the first upload runs', () async {
    final (c, _) = await setup(connected: false);
    await c.saveBranch(branch(), isNew: true);
    await c.saveActivity(
        Activity(id: 'a1', branchId: 'b1', name: 'Run', color: 1, iconCodePoint: 1, fields: const [], createdAt: DateTime(2026)),
        isNew: true);
    final seen = <String>[];
    c.addListener((st) => seen.add('${st.view.branches.length}/${st.view.activities.length}'));
    await c.connect(const GithubConfig(repo: 'o/r', pat: 't'));
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(seen, isNotEmpty);
    expect(seen.where((x) => x != '1/1'), isEmpty, reason: 'saw $seen');
  });

  test('operations are sent in order', () async {
    final (c, remote) = await setup();
    final a = Activity(
        id: 'a1',
        branchId: 'b1',
        name: 'Run',
        color: 1,
        iconCodePoint: 1,
        fields: const [ActivityField(id: 'min', name: 'Minutes', type: FieldType.duration)],
        createdAt: DateTime(2026));
    final f1 = c.saveBranch(branch(), isNew: true);
    final f2 = c.saveActivity(a, isNew: true);
    final f3 = c.addRecord(Record(
        id: 'r1', activityId: 'a1', branchId: 'b1', timestamp: DateTime(2026), values: {'min': 1800}, xpEarned: 10));
    final results = await Future.wait([f1, f2, f3]);
    expect(results.every((r) => r.ok), isTrue, reason: results.map((r) => r.message).join('|'));
    expect(remote.dispatched.map((o) => o.type.name), ['branch', 'activity', 'record']);
  });
}
