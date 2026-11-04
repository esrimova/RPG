import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_rpg/src/data/local_store.dart';
import 'package:personal_life_rpg/src/data/remote_store.dart';
import 'package:personal_life_rpg/src/domain/apply.dart';
import 'package:personal_life_rpg/src/domain/models.dart';
import 'package:personal_life_rpg/src/domain/stats.dart';
import 'package:personal_life_rpg/src/state/app_controller.dart';
import 'package:personal_life_rpg/src/state/providers.dart';
import 'package:personal_life_rpg/src/ui/browser_page.dart';
import 'package:personal_life_rpg/src/ui/level_costs_page.dart';
import 'package:personal_life_rpg/src/ui/stats_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _NoRemote implements RemoteStore {
  @override
  Future<void> dispatchBatch(List<Operation> ops) async {}
  @override
  Future<OpResult> status(String id) async => const OpResult(OpOutcome.pending, '');
  @override
  Future<Snapshot> pull() async => Snapshot.empty;
  @override
  Future<ConnectionReport> check() async => const ConnectionReport(ok: true, message: 'ok');
}

final _activity = Activity(
  id: 'a',
  branchId: 'b',
  name: 'Run',
  color: 0xFF4CAF50,
  iconCodePoint: 0xe318,
  fields: const [ActivityField(id: 'f1', name: 'Km', type: FieldType.number)],
  createdAt: DateTime(2026),
);

Future<(AppController, Widget Function(Widget))> seeded() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = AppController(LocalStore(prefs, MemorySecretStore()), (_) => _NoRemote());
  await c.init();
  await c.saveBranch(Branch(id: 'b', name: 'Body', color: 0xFF4CAF50, iconCodePoint: 0xe318, createdAt: DateTime(2026)), isNew: true);
  await c.saveActivity(_activity, isNew: true);
  Widget wrap(Widget home) => ProviderScope(
        overrides: [
          prefsProvider.overrideWithValue(prefs),
          secretsProvider.overrideWithValue(MemorySecretStore()),
          appProvider.overrideWith((_) => c),
        ],
        child: MaterialApp(home: home),
      );
  return (c, wrap);
}

void bigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 3200);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

Record rec(String id, DateTime t, num km) =>
    Record(id: id, activityId: 'a', branchId: 'b', timestamp: t, values: {'f1': km}, xpEarned: 10);

StatEntry stat(String id, DateTime t, Map<String, num> v) => StatEntry(id: id, timestamp: t, values: v);

