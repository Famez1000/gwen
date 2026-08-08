import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwen/core/state/app_state.dart';
import 'package:gwen/features/learning/presentation/understand_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _createPlanTitle = 'Create a plan with Gwyn to understand your anxiety';

Future<void> _pumpUnderstandScreen(
  WidgetTester tester,
  AppState appState,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: appState,
      child: const MaterialApp(home: UnderstandScreen()),
    ),
  );
}

void main() {
  testWidgets('shows the create-plan card without an Understand plan', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.init();

    await _pumpUnderstandScreen(tester, appState);

    expect(find.text(_createPlanTitle), findsOneWidget);
    await tester.tap(find.text(_createPlanTitle));
    await tester.pumpAndSettle();

    expect(find.text('Understand Planning'), findsOneWidget);
    expect(find.text('Plan with Gwyn'), findsNothing);
  });

  testWidgets('hides the create-plan card when an Understand plan exists', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final appState = AppState();
    await appState.init();
    await appState.saveUnderstandPlan(name: 'understand plan1');

    await _pumpUnderstandScreen(tester, appState);

    expect(find.text(_createPlanTitle), findsNothing);
  });
}
