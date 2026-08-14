import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gwen/features/sanctuary/presentation/autogenic_training_screen.dart';

void main() {
  testWidgets('shows the autogenic training sequence and guidance', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AutogenicTrainingScreen()));

    expect(find.text('Autogenic training'), findsOneWidget);
    expect(find.text('A typical session'), findsOneWidget);
    expect(find.text('Heaviness'), findsOneWidget);
    expect(find.text('My arms and legs are pleasantly heavy.'), findsNothing);
    expect(
      find.text('“My arms and legs are pleasantly heavy.”'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('A supportive practice'),
      300,
      scrollable: find.byType(Scrollable),
    );

    expect(find.text('A supportive practice'), findsOneWidget);
    expect(
      find.textContaining('complement—not replace—medical care'),
      findsOneWidget,
    );
  });
}
