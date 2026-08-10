import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwen/core/state/app_state.dart';
import 'package:gwen/features/sanctuary/presentation/anxiety_persona_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('creates and persists an anxiety persona', (tester) async {
    final appState = AppState();
    await appState.init();

    await tester.pumpWidget(
      MaterialApp(home: AnxietyPersonaScreen(appState: appState)),
    );

    expect(find.text('Your anxiety persona'), findsOneWidget);
    expect(find.text('Save changes'), findsNothing);
    expect(find.text('Saved automatically'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('anxiety-persona-name')),
      'Anxious Harry',
    );
    await tester.enterText(
      find.byKey(const Key('anxiety-persona-description')),
      'He always predicts the worst.',
    );
    await tester.pumpAndSettle();

    expect(
      find.text('“Oh, it’s good old Anxious Harry again.”'),
      findsOneWidget,
    );

    expect(appState.anxietyPersonaName, 'Anxious Harry');
    expect(appState.anxietyPersonaDescription, 'He always predicts the worst.');

    final restoredState = AppState();
    await restoredState.init();
    expect(restoredState.anxietyPersonaName, 'Anxious Harry');
    expect(restoredState.hasAnxietyPersona, isTrue);
  });
}
