import 'package:attendance_system_paete/domain/attendance_window_policy.dart';
import 'package:attendance_system_paete/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final offering = ClassOffering(
    id: 'cpe1',
    updatedAt: DateTime(2026),
    syncStatus: SyncStatus.synced,
    name: 'Grade 12 - STEM A',
    subject: 'CPE1',
    room: '301',
    schedule: '9:30 AM - 10:30 AM',
    studentCount: 1,
    scheduleDays: {Weekday.monday},
    startMinutesOfDay: 570,
    endMinutesOfDay: 630,
  );
  const policy = AttendanceWindowPolicy();

  test('allows the configured early and late grace boundaries', () {
    expect(
      policy.evaluate(offering, DateTime(2026, 9, 28, 9, 20)).status,
      AttendanceWindowStatus.scheduled,
    );
    expect(
      policy.evaluate(offering, DateTime(2026, 9, 28, 10, 45)).status,
      AttendanceWindowStatus.scheduled,
    );
  });

  test('rejects too early and too late starts', () {
    expect(
      policy.evaluate(offering, DateTime(2026, 9, 28, 9, 19)).status,
      AttendanceWindowStatus.tooEarly,
    );
    expect(
      policy.evaluate(offering, DateTime(2026, 9, 28, 10, 46)).status,
      AttendanceWindowStatus.tooLate,
    );
  });

  test('rejects the wrong weekday and supplies the next window', () {
    final result = policy.evaluate(offering, DateTime(2026, 9, 29, 9, 45));
    expect(result.status, AttendanceWindowStatus.wrongDay);
    expect(result.nextAvailableAt, DateTime(2026, 10, 5, 9, 20));
  });

  test('reports no schedule for legacy or empty offerings', () {
    final unscheduled = ClassOffering(
      id: offering.id,
      updatedAt: offering.updatedAt,
      syncStatus: offering.syncStatus,
      name: offering.name,
      subject: offering.subject,
      room: offering.room,
      schedule: offering.schedule,
      studentCount: 1,
    );
    expect(
      policy.evaluate(unscheduled, DateTime(2026, 9, 28, 9, 45)).status,
      AttendanceWindowStatus.noSchedule,
    );
  });
}
