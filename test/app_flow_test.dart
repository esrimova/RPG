import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_rpg/main.dart';
import 'dart:async';
import 'package:personal_life_rpg/src/data/local_store.dart';
import 'package:personal_life_rpg/src/data/remote_store.dart';
import 'package:personal_life_rpg/src/domain/apply.dart';
import 'package:personal_life_rpg/src/domain/models.dart';
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

void main() {
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