void main() {
  group('stats domain', () {
    test('nine stats are defined with the expected units', () {
      expect(statDefs.map((d) => d.key), ['weight', 'fat', 'wat', 'msl', 'bon', 'calo', 'pxfat', 'protein', 'bmi']);
      expect(statDef('weight')!.unit, 'Kg');
      expect(statDef('bon')!.unit, 'Kg');
      expect(statDef('fat')!.unit, '%');
    });

    test('validation mirrors the server', () {
      final t = DateTime(2026, 11, 4);
      expect(statError(stat('s', t, {'weight': 80.5})), isNull);
      expect(statError(stat('s', t, {})), isNotNull);
      expect(statError(stat('s', t, {'height': 180})), isNotNull);
      expect(statError(stat('s', t, {'weight': -1})), isNotNull);
      expect(statError(stat('s', t, {'fat': 101})), isNotNull);
      expect(statError(stat('s', t, {'bmi': 31})), isNull);
    });

    test('create, ordering, latest value per stat, delete; no edits', () {
      var s = Snapshot.empty;
      Operation op(OpAction a, StatEntry e) => Operation(
          id: 'o${e.id}${a.name}', action: a, type: EntityType.stat, entityId: e.id, payload: e.toJson(), createdAt: DateTime(2026));
      final e1 = stat('s1', DateTime(2026, 1, 5), {'weight': 82, 'fat': 20});
      final e2 = stat('s2', DateTime(2026, 2, 5), {'weight': 80});
      for (final e in [e1, e2]) {
        final r = applyOperation(s, op(OpAction.create, e));
        expect(r.ok, isTrue, reason: r.error);
        s = r.snapshot;
      }
      expect(applyOperation(s, op(OpAction.create, e1)).ok, isFalse);
      expect(applyOperation(s, op(OpAction.update, e1)).ok, isFalse);
      expect(statsNewestFirst(s.stats).first.id, 's2');
      expect(latestStatValues(s.stats), {'weight': 80, 'fat': 20}); // fat comes from the older entry
      s = applyOperation(s, op(OpAction.delete, e2)).snapshot;
      expect(latestStatValues(s.stats)['weight'], 82);
      expect(applyOperation(s, op(OpAction.delete, e2)).ok, isFalse);
    });

    test('JSON round trip through the snapshot', () {
      final s = Snapshot(stats: [stat('s1', DateTime.utc(2026, 1, 5, 8), {'weight': 82.5, 'bmi': 24})]);
      final back = Snapshot.fromJson(s.toJson());
      expect(back.stats.single.values, {'weight': 82.5, 'bmi': 24});
      expect(back.stats.single.timestamp, DateTime.utc(2026, 1, 5, 8));
    });
  });

  group('branch level points', () {
    test('level_costs round trips and is rejected when invalid', () {
      final b = Branch(id: 'b', name: 'B', color: 1, iconCodePoint: 1, createdAt: DateTime(2026), levelCosts: [500, 900]);
      expect(Branch.fromJson(b.toJson()).levelCosts, [500, 900]);
      expect(Branch.fromJson(b.copyWith(clearLevelCosts: true).toJson()).levelCosts, isNull);
      Operation op(Branch x) =>
          Operation(id: 'o', action: OpAction.create, type: EntityType.branch, entityId: x.id, payload: x.toJson(), createdAt: DateTime(2026));
      expect(applyOperation(Snapshot.empty, op(b)).ok, isTrue);
      expect(applyOperation(Snapshot.empty, op(b.copyWith(levelCosts: [500, 0]))).ok, isFalse);
    });
  });

  testWidgets('activity history: grouped by year and month, collapsible, newest open, record deletable', (tester) async {
    bigView(tester);
    final (c, wrap) = await seeded();
    await c.addRecord(rec('r1', DateTime(2025, 12, 20, 9), 1));
    await c.addRecord(rec('r2', DateTime(2026, 1, 10, 9), 2));
    await c.addRecord(rec('r3', DateTime(2026, 3, 5, 9), 3));
    await c.addRecord(rec('r4', DateTime(2026, 3, 6, 9), 4));
    await tester.pumpWidget(wrap(const ActivityHistoryPage(activityId: 'a')));
    await tester.pumpAndSettle();

    // newest year and month are open, everything else is collapsed
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('2025'), findsOneWidget);
    expect(find.text('March'), findsOneWidget);
    expect(find.textContaining('Km: 3'), findsOneWidget);
    expect(find.textContaining('Km: 4'), findsOneWidget);
    expect(find.text('January'), findsOneWidget);
    expect(find.textContaining('Km: 2'), findsNothing); // January is collapsed
    expect(find.text('December'), findsNothing); // 2025 is collapsed

    await tester.tap(find.text('January'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Km: 2'), findsOneWidget);
    await tester.tap(find.text('January'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Km: 2'), findsNothing);

    await tester.tap(find.text('2025'));
    await tester.pumpAndSettle();
    expect(find.text('December'), findsOneWidget);

    // delete a record: confirm, it disappears, and the month stays open
    await tester.tap(find.byTooltip('Delete record').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(c.state.view.records.map((r) => r.id), isNot(contains('r4')));
    expect(find.textContaining('Km: 4'), findsNothing);
    expect(find.textContaining('Km: 3'), findsOneWidget);
  });

  testWidgets('the History button on an activity opens the history page, apart from the entry card', (tester) async {
    bigView(tester);
    final (c, wrap) = await seeded();
    await c.addRecord(rec('r1', DateTime(2026, 1, 10, 9), 2));
    await tester.pumpWidget(wrap(Scaffold(body: ListView(children: [ActivityCard(activity: _activity)]))));
    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();
    expect(find.byType(ActivityHistoryPage), findsOneWidget);
    expect(find.byTooltip('Delete record'), findsOneWidget);
    expect(find.textContaining('Record  (+'), findsNothing); // the entry button is not on this page
  });

  testWidgets('stats page: saves an entry with only the filled stats, shows latest values', (tester) async {
    bigView(tester);
    final (c, wrap) = await seeded();
    await tester.pumpWidget(wrap(const StatsPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save stats'));
    await tester.pumpAndSettle();
    expect(find.text('Enter at least one stat.'), findsOneWidget);
    expect(c.state.view.stats, isEmpty);

    await tester.enterText(find.widgetWithText(TextField, 'Weight (Kg)'), '81,5');
    await tester.enterText(find.widgetWithText(TextField, 'FAT (%)'), '18');
    await tester.tap(find.text('Save stats'));
    await tester.pumpAndSettle();
    final e = c.state.view.stats.single;
    expect(e.values, {'weight': 81.5, 'fat': 18});
    expect(DateTime.now().difference(e.timestamp).inSeconds.abs() < 10, isTrue);
    expect(find.descendant(of: find.byKey(const ValueKey('latest-weight')), matching: find.text('81.5 Kg')), findsOneWidget);
    expect(find.descendant(of: find.byKey(const ValueKey('latest-bmi')), matching: find.text('-')), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'FAT (%)'), '150');
    await tester.tap(find.text('Save stats'));
    await tester.pumpAndSettle();
    expect(find.text('FAT cannot be more than 100.'), findsOneWidget);
    expect(c.state.view.stats, hasLength(1));
  });

  testWidgets('stats history: by year/month, newest open, entries deletable', (tester) async {
    bigView(tester);
    final (c, wrap) = await seeded();
    await c.addStat(stat('s1', DateTime(2025, 12, 1, 7), {'weight': 85}));
    await c.addStat(stat('s2', DateTime(2026, 4, 2, 7), {'weight': 80, 'fat': 17.5}));
    await c.addStat(stat('s3', DateTime(2026, 4, 9, 7), {'weight': 79}));
    await tester.pumpWidget(wrap(const StatsHistoryPage()));
    await tester.pumpAndSettle();
    expect(find.text('April'), findsOneWidget);
    expect(find.textContaining('Weight 79 Kg'), findsOneWidget);
    expect(find.textContaining('FAT 17.5 %'), findsOneWidget);
    expect(find.textContaining('Weight 85 Kg'), findsNothing); // 2025 collapsed
    await tester.tap(find.text('2025'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('December'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Weight 85 Kg'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete entry').first); // newest = s3
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(c.state.view.stats.map((e) => e.id).toSet(), {'s1', 's2'});
    expect(find.textContaining('Weight 79 Kg'), findsNothing);
  });

  testWidgets('level points page: shows the default, saves custom unequal costs on the branch', (tester) async {
    bigView(tester);
    final (c, wrap) = await seeded();
    await tester.pumpWidget(wrap(const LevelCostsPage(branchId: 'b')));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byKey(const ValueKey('cost-0'))).controller!.text, '500');
    expect(tester.widget<TextField>(find.byKey(const ValueKey('cost-1'))).controller!.text, '750');

    await tester.enterText(find.byKey(const ValueKey('cost-1')), '900');
    await tester.enterText(find.byKey(const ValueKey('cost-2')), '2000');
    await tester.ensureVisible(find.text('Save level points'));
    await tester.tap(find.text('Save level points'));
    await tester.pumpAndSettle();
    final costs = c.state.view.branches.single.levelCosts!;
    expect(costs.take(3), [500, 900, 2000]);
    expect(costs.length, 10);
  });

  testWidgets('level points page: rejects a non-positive cost and saves nothing', (tester) async {
    bigView(tester);
    final (c, wrap) = await seeded();
    await tester.pumpWidget(wrap(const LevelCostsPage(branchId: 'b')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('cost-2')), '0');
    await tester.ensureVisible(find.text('Save level points'));
    await tester.tap(find.text('Save level points'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Level 3 needs a whole number'), findsOneWidget);
    expect(c.state.view.branches.single.levelCosts, isNull);
  });
}
