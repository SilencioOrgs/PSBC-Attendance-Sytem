import 'models.dart';

enum AttendanceWindowStatus {
  scheduled,
  tooEarly,
  tooLate,
  wrongDay,
  noSchedule,
}

class AttendanceWindowResult {
  const AttendanceWindowResult(this.status, {this.nextAvailableAt});
  final AttendanceWindowStatus status;
  final DateTime? nextAvailableAt;
  bool get isScheduled => status == AttendanceWindowStatus.scheduled;
}

/// Applies the default teacher attendance grace period to a recurring offering schedule.
class AttendanceWindowPolicy {
  const AttendanceWindowPolicy({
    this.earlyGrace = const Duration(minutes: 10),
    this.lateGrace = const Duration(minutes: 15),
  });

  final Duration earlyGrace;
  final Duration lateGrace;

  AttendanceWindowResult evaluate(ClassOffering offering, DateTime now) {
    final days = offering.scheduleDays;
    final start = offering.startMinutesOfDay;
    final end = offering.endMinutesOfDay;
    if (days.isEmpty ||
        start == null ||
        end == null ||
        start < 0 ||
        end > 1439 ||
        end <= start) {
      return const AttendanceWindowResult(AttendanceWindowStatus.noSchedule);
    }
    final day = Weekday.values[now.weekday - 1];
    if (!days.contains(day)) {
      return AttendanceWindowResult(
        AttendanceWindowStatus.wrongDay,
        nextAvailableAt: _nextStart(now, days, start),
      );
    }
    final minute = now.hour * 60 + now.minute;
    final lower = start - earlyGrace.inMinutes;
    final upper = end + lateGrace.inMinutes;
    if (minute < lower) {
      return AttendanceWindowResult(
        AttendanceWindowStatus.tooEarly,
        nextAvailableAt: DateTime(
          now.year,
          now.month,
          now.day,
          start ~/ 60,
          start % 60,
        ).subtract(earlyGrace),
      );
    }
    if (minute > upper) {
      return AttendanceWindowResult(
        AttendanceWindowStatus.tooLate,
        nextAvailableAt: _nextStart(now, days, start),
      );
    }
    return const AttendanceWindowResult(AttendanceWindowStatus.scheduled);
  }

  DateTime _nextStart(DateTime now, Set<Weekday> days, int start) {
    for (var offset = 1; offset <= 7; offset++) {
      final candidate = now.add(Duration(days: offset));
      if (days.contains(Weekday.values[candidate.weekday - 1])) {
        return DateTime(
          candidate.year,
          candidate.month,
          candidate.day,
          start ~/ 60,
          start % 60,
        ).subtract(earlyGrace);
      }
    }
    return now;
  }
}
