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
    expect(
      find.descendant(
        of: find.byType(GlassCard),
        matching: find.byType(ImageIcon),
      ),
      findsOneWidget,
    );
    expect(find.text('Active plan'), findsNothing);
    expect(find.text('Make active'), findsNothing);
  });

  testWidgets('hides the Daily activities heading in Cope plan details', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.init();
    await appState.saveCopePlan(name: 'My Cope plan');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: MyPlansScreen()),
      ),
    );

    await tester.tap(find.text('My Cope plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Daily activities'), findsNothing);
    expect(
      find.text(
        'Coping with anxiety is all about reminding yourself that you are safe',
      ),
      findsOneWidget,
    );
    expect(find.text('Create persona'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  testWidgets('shows the saved Understand plan in its detail screen', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final initialState = AppState();
    await initialState.init();
    await initialState.saveUnderstandPlan(
      name: 'My Understand plan',
      feeling: 'Tight chest before meetings',
    );

    final restoredState = AppState();
    await restoredState.init();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: restoredState,
        child: const MaterialApp(home: MyPlansScreen()),
      ),
    );

    await tester.tap(find.text('My Understand plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(
      find.text(
        'Use these activities to gradually understand the reasons for your anxiety',
      ),
      findsOneWidget,
    );
    expect(find.text('Body Signals'), findsOneWidget);
    expect(find.textContaining('tight chest before meetings'), findsOneWidget);
    expect(find.text('Focus'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.ensureVisible(find.text('Journal'));
    await tester.tap(find.text('Journal'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Daily Journal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the saved Heal plan as a four-row icon table', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.init();
    await appState.saveHealPlan(name: 'My Heal plan');

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: appState,
        child: const MaterialApp(home: MyPlansScreen()),
      ),
    );

    await tester.tap(find.text('My Heal plan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(
      find.text('Reflect on the insights from the Understand phase'),
      findsOneWidget,
    );
    expect(
      find.text('Use these activities to slowly vanquish your anxiety'),
      findsOneWidget,
    );
    expect(find.text('Let go of what has been worrying you'), findsOneWidget);
    expect(find.text('Forgive what needs to be forgiven'), findsOneWidget);
    expect(
      find.textContaining('further vanquish your anxiety'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.book_rounded), findsOneWidget);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.byIcon(Icons.volunteer_activism_rounded), findsOneWidget);
    expect(find.byIcon(Icons.self_improvement_rounded), findsOneWidget);
    expect(find.text('Active plan'), findsNothing);
    expect(
      find.text('Is there some issue you need to let go of?'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
