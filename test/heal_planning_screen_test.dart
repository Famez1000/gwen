import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwen/features/home/presentation/planning_destination_screen.dart';

void main() {
  testWidgets('Healing plan asks the three focused questions', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HealPlanningScreen()));

    expect(find.text('Question 1 of 3'), findsOneWidget);
    expect(find.text('In what situation do you feel anxious?'), findsNothing);
    expect(
      find.text(
        'How much time do you have available per week for healing practices?',
      ),
      findsNothing,
    );
    expect(
      find.text('Additional info Gwyn could use in her plan'),
      findsNothing,
    );

    await tester.tap(find.text('No'));
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Question 2 of 3'), findsOneWidget);
    expect(
      find.text("Is there something you've been struggling to accept?"),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'A difficult change');
    await tester.pump();
    await tester.tap(find.text('Next'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Question 3 of 3'), findsOneWidget);
    expect(
      find.text(
        'Is there someone you can forgive now, or someone you feel ready to ask for forgiveness?',
      ),
      findsOneWidget,
    );
    expect(find.text('Create my plan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
