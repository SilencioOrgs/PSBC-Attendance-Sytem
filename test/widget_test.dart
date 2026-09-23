import 'package:attendance_system_paete/core/router/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('first-run role selection offers teacher and student setup', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: WelcomeScreen()));
    expect(find.text('Continue as teacher'), findsOneWidget);
    expect(find.text('Continue as student'), findsOneWidget);
  });
}
