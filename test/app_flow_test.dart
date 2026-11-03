import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_rpg/main.dart';
import 'dart:async';
import 'package:personal_life_rpg/src/data/local_store.dart';
import 'package:personal_life_rpg/src/data/remote_store.dart';
import 'package:personal_life_rpg/src/domain/apply.dart';
import 'package:personal_life_rpg/src/domain/goals.dart';
import 'package:personal_life_rpg/src/domain/models.dart';
import 'package:personal_life_rpg/src/ui/editors.dart';
import 'package:personal_life_rpg/src/ui/browser_page.dart';
import 'package:personal_life_rpg/src/state/app_controller.dart';
import 'package:personal_life_rpg/src/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Widget> app() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderScope(
    overrides: [
      prefsProvider.overrideWithValue(prefs),
      secretsProvider.overrideWithValue(MemorySecretStore()),
    ],
    child: const LifeRpgApp(),
  );
}

/// A repository that applies batches like the workflow; [gate] holds a dispatch.
class _Remote implements RemoteStore {
  Snapshot data = Snapshot.empty;
  final Map<String, OpResult> results = {};
  Completer<void>? gate;
  bool explode = false;
  bool rejectAll = false;
  @override
  Future<void> dispatchBatch(List<Operation> ops) async {
    if (gate != null) await gate!.future;
    if (explode) throw StateError('boom');
    for (final op in ops) {
      final r = applyOperation(data, op);
      if (r.ok) data = r.snapshot;
      results[op.id] = r.ok ? const OpResult(OpOutcome.success, 'ok') : OpResult(OpOutcome.rejected, r.error!);
    }
  }

  @override
  Future<OpResult> status(String id) async => results[id] ?? const OpResult(OpOutcome.pending, '');
  @override
  Future<Snapshot> pull() async => data;
  @override
  Future<ConnectionReport> check() async => const ConnectionReport(ok: true, message: 'ok');
}

/// A connected app with two changes waiting to be pushed.
Future<(Widget, _Remote)> connectedApp({int pending = 2}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final store = LocalStore(prefs, MemorySecretStore());
  await store.saveGithub(const GithubConfig(repo: 'o/r', pat: 't'));
  final remote = _Remote();
  final c = AppController(store, (_) => remote, pollDelays: [0, 0, 0, 0], pollUnit: Duration.zero);
  await c.init();
  for (var i = 0; i < pending; i++) {
    await c.saveBranch(Branch(id: 'b$i', name: 'Branch $i', color: 1, iconCodePoint: 1, createdAt: DateTime(2026)), isNew: true);
  }
  return (
    ProviderScope(overrides: [
      prefsProvider.overrideWithValue(prefs),
      secretsProvider.overrideWithValue(MemorySecretStore()),
      appProvider.overrideWith((_) => c),
    ], child: const LifeRpgApp()),
    remote
  );
}

/// A local-only controller with one branch and optionally one activity.
Future<(AppController, Widget Function(Widget))> seeded([Activity? activity]) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final c = AppController(LocalStore(prefs, MemorySecretStore()), (_) => _Remote());
  await c.init();
  await c.saveBranch(Branch(id: 'b', name: 'Body', color: 0xFF4CAF50, iconCodePoint: 0xe318, createdAt: DateTime(2026)), isNew: true);
  if (activity != null) await c.saveActivity(activity, isNew: true);
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

Activity goalActivity({double goal = 10, int baseXp = 10}) => Activity(
      id: 'a',
      branchId: 'b',
      name: 'Run',
      color: 0xFF4CAF50,
      iconCodePoint: 0xe318,
      baseXp: baseXp,
      fields: const [ActivityField(id: 'f1', name: 'Km', type: FieldType.number)],
      goal: goal,
      goalFieldId: 'f1',
      createdAt: DateTime(2026),
    );

