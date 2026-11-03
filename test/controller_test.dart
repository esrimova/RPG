import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_life_rpg/src/data/local_store.dart';
import 'package:personal_life_rpg/src/data/remote_store.dart';
import 'package:personal_life_rpg/src/domain/apply.dart';
import 'package:personal_life_rpg/src/domain/models.dart';
import 'package:personal_life_rpg/src/state/app_controller.dart';

/// Behaves like the real workflow: one run per dispatch applies the batch in
/// order, each operation validated against the state left by the previous one,
/// and writes one status file per operation. An operation id that already has
/// a status is skipped (idempotent resend). Status files appear after
/// [pollsUntilDone] polls of that id.
class FakeRemote implements RemoteStore {
  Snapshot data = Snapshot.empty;
  final Map<String, OpResult> results = {};
  final Map<String, int> polls = {};
  final List<List<Operation>> batches = [];
  int pollsUntilDone = 2;
  bool offline = false;

  /// Goes offline once this many batches have been accepted.
  int? offlineAfterBatches;

  /// The next accepted batch is received but its workflow never runs.
  bool dropNextBatch = false;

  List<Operation> get dispatched => batches.expand((b) => b).toList();

  @override
  Future<void> dispatchBatch(List<Operation> ops) async {
    if (offlineAfterBatches != null && batches.length >= offlineAfterBatches!) offline = true;
    if (offline) throw RemoteException('No connection');
    batches.add(List.of(ops));
    if (dropNextBatch) {
      dropNextBatch = false;
      return;
    }
    for (final op in ops) {
      if (results.containsKey(op.id)) continue; // already applied: never twice
      final r = applyOperation(data, op);
      if (r.ok) {
        data = r.snapshot;
        results[op.id] = const OpResult(OpOutcome.success, 'ok');
      } else {
        results[op.id] = OpResult(OpOutcome.rejected, 'Validation failed: ${r.error!}');
      }
    }
  }

  @override
  Future<OpResult> status(String id) async {
    if (offline) throw RemoteException('No connection');
    final n = polls[id] = (polls[id] ?? 0) + 1;
    if (n < pollsUntilDone) return const OpResult(OpOutcome.pending, '');
    return results[id] ?? const OpResult(OpOutcome.pending, '');
  }

  @override
  Future<Snapshot> pull() async {
    if (offline) throw RemoteException('No connection');
    final gate = pullGate;
    if (gate != null) {
      if (!pullStarted.isCompleted) pullStarted.complete();
      await gate.future;
    }
    return data;
  }

  /// When set, pull() waits for it (signalling [pullStarted] first).
  Completer<void>? pullGate;
  final Completer<void> pullStarted = Completer<void>();

  @override
  Future<ConnectionReport> check() async => const ConnectionReport(ok: true, message: 'ok', workflowInstalled: true, canWrite: true);
}

Branch branch([String id = 'b1', String name = 'Physical']) =>
    Branch(id: id, name: name, color: 1, iconCodePoint: 1, createdAt: DateTime(2026));

Activity activity([String id = 'a1', String branchId = 'b1']) => Activity(
    id: id,
    branchId: branchId,
    name: 'Run $id',
    color: 1,
    iconCodePoint: 1,
    fields: const [ActivityField(id: 'min', name: 'Minutes', type: FieldType.duration)],
    createdAt: DateTime(2026));

Operation rawOp(String id, OpAction a, EntityType t, String entityId, Map<String, dynamic> payload,
        {bool dispatched = false}) =>
    Operation(
        id: id,
        action: a,
        type: t,
        entityId: entityId,
        payload: payload,
        createdAt: DateTime(2026),
        dispatched: dispatched,
        localDate: '2026-11-03');

late SharedPreferences prefs;

