import 'package:flutter_test/flutter_test.dart';

import 'package:project_mad/app.dart';

void main() {
  testWidgets('app renders two simple screens', (WidgetTester tester) async {
    await tester.pumpWidget(const ProjectMadApp());
    await tester.pump();

    expect(find.text('First Screen'), findsOneWidget);
    expect(
      find.text('Random text lives here. Nothing fancy, just the first screen.'),
      findsOneWidget,
    );
    expect(find.text('Go to Second Screen'), findsOneWidget);

    await tester.tap(find.text('Go to Second Screen'));
    await tester.pumpAndSettle();

    expect(find.text('Second Screen'), findsOneWidget);
    expect(
      find.text('More random text on the second screen. Tap below to go back.'),
      findsOneWidget,
    );
    expect(find.text('Go Back'), findsOneWidget);
  });
}