void bigView(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 9000);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('goal UI: editor saves a goal on the only numeric field automatically', (tester) async {
    bigView(tester);
    final (c, wrap) = await seeded();
    await tester.pumpWidget(wrap(const ActivityEditorPage(branchId: 'b')));
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Run');
    await tester.tap(find.text('Add field'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Field name'), 'Km');
    await tester.enterText(find.widgetWithText(TextField, 'Goal'), '10');
    await tester.pumpAndSettle();
    expect(find.text('Goal field'), findsNothing);
    await tester.ensureVisible(find.text('Create activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create activity'));
    await tester.pumpAndSettle();
    final a = c.state.view.activities.single;
    expect(a.goal, 10);
    expect(a.goalFieldId, a.fields.single.id);
    expect(a.fields.single.required, isTrue);
  });

  testWidgets('goal UI: several numeric fields offer a selector; duration goal is minutes stored as seconds', (tester) async {
    bigView(tester);
    final (c, wrap) = await seeded();
    await tester.pumpWidget(wrap(const ActivityEditorPage(branchId: 'b')));
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Run');
    for (final n in ['Km', 'Time']) {
      await tester.tap(find.text('Add field'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Field name').last, n);
    }
    // second field becomes a duration
    await tester.ensureVisible(find.byType(DropdownButtonFormField<FieldType>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<FieldType>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duration').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Goal'), '30');
    await tester.pumpAndSettle();
    expect(find.text('Goal field'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Time').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create activity'));
    await tester.pumpAndSettle();
    final a = c.state.view.activities.single;
    expect(a.goal, 1800);
    expect(a.goalFieldId, a.fields.last.id);
  });

  testWidgets('goal UI: a goal without a numeric field is an error', (tester) async {
    bigView(tester);
    final (c, wrap) = await seeded();
    await tester.pumpWidget(wrap(const ActivityEditorPage(branchId: 'b')));
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Run');
    await tester.enterText(find.widgetWithText(TextField, 'Goal'), '10');
    await tester.ensureVisible(find.text('Create activity'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create activity'));
    await tester.pumpAndSettle();
    expect(find.textContaining('goal needs a number or duration field'), findsOneWidget);
    expect(c.state.view.activities, isEmpty);
  });

  testWidgets('goal UI: the goal field cannot be deleted or retyped while a goal is set', (tester) async {
    bigView(tester);
    final (_, wrap) = await seeded(goalActivity());
    await tester.pumpWidget(wrap(ActivityEditorPage(branchId: 'b', existing: goalActivity())));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Goal'), findsOneWidget);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.delete_outline)).onPressed, isNull);
    expect(tester.widget<DropdownButtonFormField<FieldType>>(find.byType(DropdownButtonFormField<FieldType>)).onChanged, isNull);
    // clearing the goal frees the field again
    await tester.enterText(find.widgetWithText(TextField, 'Goal'), '');
    await tester.pumpAndSettle();
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.delete_outline)).onPressed, isNotNull);
  });

  testWidgets('goal UI: record card previews points live and saves goal and xp', (tester) async {
    bigView(tester);
    final (c, wrap) = await seeded(goalActivity());
    await tester.pumpWidget(wrap(Scaffold(body: ListView(children: [ActivityCard(activity: goalActivity())]))));
    await tester.pumpAndSettle();
    expect(find.text('0 / 10 = 0% → +0 XP'), findsOneWidget);
    expect(find.text('Record  (+0 XP)'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Km'), '5');
    await tester.pump();
    expect(find.text('5 / 10 = 50% → +5 XP'), findsOneWidget);
    expect(find.text('Record  (+5 XP)'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Km'), '25');
    await tester.pump();
    expect(find.text('25 / 10 = 250% → +25 XP'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Km'), '5');
    await tester.pump();
    await tester.tap(find.textContaining('Record  ('));
    await tester.pumpAndSettle();
    expect(find.text('Recorded +5 XP'), findsOneWidget);
    final r = c.state.view.records.single;
    expect(r.xpEarned, goalXp(baseXp: 10, value: 5, goal: 10));
    expect(r.goal, 10);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('goal UI: editing the goal leaves earlier records untouched', (tester) async {
    bigView(tester);
    final (c, wrap) = await seeded(goalActivity());
    await tester.pumpWidget(wrap(Scaffold(body: ListView(children: [ActivityCard(activity: goalActivity())]))));
    await tester.enterText(find.widgetWithText(TextField, 'Km'), '5');
    await tester.tap(find.textContaining('Record  ('));
    await tester.pumpAndSettle();
    await c.saveActivity(goalActivity(goal: 20), isNew: false);
    final r = c.state.view.records.single;
    expect(r.xpEarned, 5);
    expect(r.goal, 10);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('goal UI: legacy optional goal field is required when recording', (tester) async {
    bigView(tester);
    final base = goalActivity();
    final legacy = base.copyWith(fields: const [ActivityField(id: 'f1', name: 'Km', type: FieldType.number, required: false)]);
    final (c, wrap) = await seeded(legacy);
    await tester.pumpWidget(wrap(Scaffold(body: ListView(children: [ActivityCard(activity: legacy)]))));
    await tester.tap(find.textContaining('Record  ('));
    await tester.pumpAndSettle();
    expect(find.text('Enter Km.'), findsOneWidget);
    expect(c.state.view.records, isEmpty);
  });

  testWidgets('goal UI: duration goal previews in minutes and saves seconds', (tester) async {
    bigView(tester);
    final dur = Activity(
        id: 'd', branchId: 'b', name: 'Plank', color: 0xFF4CAF50, iconCodePoint: 0xe318, baseXp: 10,
        fields: const [ActivityField(id: 'f1', name: 'Time', type: FieldType.duration)],
        goal: 1800, goalFieldId: 'f1', createdAt: DateTime(2026));
    final (c, wrap) = await seeded(dur);
    await tester.pumpWidget(wrap(Scaffold(body: ListView(children: [ActivityCard(activity: dur)]))));
    await tester.enterText(find.widgetWithText(TextField, 'Time - minutes'), '15');
    await tester.pump();
    expect(find.text('15 / 30 = 50% → +5 XP'), findsOneWidget);
    await tester.tap(find.textContaining('Record  ('));
    await tester.pumpAndSettle();
    final r = c.state.view.records.single;
    expect(r.xpEarned, 5);
    expect(r.goal, 1800);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('activities without a goal still earn base XP and show no preview', (tester) async {
    bigView(tester);
    final plain = Activity(
        id: 'p', branchId: 'b', name: 'Read', color: 0xFF4CAF50, iconCodePoint: 0xe318, baseXp: 7,
        fields: const [ActivityField(id: 'f1', name: 'Pages', type: FieldType.number)], createdAt: DateTime(2026));
    final (c, wrap) = await seeded(plain);
    await tester.pumpWidget(wrap(Scaffold(body: ListView(children: [ActivityCard(activity: plain)]))));
    expect(find.text('Record  (+7 XP)'), findsOneWidget);
    expect(find.textContaining('%'), findsNothing);
    await tester.enterText(find.widgetWithText(TextField, 'Pages'), '3');
    await tester.tap(find.textContaining('Record  ('));
    await tester.pumpAndSettle();
    expect(c.state.view.records.single.xpEarned, 7);
    expect(c.state.view.records.single.goal, isNull);
    await tester.pump(const Duration(seconds: 10));
  });

  testWidgets('first run: empty app, then branch -> activity with field -> record -> history', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(await app());
    await tester.pumpAndSettle();

    // Starts empty: no seeded branches.
    expect(find.text('Start your journey'), findsOneWidget);
    expect(find.text('Physical Development'), findsNothing);

    // 1. create branch
    await tester.tap(find.text('Create first branch'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Physical Development');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Physical Development'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);

    // 2. create activity with a configured field
    await tester.tap(find.text('Add first activity'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Push-ups');
    await tester.tap(find.text('Add field'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Field name'), 'Reps');
    await tester.scrollUntilVisible(find.text('Create activity'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create activity'));
    await tester.pumpAndSettle();
    expect(find.text('Push-ups'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Reps'), findsOneWidget); // field rendered from its definition

    // 3. required field is enforced
    await tester.tap(find.textContaining('Record'));
    await tester.pumpAndSettle();
    expect(find.text('Enter Reps.'), findsOneWidget);

    // 4. record a result
    await tester.enterText(find.widgetWithText(TextField, 'Reps'), '12');
    await tester.tap(find.textContaining('Record'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 record '), findsOneWidget);

    // 5. history persisted
    await tester.tap(find.byTooltip('History'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reps: 12'), findsOneWidget);
  });

  testWidgets('home button opens Home with config entry', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(await app());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Configuration'), findsOneWidget);
    await tester.tap(find.text('Configuration'));
    await tester.pumpAndSettle();
    expect(find.text('GitHub storage'), findsOneWidget);
    expect(find.text('AI Coach'), findsNothing);
  });

  testWidgets('sync chip: local-only opens the GitHub settings', (tester) async {
    tester.view.physicalSize = const Size(1080, 2200);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(await app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Local only'));
    await tester.pumpAndSettle();
    expect(find.text('GitHub storage'), findsOneWidget);
  });

  testWidgets('settings: Push to GitHub (N) shows progress, then badge 0 and last push time', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final (widget, remote) = await connectedApp();
    remote.gate = Completer<void>();
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Configuration'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Push to GitHub (2)'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Never pushed'), findsOneWidget);
    await tester.tap(find.text('Push to GitHub (2)'));
    await tester.pump();
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.textContaining('Sending'), findsOneWidget);
    remote.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Push finished'), findsOneWidget);
    expect(find.text('2 saved (of 2 sent).'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Push to GitHub (0)'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Push to GitHub (0)')).onPressed, isNull);
    expect(find.textContaining('Last push'), findsOneWidget);
    expect(find.text('Push log'), findsOneWidget);
  });

  testWidgets('sync chip: connected shows pending count and opens the push dialog', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final (widget, _) = await connectedApp();
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    expect(find.text('2 pending'), findsOneWidget);
    await tester.tap(find.text('2 pending'));
    await tester.pumpAndSettle();
    expect(find.text('Push finished'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.text('Synced'), findsOneWidget);
  });

  testWidgets('push dialog: back is blocked mid-push; progress shows "of 2"', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final (widget, remote) = await connectedApp();
    remote.gate = Completer<void>();
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 pending'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Sending 0 of 2…'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.textContaining('Sending'), findsOneWidget);
    remote.gate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Push finished'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Push finished'), findsNothing);
  });

  testWidgets('push dialog: unexpected error still shows a message and OK closes it', (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final (widget, remote) = await connectedApp();
    remote.explode = true;
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
    await tester.tap(find.text('2 pending'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Push stopped'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Push stopped'), findsNothing);
  });
}
