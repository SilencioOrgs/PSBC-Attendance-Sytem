import 'package:attendance_system_paete/core/widgets/app_feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('feedback replaces earlier messages with one floating result', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    AppFeedback.loading(context, 'Saving report');
    await tester.pump();
    expect(find.text('Saving report'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    AppFeedback.success(context, 'Report saved');
    await tester.pumpAndSettle();
    expect(find.text('Saving report'), findsNothing);
    expect(find.text('Report saved'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
  });

  testWidgets('loading feedback can be dismissed without leaving a timer', (
    tester,
  ) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (value) {
              context = value;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    AppFeedback.loading(context, 'Working');
    await tester.pump();
    AppFeedback.hideLoading(context);
    await tester.pumpAndSettle();
    expect(find.text('Working'), findsNothing);
  });
}
