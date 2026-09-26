import 'dart:math' as math;

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../domain/models.dart';
import '../../../features/reports/models/report_models.dart';

/// Builds print-ready A4 reports with repeating table headers and page numbers.
class PdfReportGenerator {
  static const _ink = PdfColor.fromInt(0xFF172B4D);
  static const _blue = PdfColor.fromInt(0xFFC45A1A);
  static const _muted = PdfColor.fromInt(0xFF64748B);
  static const _line = PdfColor.fromInt(0xFFDCE3EB);
  static const _softBlue = PdfColor.fromInt(0xFFFBE8DC);

  Future<List<int>> attendanceSession(AttendanceSessionReport report) => _build(
    title: 'Attendance Report',
    subtitle: '${report.section.name} · ${report.section.subject}',
    build: (context) => [
      _metadata([
        ('Teacher', report.teacher.name),
        ('Class', report.section.name),
        ('Subject', report.section.subject),
        ('Section', report.section.sectionLabel),
        ('Date', _date(report.session.startedAt)),
        ('Start Time', _time(report.session.startedAt)),
        (
          'End Time',
          report.session.endedAt == null
              ? 'In progress'
              : _time(report.session.endedAt!),
        ),
      ]),
      pw.SizedBox(height: 14),
      _summary([
        ('Total Students', '${report.rows.length}'),
        ('Present', '${report.present}'),
        ('Absent', '${report.absent}'),
        ('Not Detected', '${report.notDetected}'),
        ('Manual', '${report.manual}'),
      ]),
      pw.SizedBox(height: 18),
      if (report.rows.isEmpty)
        _emptyMessage('No attendance records are available for this session.')
      else
        _table(
          headers: const [
            'No.',
            'Student Number',
            'Student Name',
            'Status',
            'Detected Time',
            'Method',
          ],
          rows: [
            for (var index = 0; index < report.rows.length; index++)
              [
                '${index + 1}',
                report.rows[index].student.studentNumber,
                report.rows[index].student.name,
                report.rows[index].statusLabel,
                report.rows[index].record.detectedAt == null
                    ? '—'
                    : _time(report.rows[index].record.detectedAt!),
                report.rows[index].detectionMethod.isEmpty
                    ? '—'
                    : report.rows[index].detectionMethod,
              ],
          ],
        ),
    ],
  );

  Future<List<int>> classAttendance(ClassAttendanceReport report) => _build(
    title: 'Class Attendance Report',
    subtitle: '${report.section.name} · ${report.section.subject}',
    landscape: true,
    build: (context) => [
      _metadata([
        ('Teacher', report.teacher.name),
        ('Class', report.section.name),
        ('Subject', report.section.subject),
        ('Section', report.section.sectionLabel),
        ('Completed Sessions', '${report.sessions.length}'),
      ]),
      pw.SizedBox(height: 18),
      if (report.sessions.isEmpty || report.students.isEmpty)
        _emptyMessage(
          'No completed attendance sessions are available for this class.',
        )
      else
        ..._classAttendanceTables(report),
    ],
  );

  List<pw.Widget> _classAttendanceTables(ClassAttendanceReport report) {
    const sessionsPerTable = 8;
    final tables = <pw.Widget>[];
    for (
      var startIndex = 0;
      startIndex < report.sessions.length;
      startIndex += sessionsPerTable
    ) {
      final endIndex = math.min(
        startIndex + sessionsPerTable,
        report.sessions.length,
      );
      tables.addAll([
        pw.Text(
          'Sessions ${startIndex + 1}-$endIndex',
          style: const pw.TextStyle(color: _muted, fontSize: 8),
        ),
        pw.SizedBox(height: 6),
        _table(
          headers: [
            'Student',
            for (var index = startIndex; index < endIndex; index++)
              _date(report.sessions[index].startedAt),
            'Attendance %',
          ],
          rows: [
            for (final row in report.students)
              [
                '${row.student.name}\n${row.student.studentNumber}',
                for (var index = startIndex; index < endIndex; index++)
                  _status(
                    index < row.records.length
                        ? row.records[index]?.recordStatus
                        : null,
                  ),
                '${row.attendancePercent.toStringAsFixed(1)}%',
              ],
          ],
          small: true,
        ),
        pw.SizedBox(height: 14),
      ]);
    }
    return tables;
  }

