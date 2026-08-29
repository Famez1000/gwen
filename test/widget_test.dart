import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gwen/main.dart';
import 'package:gwen/core/state/app_state.dart';
import 'package:gwen/onboarding/merged_onboarding_flow.dart';

void main() {
  setUp(() {
    // Setup Mock SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('StillnessApp smoke test - starts on Home screen', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'heal_disclaimer_accepted': true,
    });
    final appState = AppState();
    await appState.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(StillnessApp(appState: appState));
    await tester.pump();

    // Verify the current home content displays.
    expect(find.text('Panic'), findsOneWidget);
    expect(find.text('Not OK'), findsOneWidget);
    expect(find.text('Surviving'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('Reminders'), findsOneWidget);

    // Verify bottom nav destinations are displayed
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Cope'), findsOneWidget);
    expect(find.text('Journal'), findsOneWidget);
    expect(find.text('Understand'), findsOneWidget);
    expect(find.text('Heal'), findsOneWidget);
  });

  testWidgets('a new user starts in the merged onboarding flow', (
    WidgetTester tester,
  ) async {
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(StillnessApp(appState: appState));
    await tester.pump();

    expect(find.byType(MergedOnboardingFlow), findsOneWidget);
    expect(find.text('Hi, I am Gwyn'), findsOneWidget);
  });

  testWidgets(
    'an upgraded user who has not accepted the terms starts at onboarding',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed': true,
        'heal_disclaimer_accepted': false,
      });
      final appState = AppState();
      await appState.init();

      await tester.pumpWidget(StillnessApp(appState: appState));
      await tester.pump();

      expect(find.byType(MergedOnboardingFlow), findsOneWidget);
      expect(find.text('Hi, I am Gwyn'), findsOneWidget);
      expect(find.text('Terms and Conditions'), findsNothing);
    },
  );
}
