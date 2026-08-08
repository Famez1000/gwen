import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwen/core/state/app_state.dart';
import 'package:gwen/core/widgets/glass_card.dart';
import 'package:gwen/features/profile/presentation/my_plans_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows exactly one fixed card for each plan aspect', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: MyPlansScreen()),
      ),
    );

    final planCards = find.byType(GlassCard);
    expect(planCards, findsNWidgets(3));
    expect(
      find.descendant(of: planCards, matching: find.text('Cope')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: planCards, matching: find.text('Understand')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: planCards, matching: find.text('Heal')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: planCards,
        matching: find.text('No plan yet, click to create one'),
      ),
      findsNWidgets(3),
    );
    expect(find.text('Create a new plan with Gwyn'), findsNothing);
  });

  testWidgets('uses unnumbered default titles for the three plan aspects', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.init();
    await appState.saveCopePlan();
    await appState.saveUnderstandPlan();
    await appState.saveHealPlan();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: MyPlansScreen()),
      ),
    );

    expect(find.text('Cope plan'), findsOneWidget);
    expect(find.text('Understand plan'), findsOneWidget);
    expect(find.text('Heal plan'), findsOneWidget);
  });

  testWidgets('cancelling an Understand plan title edit closes cleanly', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.init();
    await appState.saveUnderstandPlan(name: 'understand plan1');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: MyPlansScreen()),
      ),
    );

    await tester.tap(find.text('understand plan1'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byTooltip('Edit plan title'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Edit plan title'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Edit plan title'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
