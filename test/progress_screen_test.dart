import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwen/core/state/app_state.dart';
import 'package:gwen/features/progress/presentation/progress_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows horizontal progress rows for Cope, Understand, and Heal', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      MaterialApp(home: ProgressScreen(appState: appState)),
    );

    for (final section in ['cope', 'understand', 'heal']) {
      final finder = find.byKey(ValueKey('$section-progress-scroll'));
      expect(finder, findsOneWidget);
      final listView = tester.widget<ListView>(finder);
      expect(listView.scrollDirection, Axis.horizontal);
      expect(listView.childrenDelegate.estimatedChildCount, 1);
    }

    expect(find.text('Cope'), findsOneWidget);
    expect(find.text('Understand'), findsOneWidget);
    expect(find.text('Heal'), findsOneWidget);
    expect(find.text('No plan yet, click to create one'), findsNWidgets(3));
    expect(find.textContaining('Active plan'), findsNothing);
    expect(find.text('Average anxiety score'), findsNothing);
    expect(find.text('Last month trend'), findsNothing);
    expect(find.text('Analysis'), findsNothing);
    expect(find.text('Create a new plan with Gwyn'), findsNothing);
    expect(tester.takeException(), isNull);

    final understandCreateCard = find.descendant(
      of: find.byKey(const ValueKey('understand-progress-scroll')),
      matching: find.text('No plan yet, click to create one'),
    );
    await tester.ensureVisible(understandCreateCard);
    await tester.tap(understandCreateCard);
    await tester.pumpAndSettle();

    expect(find.text('Understand Planning'), findsOneWidget);
  });

  testWidgets('shows progress cards only for aspects that have a plan', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.init();
    await appState.saveCopePlan(name: 'cope plan1');
    await appState.saveUnderstandPlan(name: 'understand plan1');
    await appState.saveHealPlan(name: 'heal plan1');

    await tester.pumpWidget(
      MaterialApp(home: ProgressScreen(appState: appState)),
    );

    expect(find.text('No plan yet, click to create one'), findsNothing);
    expect(find.text('My Cope plan'), findsOneWidget);
    expect(find.text('My Understand plan'), findsOneWidget);
    expect(find.text('My Heal plan'), findsOneWidget);
    for (final section in ['cope', 'understand', 'heal']) {
      final listView = tester.widget<ListView>(
        find.byKey(ValueKey('$section-progress-scroll')),
      );
      expect(listView.childrenDelegate.estimatedChildCount, 3);
    }

    await tester.tap(find.text('My Cope plan'));
    await tester.pumpAndSettle();

    expect(find.text('cope plan1'), findsOneWidget);
    expect(find.text('Daily activities'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('My Understand plan'));
    await tester.tap(find.text('My Understand plan'));
    await tester.pumpAndSettle();

    expect(find.text('understand plan1'), findsWidgets);
    expect(find.text('Focus'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('My Heal plan'));
    await tester.tap(find.text('My Heal plan'));
    await tester.pumpAndSettle();

    expect(find.text('heal plan1'), findsWidgets);
    expect(find.text('Focus'), findsOneWidget);
  });
}
