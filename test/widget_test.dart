import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gwen/main.dart';
import 'package:gwen/core/state/app_state.dart';

void main() {
  setUp(() {
    // Setup Mock SharedPreferences before each test
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('StillnessApp smoke test - starts on Home screen', (
    WidgetTester tester,
  ) async {
    final appState = AppState();
    await appState.init();

    // Build our app and trigger a frame.
    await tester.pumpWidget(StillnessApp(appState: appState));
    await tester.pump();

    // Verify that the title / welcome text displays
    expect(find.text('Welcome to Stillness'), findsOneWidget);
    expect(find.text('You are here. You are safe.'), findsOneWidget);

    // Verify anxiety slider title is rendered
    expect(find.text('How anxious are you right now?'), findsOneWidget);

    // Verify bottom nav destinations are displayed
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Breathe'), findsOneWidget);
    expect(find.text('Sanctuary'), findsOneWidget);
    expect(find.text('Spaces'), findsOneWidget);
  });
}
