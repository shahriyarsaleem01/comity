// This is a basic Flutter widget test for Comity app.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('Comity')),
        ),
      ),
    );

    // Verify that the app loads
    expect(find.text('Comity'), findsOneWidget);
  });
}