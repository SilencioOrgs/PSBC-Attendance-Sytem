import 'dart:convert';

import '../../../domain/models.dart';
import '../../../features/reports/models/report_models.dart';

/// Serializes typed reports as RFC 4180 CSV with a UTF-8 BOM for spreadsheets.
class CsvReportGenerator {
  List<int> attendanceSession(AttendanceSessionReport report) => _encode([
    const [
      'Student Number',
      'Student Name',
      'Class',
      'Subject',
      'Section',
      'Date',
      'Session Start',
      'Session End',
      'Status',
      'Detection Method',
      'Detected At',
      'Manual Override',
    ],
    for (final row in report.rows)
      [
        row.student.studentNumber,
        row.student.name,
        report.section.name,
        report.section.subject,
        report.section.sectionLabel,
        _date(report.session.startedAt),
        _time(report.session.startedAt),
        report.session.endedAt == null ? '' : _time(report.session.endedAt!),
        row.statusLabel,
        row.detectionMethod,
        row.record.detectedAt == null ? '' : _dateTime(row.record.detectedAt!),
        row.hasManualOverride ? 'Yes' : 'No',
      ],
  ]);

  List<int> classAttendance(ClassAttendanceReport report) => _encode([
    const [
      'Student Number',
      'Student Name',
      'Session Date',
      'Status',
      'Detection Method',
    ],
    for (final student in report.students)
      for (var index = 0; index < report.sessions.length; index++)
        [
          student.student.studentNumber,
          student.student.name,
          _date(report.sessions[index].startedAt),
          _status(student.records[index]?.recordStatus),
          _method(student.records[index]?.recordStatus),
        ],
  ]);

  List<int> studentAttendance(StudentAttendanceReport report) => _encode([
    const [
      'Student Name',
      'Student Number',
      'Class',
      'Total Sessions',
      'Present',
      'Absent',
      'Not Detected',
      'Attendance Percentage',
      'Session Date',
      'Status',
      'Detection Method',
      'Detected At',
      'Manual Override',
    ],
    for (final row in report.rows)
      [
        report.student.name,
        report.student.studentNumber,
        report.section.name,
        report.totalSessions,
        report.present,
        report.absent,
        report.notDetected,
        report.attendancePercent.toStringAsFixed(1),
        row.session == null ? '' : _date(row.session!.startedAt),
        row.statusLabel,
        row.detectionMethod,
        row.record.detectedAt == null ? '' : _dateTime(row.record.detectedAt!),
        row.hasManualOverride ? 'Yes' : 'No',
      ],
  ]);

  List<int> classRoster(ClassRosterReport report) => _encode([
    const [
      'Student Number',
      'Student Name',
      'Device Registered',
      'Enrollment Status',
    ],
    for (final student in report.students)
      [
        student.studentNumber,
        student.name,
        student.deviceRegistered ? 'Yes' : 'No',
        'Enrolled',
      ],
  ]);

  List<int> _encode(List<List<Object?>> rows) => utf8.encode(
    '\uFEFF${rows.map((row) => row.map(_escape).join(',')).join('\r\n')}\r\n',
  );

  String _escape(Object? value) =>
      '"${(value?.toString() ?? '').replaceAll('"', '""')}"';

  static String _status(AttendanceRecordStatus? status) => switch (status) {
    AttendanceRecordStatus.present => 'Present',
    AttendanceRecordStatus.absent => 'Absent',
    AttendanceRecordStatus.notDetected => 'Not Detected',
    AttendanceRecordStatus.manualPresent => 'Manual Present',
    AttendanceRecordStatus.manualAbsent => 'Manual Absent',
    null => 'Not Detected',
  };

  static String _method(AttendanceRecordStatus? status) => switch (status) {
    AttendanceRecordStatus.present => 'BLE',
    AttendanceRecordStatus.manualPresent ||
    AttendanceRecordStatus.manualAbsent => 'Manual',
    AttendanceRecordStatus.absent ||
    AttendanceRecordStatus.notDetected ||
    null => '',
  };

  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  static String _dateTime(DateTime value) => '${_date(value)} ${_time(value)}';
}
