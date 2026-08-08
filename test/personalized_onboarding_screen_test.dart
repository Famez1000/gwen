import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwen/core/state/app_state.dart';
import 'package:gwen/features/onboarding/presentation/personalized_onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('onboarding track selection is persisted', () async {
    final appState = AppState();
    await appState.init();
    await appState.setOnboardingTrack(OnboardingTrack.personalized);

    final restoredState = AppState();
    await restoredState.init();

    expect(restoredState.onboardingTrack, OnboardingTrack.personalized);
  });

  testWidgets('personalized track shows progress through its questions', (
    tester,
  ) async {
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      MaterialApp(
        home: PersonalizedOnboardingScreen(
          appState: appState,
          isPreview: true,
          onAcceptTerms: () async {},
          onComplete: () async {},
        ),
      ),
    );

    expect(find.text('Welcome'), findsOneWidget);
    await tester.tap(find.text('Personalize my plan'));
    await tester.pumpAndSettle();

    expect(find.text('1/8'), findsOneWidget);
    expect(
      find.text('What would you most like Gwyn to help with?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cope'));
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('2/8'), findsOneWidget);
    expect(find.text('How often does anxiety affect you?'), findsOneWidget);
  });
}
