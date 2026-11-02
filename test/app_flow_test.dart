import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:personal_life_rpg/main.dart';
import 'package:personal_life_rpg/src/data/local_store.dart';
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
}
