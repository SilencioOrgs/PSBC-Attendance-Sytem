import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/services/reports/automatic_report_scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AutomaticReportSchedule', () {
    test(
      'daily schedule uses today when the configured time is still ahead',
      () {
        final next = AutomaticReportSchedule.nextOccurrence(
          mode: AutomaticReportMode.daily,
          now: DateTime(2026, 9, 25, 8, 10),
          hour: 17,
          minute: 30,
          weekday: Weekday.friday,
        );

        expect(next, DateTime(2026, 9, 25, 17, 30));
      },
    );

    test('daily schedule moves to tomorrow after its configured time', () {
      final next = AutomaticReportSchedule.nextOccurrence(
        mode: AutomaticReportMode.daily,
        now: DateTime(2026, 9, 25, 17, 30),
        hour: 17,
        minute: 30,
        weekday: Weekday.friday,
      );

      expect(next, DateTime(2026, 9, 26, 17, 30));
    });

    test('weekly schedule selects the next configured weekday and time', () {
      final next = AutomaticReportSchedule.nextOccurrence(
        mode: AutomaticReportMode.weekly,
        now: DateTime(2026, 9, 23, 8),
        hour: 17,
        minute: 0,
        weekday: Weekday.friday,
      );

      expect(next, DateTime(2026, 9, 25, 17));
    });

    test('weekly schedule advances seven days when due time has passed', () {
      final next = AutomaticReportSchedule.nextOccurrence(
        mode: AutomaticReportMode.weekly,
        now: DateTime(2026, 9, 25, 18),
        hour: 17,
        minute: 0,
        weekday: Weekday.friday,
      );

      expect(next, DateTime(2026, 10, 2, 17));
    });

    test('weekly window ends at the scheduled wall time and starts seven days earlier', () {
      final window = AutomaticReportSchedule.windowFor(
        mode: AutomaticReportMode.weekly,
        occurrenceAt: DateTime(2026, 9, 25, 17),
      );

      expect(window.start, DateTime(2026, 9, 18, 17));
      expect(window.end, DateTime(2026, 9, 25, 17));
    });

    test('daily window starts at local midnight', () {
      final window = AutomaticReportSchedule.windowFor(
        mode: AutomaticReportMode.daily,
        occurrenceAt: DateTime(2026, 9, 25, 17, 30),
      );

      expect(window.start, DateTime(2026, 9, 25));
      expect(window.end, DateTime(2026, 9, 25, 17, 30));
    });
  });
}
