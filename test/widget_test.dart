import 'package:flutter_test/flutter_test.dart';

import 'package:project_mad/app.dart';

void main() {
  testWidgets('app renders the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProjectMadApp());
    await tester.pump();

    expect(find.text('Home'), findsWidgets);
    expect(
      find.text(
        'Simple Flutter demo with bottom navigation and weekly coursework activities.',
      ),
      findsOneWidget,
    );
    expect(find.text('Go to Second Screen'), findsOneWidget);
    expect(find.text('Open Week 3 Activity'), findsOneWidget);
  });
}
