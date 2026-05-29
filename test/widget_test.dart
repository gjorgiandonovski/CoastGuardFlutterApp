import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:project_mad/app.dart';

void main() {
  testWidgets('app renders an injected home widget for tests', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProjectMadApp(
        homeOverride: Scaffold(body: Center(child: Text('Test home'))),
      ),
    );
    await tester.pump();

    expect(find.text('Test home'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