  Future<List<int>> studentAttendance(StudentAttendanceReport report) => _build(
    title: 'Student Attendance Report',
    subtitle: report.student.name,
    build: (context) => [
      _metadata([
        ('Student Name', report.student.name),
        ('Student Number', report.student.studentNumber),
        ('Class', report.section.name),
        ('Teacher', report.teacher.name),
      ]),
      pw.SizedBox(height: 14),
      _summary([
        ('Total Sessions', '${report.totalSessions}'),
        ('Present', '${report.present}'),
        ('Absent', '${report.absent}'),
        ('Not Detected', '${report.notDetected}'),
        ('Attendance', '${report.attendancePercent.toStringAsFixed(1)}%'),
      ]),
      pw.SizedBox(height: 18),
      if (report.rows.isEmpty)
        _emptyMessage(
          'No completed attendance sessions are available for this student.',
        )
      else
        _table(
          headers: const ['Date', 'Class', 'Status', 'Detection Method'],
          rows: [
            for (final row in report.rows)
              [
                row.session == null ? '—' : _date(row.session!.startedAt),
                report.section.name,
                row.statusLabel,
                row.detectionMethod.isEmpty ? '—' : row.detectionMethod,
              ],
          ],
        ),
    ],
  );

  Future<List<int>> classRoster(ClassRosterReport report) => _build(
    title: 'Class Roster',
    subtitle: '${report.section.name} · ${report.section.subject}',
    build: (context) => [
      _metadata([
        ('Teacher', report.teacher.name),
        ('Class', report.section.name),
        ('Subject', report.section.subject),
        ('Section', report.section.sectionLabel),
      ]),
      pw.SizedBox(height: 18),
      if (report.students.isEmpty)
        _emptyMessage('No students are enrolled in this class.')
      else
        _table(
          headers: const [
            'Student Number',
            'Student Name',
            'Device Registered',
            'Enrollment Status',
          ],
          rows: [
            for (final student in report.students)
              [
                student.studentNumber,
                student.name,
                student.deviceRegistered ? 'Yes' : 'No',
                'Enrolled',
              ],
          ],
        ),
    ],
  );

  Future<List<int>> _build({
    required String title,
    required String subtitle,
    required List<pw.Widget> Function(pw.Context context) build,
    bool landscape = false,
  }) async {
    final document = pw.Document();
    final font = pw.Font.ttf(await rootBundle.load('assets/fonts/Inter.ttf'));
    document.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: font),
        pageFormat: landscape ? PdfPageFormat.a4.landscape : PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 34),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          margin: const pw.EdgeInsets.only(bottom: 18),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: _line, width: 1)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'ClassAttend',
                style: pw.TextStyle(
                  color: _blue,
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                title,
                style: pw.TextStyle(
                  color: _ink,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6)),
          ),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(color: _muted, fontSize: 8),
          ),
        ),
        build: (context) => [
          pw.Text(
            title,
            style: pw.TextStyle(
              color: _ink,
              fontSize: 19,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: const pw.TextStyle(color: _muted, fontSize: 10),
          ),
          pw.SizedBox(height: 16),
          ...build(context),
        ],
      ),
    );
    return document.save();
  }

  pw.Widget _metadata(List<(String, String)> values) => pw.Container(
    padding: const pw.EdgeInsets.all(12),
    decoration: pw.BoxDecoration(
      color: _softBlue,
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Wrap(
      spacing: 18,
      runSpacing: 10,
      children: [
        for (final (label, value) in values)
          pw.SizedBox(
            width: 230,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  label.toUpperCase(),
                  style: const pw.TextStyle(color: _muted, fontSize: 7),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  value.isEmpty ? '—' : value,
                  style: pw.TextStyle(
                    color: _ink,
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  pw.Widget _summary(List<(String, String)> values) => pw.Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (label, value) in values)
        pw.Container(
          width: 95,
          padding: const pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: _line, width: 0.7),
            borderRadius: pw.BorderRadius.circular(5),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                value,
                style: pw.TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                label,
                style: const pw.TextStyle(color: _muted, fontSize: 7),
              ),
            ],
          ),
        ),
    ],
  );

  pw.Widget _table({
    required List<String> headers,
    required List<List<String>> rows,
    bool small = false,
  }) => pw.TableHelper.fromTextArray(
    headers: headers,
    data: rows,
    headerCount: 1,
    cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
    border: pw.TableBorder.all(color: _line, width: 0.5),
    headerDecoration: const pw.BoxDecoration(color: _softBlue),
    headerStyle: pw.TextStyle(
      color: _ink,
      fontSize: small ? 6 : 8,
      fontWeight: pw.FontWeight.bold,
    ),
    cellStyle: pw.TextStyle(color: _ink, fontSize: small ? 6 : 8),
    oddRowDecoration: const pw.BoxDecoration(
      color: PdfColor.fromInt(0xFFF8FAFC),
    ),
  );

  pw.Widget _emptyMessage(String message) => pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(18),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _line),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Text(
      message,
      style: const pw.TextStyle(color: _muted, fontSize: 10),
    ),
  );

  static String _status(AttendanceRecordStatus? status) => switch (status) {
    AttendanceRecordStatus.present => 'Present',
    AttendanceRecordStatus.absent => 'Absent',
    AttendanceRecordStatus.notDetected => 'Not Detected',
    AttendanceRecordStatus.manualPresent => 'Manual Present',
    AttendanceRecordStatus.manualAbsent => 'Manual Absent',
    null => '—',
  };

  static String _date(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  static String _time(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