Future<(AppController, FakeRemote)> setup({
  bool connected = true,
  List<Operation> ops = const [],
  Snapshot base = Snapshot.empty,
  FakeRemote? remote,
}) async {
  SharedPreferences.setMockInitialValues({});
  prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs, MemorySecretStore());
  if (connected) await store.saveGithub(const GithubConfig(repo: 'o/r', pat: 't'));
  await store.saveBase(base);
  await store.saveOps(ops);
  final r = remote ?? FakeRemote();
  final c = AppController(store, (_) => r, pollDelays: [0, 0, 0, 0], pollUnit: Duration.zero);
  await c.init();
  await Future<void>.delayed(Duration.zero);
  return (c, r);
}

final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$');

void main() {
  Operation chunkOp(int i, {String pad = ''}) => Operation(
      id: 'op$i',
      action: OpAction.create,
      type: EntityType.branch,
      entityId: 'b$i',
      payload: {'name': pad},
      createdAt: DateTime(2026),
      localDate: '2026-11-03');

  test('RemoteStore.chunk splits by count, in order', () {
    final ops = [for (var i = 0; i < 60; i++) chunkOp(i)];
    final batches = RemoteStore.chunk(ops);
    expect(batches.map((b) => b.length), [25, 25, 10]);
    expect(batches.expand((b) => b).map((o) => o.id), ops.map((o) => o.id));
  });

  test('RemoteStore.chunk puts an oversized operation alone', () {
    final big = chunkOp(1, pad: 'x' * 49000);
    final ops = [chunkOp(0), big, chunkOp(2)];
    final batches = RemoteStore.chunk(ops);
    expect(batches.map((b) => b.map((o) => o.id).toList()), [
      ['op0'],
      ['op1'],
      ['op2'],
    ]);
  });

  test('RemoteStore.chunk accumulates bytes across mid-size operations', () {
    // each ~20 KB: two fit under 48 KB, the third starts a new batch
    final ops = [for (var i = 0; i < 3; i++) chunkOp(i, pad: 'x' * 20000)];
    final batches = RemoteStore.chunk(ops);
    expect(batches.map((b) => b.map((o) => o.id).toList()), [
      ['op0', 'op1'],
      ['op2'],
    ]);
  });

  test('RemoteStore.chunk of nothing is no batches', () {
    expect(RemoteStore.chunk(const []), isEmpty);
  });

  test('local-only mode stores data without GitHub', () async {
    final (c, _) = await setup(connected: false);
    final r = await c.saveBranch(branch(), isNew: true);
    expect(r.ok, isTrue);
    expect(c.state.view.branches, hasLength(1));
    expect(c.state.ops, isEmpty);
    expect(await c.pushNow(), isNull);
  });

  test('submitting while connected sends nothing and keeps the item in the view', () async {
    final (c, remote) = await setup();
    final r = await c.saveBranch(branch(), isNew: true);
    expect(r.outcome, OpOutcome.success);
    expect(r.message, 'Saved - waiting for push');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(remote.batches, isEmpty);
    expect(remote.polls, isEmpty);
    expect(c.state.view.branches.single.name, 'Physical');
    expect(c.state.pendingCount, 1);
  });

  test('every operation carries a strict YYYY-MM-DD local date', () async {
    final (c, _) = await setup();
    await c.saveBranch(branch(), isNew: true);
    await c.saveActivity(activity(), isNew: true);
    await c.deleteActivity('a1');
    for (final op in c.state.ops) {
      expect(op.localDate, matches(_dateRe));
    }
  });

  test('locally invalid change is rejected before queueing', () async {
    final s = Snapshot(branches: [branch('other', 'Physical')]);
    final (c, _) = await setup(base: s, remote: FakeRemote()..data = s);
    final r = await c.saveBranch(branch('b2', 'physical'), isNew: true);
    expect(r.outcome, OpOutcome.rejected);
    expect(c.state.ops, isEmpty);
  });

  test('init never dispatches, even with pending operations, but pulls', () async {
    final remote = FakeRemote()..data = Snapshot(branches: [branch('x', 'Mind')]);
    final (c, _) = await setup(
        remote: remote,
        ops: [rawOp('op1', OpAction.create, EntityType.branch, 'b1', branch().toJson())]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(remote.batches, isEmpty);
    expect(c.state.ops, hasLength(1));
    expect(c.state.view.branches.map((b) => b.id), containsAll(['x', 'b1']));
  });

  test('pushNow sends all pending in order and leaves the queue empty', () async {
    final (c, remote) = await setup();
    await c.saveBranch(branch(), isNew: true);
    await c.saveActivity(activity(), isNew: true);
    await c.addRecord(Record(
        id: 'r1', activityId: 'a1', branchId: 'b1', timestamp: DateTime(2026), values: {'min': 1800}, xpEarned: 10));
    final entry = await c.pushNow();
    expect(entry, isNotNull);
    expect(remote.batches, hasLength(1));
    expect(remote.dispatched.map((o) => o.type.name), ['branch', 'activity', 'record']);
    expect(remote.dispatched.every((o) => _dateRe.hasMatch(o.localDate)), isTrue);
    expect(c.state.ops, isEmpty);
    expect(remote.data.records, hasLength(1));
    expect(c.state.view.records, hasLength(1));
    expect(c.state.syncing, isFalse);
    expect(c.state.lastSync, isNotNull);
  });

  test('pushNow twice in a row sends nothing the second time', () async {
    final (c, remote) = await setup();
    await c.saveBranch(branch(), isNew: true);
    await c.pushNow();
    expect(await c.pushNow(), isNull);
    expect(remote.batches, hasLength(1));
    expect(c.state.pushLog, hasLength(1));
  });

  test('a second pushNow while one runs returns null', () async {
    final (c, remote) = await setup();
    await c.saveBranch(branch(), isNew: true);
    final first = c.pushNow();
    expect(await c.pushNow(), isNull);
    expect(c.state.syncing, isTrue);
    expect(await first, isNotNull);
    expect(remote.batches, hasLength(1));
  });

  test('the log gets one entry per push with correct counts, persisted newest first', () async {
    final (c, remote) = await setup();
    await c.saveBranch(branch(), isNew: true);
    await c.saveBranch(branch('b2', 'Mind'), isNew: true);
    final e1 = await c.pushNow();
    expect((e1!.sent, e1.succeeded, e1.rejected, e1.failed), (2, 2, 0, 0));
    // remote gains a clash the app has not pulled: rejected server-side
    remote.data = remote.data.copyWith(branches: [...remote.data.branches, branch('x', 'Social')]);
    await c.saveBranch(branch('b3', 'Social'), isNew: true);
    await c.saveBranch(branch('b4', 'Work'), isNew: true);
    final e2 = await c.pushNow();
    expect((e2!.sent, e2.succeeded, e2.rejected, e2.failed), (2, 1, 1, 0));
    expect(c.state.pushLog, hasLength(2));
    expect(c.state.pushLog.first.time.isBefore(c.state.pushLog.last.time), isFalse);
    expect(c.state.pushLog.first.rejected, 1);
    final stored = LocalStore(prefs, MemorySecretStore()).loadPushLog();
    expect(stored.map((e) => e.rejected), [1, 0]);
    expect(stored.first.sent, 2);
  });

  test('push log keeps at most 50 entries', () async {
    final (c, _) = await setup();
    await c.saveBranch(branch(), isNew: true);
    await c.pushNow();
    for (var i = 0; i < 51; i++) {
      await c.saveBranch(branch('b1', 'Physical $i'), isNew: false);
      await c.pushNow();
    }
    expect(c.state.pushLog, hasLength(50));
    expect(LocalStore(prefs, MemorySecretStore()).loadPushLog(), hasLength(50));
  });

  test('a rejected operation is dropped with a notice naming the reason; dependents rejected too', () async {
    final (c, remote) = await setup();
    remote.data = Snapshot(branches: [branch('x', 'Physical')]);
    await c.saveBranch(branch('b2', 'Physical'), isNew: true);
    await c.saveActivity(activity('a1', 'b2'), isNew: true);
    final e = await c.pushNow();
    expect(e!.rejected, 2);
    expect(c.state.ops, isEmpty);
    expect(c.state.view.branches.map((b) => b.id), ['x']);
    expect(c.state.view.activities, isEmpty);
    expect(c.state.notice, contains('not saved'));
    expect(c.state.notice, contains('already exists'));
  });

  test('a failed operation is dropped and counted as failed', () async {
    final (c, remote) = await setup();
    await c.saveBranch(branch(), isNew: true);
    final opId = c.state.ops.single.id;
    remote.results[opId] = const OpResult(OpOutcome.failed, 'Workflow crashed');
    final e = await c.pushNow();
    expect((e!.succeeded, e.rejected, e.failed), (0, 0, 1));
    expect(c.state.ops, isEmpty);
    expect(c.state.notice, contains('Workflow crashed'));
  });

  test('offline mid-push keeps unsent ops queued and confirmed ones confirmed', () async {
    final (c, remote) = await setup();
    for (var i = 0; i < 30; i++) {
      await c.saveBranch(branch('b$i', 'B$i'), isNew: true);
    }
    remote.offlineAfterBatches = 1;
    final e = await c.pushNow();
    expect(e, isNotNull);
    expect(e!.succeeded, 25);
    expect(remote.data.branches, hasLength(25));
    expect(c.state.ops, hasLength(5));
    expect(c.state.ops.every((o) => !o.dispatched), isTrue);
    expect(c.state.base.branches, hasLength(25));
    expect(c.state.view.branches, hasLength(30));
    expect(c.state.notice, contains('No connection'));
    expect(c.state.syncing, isFalse);
    // persisted the same way
    final store = LocalStore(prefs, MemorySecretStore());
    expect(store.loadOps(), hasLength(5));
    expect(store.loadBase().branches, hasLength(25));

    remote.offline = false;
    remote.offlineAfterBatches = null;
    await c.pushNow();
    expect(c.state.ops, isEmpty);
    expect(remote.data.branches, hasLength(30));
    expect(remote.dispatched.map((o) => o.entityId).toSet(), hasLength(30));
  });

  test('30 pending operations produce two dispatchBatch calls', () async {
    final (c, remote) = await setup();
    for (var i = 0; i < 30; i++) {
      await c.saveBranch(branch('b$i', 'B$i'), isNew: true);
    }
    await c.pushNow();
    expect(remote.batches.map((b) => b.length), [25, 5]);
    expect(c.state.ops, isEmpty);
  });

  test('consecutive updates to the same entity are coalesced into the latest one', () async {
    final (c, remote) = await setup();
    await c.saveBranch(branch(), isNew: true);
    await c.saveBranch(branch('b1', 'Body'), isNew: false);
    await c.saveBranch(branch('b1', 'Strength'), isNew: false);
    await c.pushNow();
    expect(remote.dispatched.map((o) => o.action.name), ['create', 'update']);
    expect(remote.dispatched.last.payload['name'], 'Strength');
    expect(remote.data.branches.single.name, 'Strength');
    expect(c.state.view.branches.single.name, 'Strength');
  });

  test('coalescing never merges create+update, non-consecutive updates or dispatched ops', () async {
    final b1 = branch();
    final b2 = branch('b2', 'Mind');
    final remote = FakeRemote()..data = Snapshot(branches: [b1, b2]);
    final (c, _) = await setup(remote: remote, base: Snapshot(branches: [b1, b2]), ops: [
      rawOp('u0', OpAction.update, EntityType.branch, 'b1', branch('b1', 'A').toJson(), dispatched: true),
      rawOp('u1', OpAction.update, EntityType.branch, 'b1', branch('b1', 'B').toJson()),
      rawOp('u2', OpAction.update, EntityType.branch, 'b2', branch('b2', 'C').toJson()),
      rawOp('u3', OpAction.update, EntityType.branch, 'b1', branch('b1', 'D').toJson()),
      rawOp('u4', OpAction.update, EntityType.branch, 'b1', branch('b1', 'E').toJson()),
    ]);
    // u0 was dispatched but its workflow never ran: it gets re-sent after polling
    await c.pushNow();
    expect(remote.dispatched.map((o) => o.id), ['u0', 'u1', 'u2', 'u4']);
    expect(remote.data.branches.map((b) => b.name), ['E', 'C']);
  });

  test('updates are not coalesced when the latest alone would be judged differently', () async {
    // remove t2 + add t3, then check t3: fine step by step, but the latest alone
    // compared with the base "completes the quest by removing a task".
    QuestTask t(String id, bool done) =>
        QuestTask(id: id, name: id, date: '2026-11-10', doneAt: done ? DateTime(2026, 11, 3) : null);
    Quest q(List<QuestTask> tasks) => Quest(
        id: 'q1', name: 'Q', startDate: '2026-11-01', endDate: '2099-11-30', totalXp: 10, tasks: tasks, createdAt: DateTime(2026));
    final base = Snapshot(quests: [q([t('t1', true), t('t2', false)])]);
    final remote = FakeRemote()..data = base;
    final (c, _) = await setup(remote: remote, base: base);
    final r1 = await c.submit(rawOp('u1', OpAction.update, EntityType.quest, 'q1', q([t('t1', true), t('t3', false)]).toJson()));
    final r2 = await c.submit(rawOp('u2', OpAction.update, EntityType.quest, 'q1', q([t('t1', true), t('t3', true)]).toJson()));
    expect([r1.ok, r2.ok], [true, true]);
    final e = await c.pushNow();
    expect(remote.dispatched.map((o) => o.id), ['u1', 'u2']);
    expect(e!.succeeded, 2);
    expect(remote.data.quests.single.tasks.map((x) => x.id), ['t1', 't3']);
  });

  test('an operation already dispatched is checked via status and not re-dispatched when it has one', () async {
    final remote = FakeRemote()..data = Snapshot(branches: [branch()]);
    remote.results['op1'] = const OpResult(OpOutcome.success, 'ok');
    final (c, _) = await setup(
        remote: remote, ops: [rawOp('op1', OpAction.create, EntityType.branch, 'b1', branch().toJson(), dispatched: true)]);
    final e = await c.pushNow();
    expect(remote.polls['op1'], greaterThan(0));
    expect(remote.batches, isEmpty);
    expect(e!.succeeded, 1);
    expect(c.state.ops, isEmpty);
    expect(c.state.view.branches, hasLength(1));
  });

  test('an already-dispatched operation with no status after polling is re-dispatched once', () async {
    final remote = FakeRemote();
    final (c, _) = await setup(
        remote: remote, ops: [rawOp('op1', OpAction.create, EntityType.branch, 'b1', branch().toJson(), dispatched: true)]);
    final e = await c.pushNow();
    expect(remote.batches.map((b) => b.map((o) => o.id).toList()), [
      ['op1']
    ]);
    expect(e!.succeeded, 1);
    expect(remote.data.branches, hasLength(1));
    expect(c.state.ops, isEmpty);
  });

  test('a batch whose workflow never runs stays queued as dispatched; next push checks first', () async {
    final (c, remote) = await setup();
    await c.saveBranch(branch(), isNew: true);
    remote.dropNextBatch = true;
    final e = await c.pushNow();
    expect(e!.succeeded, 0);
    expect(c.state.ops.single.dispatched, isTrue);
    expect(c.state.view.branches, hasLength(1));
    // the workflow eventually ran: next push only checks the status
    final op = c.state.ops.single;
    remote.data = Snapshot(branches: [branch()]);
    remote.results[op.id] = const OpResult(OpOutcome.success, 'ok');
    await c.pushNow();
    expect(remote.batches, hasLength(1));
    expect(c.state.ops, isEmpty);
  });

  test('progress done reaches total and is updated after each resolved operation', () async {
    final (c, _) = await setup();
    for (var i = 0; i < 3; i++) {
      await c.saveBranch(branch('b$i', 'B$i'), isNew: true);
    }
    final seen = <String>[];
    c.addListener((st) {
      final p = st.push;
      if (p.running) seen.add('${p.done}/${p.total}');
    }, fireImmediately: false);
    await c.pushNow();
    expect(seen.toSet().toList(), ['0/3', '1/3', '2/3', '3/3']);
    expect(c.state.push.running, isFalse);
    expect(c.state.push.done, c.state.push.total);
  });

  test('accepted operations never vanish from the view while a push runs', () async {
    final (c, _) = await setup();
    await c.saveBranch(branch(), isNew: true);
    await c.saveActivity(activity(), isNew: true);
    final seen = <String>[];
    c.addListener((st) => seen.add('${st.view.branches.length}/${st.view.activities.length}'));
    await c.pushNow();
    expect(seen.where((x) => x != '1/1'), isEmpty, reason: 'saw $seen');
  });

  test('changes made during a push stay queued for the next one', () async {
    final (c, remote) = await setup();
    await c.saveBranch(branch(), isNew: true);
    final f = c.pushNow();
    await c.saveBranch(branch('b2', 'Mind'), isNew: true);
    await f;
    expect(c.state.ops.map((o) => o.entityId), ['b2']);
    expect(c.state.view.branches, hasLength(2));
    await c.pushNow();
    expect(remote.data.branches, hasLength(2));
    expect(c.state.ops, isEmpty);
  });

  test('connecting merges local data into the queue but does not push', () async {
    final (c, remote) = await setup(connected: false);
    await c.saveBranch(branch(), isNew: true);
    final seen = <String>[];
    c.addListener((st) => seen.add('${st.view.branches.length}'));
    final report = await c.connect(const GithubConfig(repo: 'o/r', pat: 't'));
    expect(report.ok, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(remote.batches, isEmpty);
    expect(c.state.ops, hasLength(1));
    expect(c.state.view.branches, hasLength(1));
    expect(seen.where((x) => x != '1'), isEmpty, reason: 'saw $seen');
    await c.pushNow();
    expect(remote.data.branches, hasLength(1));
    expect(c.state.ops, isEmpty);
  });

  test('disconnect keeps the view and sends nothing', () async {
    final (c, remote) = await setup();
    await c.saveBranch(branch(), isNew: true);
    await c.disconnect();
    expect(remote.batches, isEmpty);
    expect(c.state.view.branches, hasLength(1));
    expect(c.state.ops, isEmpty);
  });

  test('disconnecting during a push keeps the view and ends the push cleanly', () async {
    final (c, _) = await setup();
    await c.saveBranch(branch(), isNew: true);
    await c.saveBranch(branch('b2', 'Mind'), isNew: true);
    final f = c.pushNow();
    await c.disconnect();
    await f;
    expect(c.state.view.branches, hasLength(2));
    expect(c.state.base.branches, hasLength(2));
    expect(c.state.ops, isEmpty);
    expect(c.state.syncing, isFalse);
    expect(c.state.push.running, isFalse);
  });

  test('disconnect while the final pull is in flight persists the kept view and an empty queue', () async {
    // The pull is released at several points during disconnect's own awaits.
    for (var k = 0; k < 40; k++) {
      final (c, remote) = await setup();
      await c.saveBranch(branch(), isNew: true);
      remote.pullGate = Completer<void>();
      final push = c.pushNow();
      await c.saveBranch(branch('b2', 'Mind'), isNew: true); // queued during the push
      await remote.pullStarted.future;
      final keep = c.state.view.branches.map((b) => b.id).toList();
      expect(keep, ['b1', 'b2']);
      remote.data = Snapshot(branches: [branch('x', 'Remote only')]); // diverged remote
      final d = c.disconnect();
      for (var j = 0; j < k; j++) {
        await Future<void>.microtask(() {}); // one microtask hop at a time
      }
      remote.pullGate!.complete();
      await d;
      await push;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final store = LocalStore(prefs, MemorySecretStore());
      expect(store.loadBase().branches.map((b) => b.id), keep, reason: 'k=$k persisted base');
      expect(store.loadOps(), isEmpty, reason: 'k=$k persisted ops');
      expect(c.state.view.branches.map((b) => b.id), keep, reason: 'k=$k view');
      expect(c.state.github.isConfigured, isFalse);
    }
  });

  test('syncNow pushes (thin wrapper until the UI moves to pushNow)', () async {
    final (c, remote) = await setup();
    await c.saveBranch(branch(), isNew: true);
    await c.syncNow();
    expect(remote.batches, hasLength(1));
    expect(c.state.ops, isEmpty);
  });
}
