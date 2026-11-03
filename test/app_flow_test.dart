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
import 'package:personal_life_rpg/src/domain/quests.dart';
import 'package:personal_life_rpg/src/ui/editors.dart';
import 'package:personal_life_rpg/src/ui/browser_page.dart';
import 'package:personal_life_rpg/src/ui/home_page.dart';
import 'package:personal_life_rpg/src/ui/quest_editor.dart';
import 'package:personal_life_rpg/src/ui/quests_page.dart';
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

  group('quests', () {
    String day(int offset) {
      final n = DateTime.now();
      return dateKey(DateTime(n.year, n.month, n.day + offset));
    }

    Quest seedQuest({
      String id = 'q1',
      String name = 'Shed',
      int start = 0,
      int end = 6,
      int xp = 100,
      bool auto = false,
      QuestPattern? pattern,
      required List<(String, int, bool)> tasks, // name, date offset, checked
    }) =>
        Quest(
          id: id,
          name: name,
          startDate: day(start),
          endDate: day(end),
          totalXp: xp,
          auto: auto,
          pattern: pattern,
          createdAt: DateTime(2026),
          tasks: [
            for (final (i, t) in tasks.indexed)
              QuestTask(id: '${id}_t$i', name: t.$1, date: day(t.$2), doneAt: t.$3 ? DateTime(2026) : null),
          ],
        );

    Future<void> pickDate(WidgetTester tester, Finder button, String key) async {
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Switch to input'));
      await tester.pumpAndSettle();
      final p = key.split('-').map(int.parse).toList();
      await tester.enterText(find.descendant(of: find.byType(Dialog), matching: find.byType(TextField)), '${p[1]}/${p[2]}/${p[0]}');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
    }

    Future<void> tapText(WidgetTester tester, String text) async {
      await tester.ensureVisible(find.text(text).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(text).last);
      await tester.pumpAndSettle();
    }

    Widget questsHome() => const Scaffold(body: QuestsPage());

    testWidgets('main screen always has a Quests page, even with no branches', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(await app());
      await tester.pumpAndSettle();
      expect(find.text('Start your journey'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Quests'), findsOneWidget);
      expect(find.text('New quest'), findsOneWidget);
    });

    testWidgets('with branches the Quests page sits before the add-branch page', (tester) async {
      bigView(tester);
      final (_, wrap) = await seeded();
      await tester.pumpWidget(wrap(const BrowserPage()));
      await tester.pumpAndSettle();
      expect(find.text('Body'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('New quest'), findsOneWidget);
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Add another branch'), findsOneWidget);
    });

    testWidgets('create: name, dates, points, 4 tasks every other day get dated in order', (tester) async {
      bigView(tester);
      final (c, wrap) = await seeded();
      await tester.pumpWidget(wrap(const QuestEditorPage()));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Build a shed');
      await tester.enterText(find.widgetWithText(TextField, 'Total points'), '120');
      await pickDate(tester, find.byKey(const Key('endDate')), day(6));
      await tapText(tester, 'Every other day');
      for (var i = 0; i < 4; i++) {
        await tapText(tester, 'Add task');
      }
      final names = ['Cut wood', 'Frame', 'Roof', 'Paint'];
      for (var i = 0; i < 4; i++) {
        await tester.enterText(find.widgetWithText(TextField, 'Task name').at(i), names[i]);
      }
      await tester.pumpAndSettle();
      await tapText(tester, 'Create quest');
      final q = c.state.view.quests.single;
      expect(q.name, 'Build a shed');
      expect(q.totalXp, 120);
      expect(q.startDate, day(0));
      expect(q.endDate, day(6));
      expect(q.auto, isTrue);
      expect(q.pattern!.n, 2);
      expect(q.tasks.map((t) => t.name), names);
      expect(q.tasks.map((t) => t.date), [day(0), day(2), day(4), day(6)]);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('create: weekdays-only preset stores Mon-Fri', (tester) async {
      bigView(tester);
      final (c, wrap) = await seeded();
      await tester.pumpWidget(wrap(const QuestEditorPage()));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Work week');
      await tapText(tester, 'Weekdays only');
      await tapText(tester, 'Add task');
      await tester.enterText(find.widgetWithText(TextField, 'Task name'), 'Plan');
      await tapText(tester, 'Create quest');
      final q = c.state.view.quests.single;
      expect(q.pattern!.type, 'weekdays');
      expect(q.pattern!.days, [1, 2, 3, 4, 5]);
      final d = DateTime.parse(q.tasks.single.date);
      expect(d.weekday, lessThanOrEqualTo(5));
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('create: manual mode lets each task date be set', (tester) async {
      bigView(tester);
      final (c, wrap) = await seeded();
      await tester.pumpWidget(wrap(const QuestEditorPage()));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Name'), 'Hand-dated');
      await tapText(tester, 'Manual');
      await tapText(tester, 'Add task');
      await tapText(tester, 'Add task');
      await tester.enterText(find.widgetWithText(TextField, 'Task name').at(0), 'One');
      await tester.enterText(find.widgetWithText(TextField, 'Task name').at(1), 'Two');
      await pickDate(tester, find.byKey(const Key('taskDate-1')), day(3));
      await tapText(tester, 'Create quest');
      final q = c.state.view.quests.single;
      expect(q.auto, isFalse);
      expect(q.tasks.map((t) => t.date), [day(0), day(3)]);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('checking a task updates progress and XP; Home includes quest XP', (tester) async {
      bigView(tester);
      final (c, wrap) = await seeded();
      await c.saveQuest(
          seedQuest(tasks: [('Task A', 0, false), ('Task B', 1, false), ('Task C', 2, false), ('Task D', 3, false)]),
          isNew: true);
      await tester.pumpWidget(wrap(questsHome()));
      await tester.pumpAndSettle();
      expect(find.textContaining('0/4 tasks'), findsOneWidget);
      await tester.tap(find.text('Task A'));
      await tester.pumpAndSettle();
      expect(find.textContaining('1/4 tasks'), findsOneWidget);
      expect(find.textContaining('+25 XP'), findsOneWidget);
      expect(find.text('25 / 100 XP'), findsOneWidget); // Quests branch bar
      expect(c.state.view.quests.single.tasks.first.doneAt, isNotNull);
      // unchecking takes the share back
      await tester.tap(find.text('Task A'));
      await tester.pumpAndSettle();
      expect(find.textContaining('0/4 tasks'), findsOneWidget);
      await tester.tap(find.text('Task A'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Task B'));
      await tester.pumpAndSettle();

      await tester.pumpWidget(wrap(const HomePage()));
      await tester.pumpAndSettle();
      expect(find.text('50 XP total'), findsOneWidget);
      expect(find.text('Quests'), findsOneWidget);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('checking the last task completes the quest and moves it to History with full points', (tester) async {
      bigView(tester);
      final (c, wrap) = await seeded();
      await c.saveQuest(seedQuest(tasks: [('Task A', 0, true), ('Task B', 1, false)]), isNew: true);
      await tester.pumpWidget(wrap(questsHome()));
      await tester.pumpAndSettle();
      expect(find.text('Completed'), findsNothing);
      await tester.tap(find.text('Task B'));
      await tester.pumpAndSettle();
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('100 XP'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing); // no longer in the active list
      expect(find.byTooltip('Edit quest'), findsNothing); // read-only
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('History shows Completed and Failed (0 points); finished quests can only be deleted', (tester) async {
      bigView(tester);
      final (c, wrap) = await seeded();
      await c.saveQuest(seedQuest(id: 'qa', name: 'Done one', start: -3, end: 2, tasks: [('A', -3, true)]), isNew: true);
      await c.saveQuest(
          seedQuest(id: 'qb', name: 'Missed one', start: -5, end: -1, tasks: [('B', -5, true), ('C', -2, false)]),
          isNew: true);
      await tester.pumpWidget(wrap(questsHome()));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('100 XP'), findsOneWidget);
      expect(find.text('0 XP'), findsOneWidget);
      // the failed quest's earned share does not count: 100 XP -> level 2, 0 / 200
      expect(find.text('Level 2'), findsOneWidget);
      expect(find.text('0 / 200 XP'), findsOneWidget);
      expect(find.byType(Checkbox), findsNothing);
      expect(find.byTooltip('Edit quest'), findsNothing);
      await tester.tap(find.byTooltip('Delete quest').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(c.state.view.quests.map((q) => q.name), ['Done one']);
      expect(find.text('Failed'), findsNothing);
    });

    testWidgets('adding a task to an auto quest re-spreads open tasks only', (tester) async {
      bigView(tester);
      final (c, wrap) = await seeded();
      final q = seedQuest(
        start: -2,
        end: 5,
        auto: true,
        pattern: QuestPattern.everyNDays(1),
        tasks: [('Past', -2, false), ('Checked', 0, true), ('Open 1', 1, false), ('Open 2', 2, false)],
      );
      await c.saveQuest(q, isNew: true);
      await tester.pumpWidget(wrap(QuestEditorPage(existing: c.state.view.quests.single)));
      await tester.pumpAndSettle();
      await tapText(tester, 'Add task');
      await tester.enterText(find.widgetWithText(TextField, 'Task name').last, 'New');
      await tapText(tester, 'Save changes');
      final saved = c.state.view.quests.single;
      expect(saved.tasks.map((t) => t.name), ['Past', 'Checked', 'Open 1', 'Open 2', 'New']);
      expect(saved.tasks.map((t) => t.date), [day(-2), day(0), day(0), day(2), day(4)]);
      expect(saved.tasks[1].doneAt, isNotNull);
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('editor refuses removing the last unchecked task', (tester) async {
      bigView(tester);
      final (c, wrap) = await seeded();
      await c.saveQuest(seedQuest(tasks: [('Checked', 0, true), ('Last open', 1, false)]), isNew: true);
      await tester.pumpWidget(wrap(QuestEditorPage(existing: c.state.view.quests.single)));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Remove task').at(1));
      await tester.pumpAndSettle();
      expect(find.text('Cannot complete a quest by removing tasks'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Task name'), findsNWidgets(2));
      expect(c.state.view.quests.single.tasks, hasLength(2));
    });

    testWidgets('auto quest with no matching dates left shows the error and saves nothing', (tester) async {
      bigView(tester);
      final (c, wrap) = await seeded();
      await c.saveQuest(
          seedQuest(start: -1, end: 0, auto: true, pattern: QuestPattern.everyNDays(2), tasks: [('Past', -1, false)]),
          isNew: true);
      await tester.pumpWidget(wrap(QuestEditorPage(existing: c.state.view.quests.single)));
      await tester.pumpAndSettle();
      await tapText(tester, 'Add task');
      await tester.enterText(find.widgetWithText(TextField, 'Task name').last, 'Nowhere');
      await tapText(tester, 'Save changes');
      expect(find.text('No matching dates left'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget); // still in the editor
      expect(c.state.view.quests.single.tasks, hasLength(1));
    });
  });
}
