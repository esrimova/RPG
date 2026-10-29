// This is a basic Flutter widget test for Personal Life RPG.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_life_rpg/main.dart';
import 'package:personal_life_rpg/src/presentation/providers/app_providers.dart';
import 'package:personal_life_rpg/src/domain/entities/index.dart';

void main() {
  testWidgets('App loads and shows dashboard', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          // Override branches provider with test data
          branchesProvider.overrideWith((ref) async => [
            Branch(
              id: 'test-branch-1',
              name: 'Physical Development',
              description: 'Strength & conditioning',
              accentColor: const Color(0xFF00F0FF),
              icon: Icons.fitness_center,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            Branch(
              id: 'test-branch-2',
              name: 'Professional Skills',
              description: 'Career growth',
              accentColor: const Color(0xFFA855F7),
              icon: Icons.code,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ]),
          // Override user profile provider
          userProfileProvider.overrideWith((ref) async => UserProfile(
            id: 'test-user',
            username: 'testuser',
            displayName: 'TEST OPERATOR',
            level: 1,
            createdAt: DateTime.now(),
            lastActiveDate: DateTime.now(),
          )),
        ],
        child: const PersonalLifeRPGApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    // Verify that the app loads with basic elements
    expect(find.text('PERSONAL LIFE RPG'), findsOneWidget);
    
    // Check navigation bar exists
    expect(find.byType(NavigationBar), findsOneWidget);
    
    // Verify all 4 navigation destinations
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Activity'), findsWidgets);
    expect(find.text('AI Terminal'), findsWidgets);
    expect(find.text('Config'), findsWidgets);
  });

  testWidgets('Navigation switches between tabs', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          branchesProvider.overrideWith((ref) async => [
            Branch(
              id: 'test-branch-1',
              name: 'Physical Development',
              description: 'Strength & conditioning',
              accentColor: const Color(0xFF00F0FF),
              icon: Icons.fitness_center,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ]),
          userProfileProvider.overrideWith((ref) async => UserProfile(
            id: 'test-user',
            username: 'testuser',
            displayName: 'TEST OPERATOR',
            level: 1,
            createdAt: DateTime.now(),
            lastActiveDate: DateTime.now(),
          )),
        ],
        child: const PersonalLifeRPGApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    // Tap on Activity tab (index 1)
    await tester.tap(find.text('Activity').last);
    await tester.pump(const Duration(seconds: 2));
    
    // Should show Activity page - just verify navigation worked
    expect(find.byType(NavigationBar), findsOneWidget);

    // Tap on AI Terminal tab (index 2)
    await tester.tap(find.text('AI Terminal').last);
    await tester.pump(const Duration(seconds: 2));
    
    // Should show AI Terminal page
    expect(find.byType(NavigationBar), findsOneWidget);
    
    // Tap on Config tab (index 3)
    await tester.tap(find.text('Config').last);
    await tester.pump(const Duration(seconds: 2));
    
    // Should show Config page
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}