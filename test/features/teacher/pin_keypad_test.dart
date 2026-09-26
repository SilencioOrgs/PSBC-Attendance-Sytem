import 'package:attendance_system_paete/core/theme/app_theme.dart';
import 'package:attendance_system_paete/features/teacher/presentation/widgets/pin_keypad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keypad appends digits, masks them, and deletes the last one', (
    tester,
  ) async {
    String pin = '';
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: PinKeypad(
              pin: pin,
              onDigit: (digit) => setState(() => pin += digit),
              onDelete: () =>
                  setState(() => pin = pin.substring(0, pin.length - 1)),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('pin_digit_1')));
    await tester.tap(find.byKey(const ValueKey('pin_digit_2')));
    await tester.tap(find.byKey(const ValueKey('pin_digit_3')));
    await tester.tap(find.byKey(const ValueKey('pin_digit_4')));
    await tester.pump();

    expect(pin, '1234');
    expect(find.text('1234'), findsNothing);
    expect(find.byType(EditableText), findsNothing);
    expect(find.bySemanticsLabel('PIN digit entered'), findsNWidgets(4));

    await tester.tap(find.byKey(const ValueKey('pin_delete')));
    await tester.pump();
    expect(pin, '123');
    expect(find.bySemanticsLabel('PIN digit entered'), findsNWidgets(3));
  });
}
