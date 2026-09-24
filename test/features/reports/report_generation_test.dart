import 'dart:convert';

import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/features/reports/models/report_models.dart';
import 'package:attendance_system_paete/infrastructure/export/csv/csv_report_generator.dart';
import 'package:attendance_system_paete/infrastructure/export/file/report_file_name.dart';
import 'package:attendance_system_paete/infrastructure/export/pdf/pdf_report_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 9, 24, 8, 15);
  final teacher = Teacher(
    id: 'teacher-internal-id',
    updatedAt: now,
    syncStatus: SyncStatus.synced,
    name: 'Ana Reyes',
  );
  final section = ClassSection(
    id: 'class-internal-id',
    updatedAt: now,
    syncStatus: SyncStatus.synced,
    name: 'GRADE12-STEM A',
    subject: 'Filipino, Language',
    room: 'Room 1',
    schedule: 'Monday, 08:00',
    studentCount: 1,
    gradeLevel: 12,
    sectionLabel: 'STEM A',
    sectionCode: 'GRADE12-STEM A',
  );
  final session = AttendanceSession(
    id: 'session-internal-id',
    updatedAt: now,
    syncStatus: SyncStatus.synced,
    classId: section.id,
    title: section.name,
    startedAt: now,
    endedAt: now.add(const Duration(minutes: 15)),
    status: AttendanceSessionStatus.completed,
  );
  final student = Student(
    id: 'student-internal-id',
    updatedAt: now,
    syncStatus: SyncStatus.synced,
    name: 'Ana "María",\nSantos',
    studentNumber: 'T-001',
    classId: section.id,
    gradeLevel: 'Grade 12',
    deviceRegistered: true,
  );
  final record = AttendanceRecord(
    id: 'record-internal-id',
    updatedAt: now,
    syncStatus: SyncStatus.synced,
    sessionId: session.id,
    studentId: student.id,
    isPresent: true,
    detectedAt: now.add(const Duration(minutes: 2)),
    rssi: -45,
    recordStatus: AttendanceRecordStatus.manualPresent,
  );
  final row = AttendanceReportRow(
    student: student,
    record: record,
    session: session,
  );
  final attendanceReport = AttendanceSessionReport(
    teacher: teacher,
    section: section,
    session: session,
    rows: [row],
  );

  test('session CSV escapes quotes, commas, and line breaks as UTF-8', () {
    final bytes = CsvReportGenerator().attendanceSession(attendanceReport);
    final csv = utf8.decode(bytes);

    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(csv, contains('"Student Number","Student Name","Class"'));
    expect(csv, contains('"Ana ""María"",\nSantos"'));
    expect(csv, contains('"Filipino, Language"'));
    expect(csv, contains('"Manual Present"'));
    expect(csv, contains('"Manual"'));
    expect(csv, isNot(contains('session-internal-id')));
    expect(csv, isNot(contains('record-internal-id')));
  });

  test('class, student, and roster CSVs use typed report rows', () {
    final csv = CsvReportGenerator();
    final classReport = ClassAttendanceReport(
      teacher: teacher,
      section: section,
      sessions: [session],
      students: [
        ClassAttendanceStudentRow(student: student, records: [record]),
      ],
    );
    final studentReport = StudentAttendanceReport(
      teacher: teacher,
      section: section,
      student: student,
      rows: [row],
    );
    final roster = ClassRosterReport(
      teacher: teacher,
      section: section,
      students: [student],
    );

    final classCsv = utf8.decode(csv.classAttendance(classReport));
    expect(
      classCsv,
      contains('"Student Number","Student Name","Class","Subject","Section"'),
    );
    expect(
      classCsv,
      contains('"GRADE12-STEM A","Filipino, Language","STEM A","2026-09-24"'),
    );
    expect(classCsv.split('\r\n'), hasLength(3));
    expect(classReport.students.single.presentCount, 1);
    expect(classReport.students.single.attendancePercent, 100);
    expect(studentReport.present, 1);
    expect(studentReport.attendancePercent, 100);
    expect(
      utf8.decode(csv.studentAttendance(studentReport)),
      contains('"Attendance Percentage"'),
    );
    expect(
      utf8.decode(csv.classRoster(roster)),
      contains('"Device Registered","Enrollment Status"'),
    );
    expect(
      utf8.decode(csv.classRoster(roster)),
      isNot(contains('registeredUuid')),
    );
  });

  test('PDFs are valid documents and session tables paginate', () async {
    final pdf = PdfReportGenerator();
    final sessionBytes = await pdf.attendanceSession(attendanceReport);
    expect(String.fromCharCodes(sessionBytes.take(5)), '%PDF-');

    final manyRows = [
      for (var index = 0; index < 90; index++)
        AttendanceReportRow(
          student: Student(
            id: 'student-$index',
            updatedAt: now,
            syncStatus: SyncStatus.synced,
            name: index == 0
                ? 'María ${List.filled(12, 'Dela Cruz').join(' ')}'
                : 'Student $index',
            studentNumber: 'T-${index.toString().padLeft(3, '0')}',
            classId: section.id,
            gradeLevel: 'Grade 12',
            deviceRegistered: false,
          ),
          record: AttendanceRecord(
            id: 'record-$index',
            updatedAt: now,
            syncStatus: SyncStatus.synced,
            sessionId: session.id,
            studentId: 'student-$index',
            isPresent: false,
            detectedAt: null,
            recordStatus: AttendanceRecordStatus.notDetected,
          ),
          session: session,
        ),
    ];
    final multipage = await pdf.attendanceSession(
      AttendanceSessionReport(
        teacher: teacher,
        section: section,
        session: session,
        rows: manyRows,
      ),
    );
    expect(String.fromCharCodes(multipage.take(5)), '%PDF-');
    expect(multipage.length, greaterThan(5000));

    final empty = await pdf.attendanceSession(
      AttendanceSessionReport(
        teacher: teacher,
        section: section,
        session: session,
        rows: const [],
      ),
    );
    expect(String.fromCharCodes(empty.take(5)), '%PDF-');
  });

  test('class, student, and roster reports generate PDFs', () async {
    final sessions = [
      for (var index = 0; index < 17; index++)
        AttendanceSession(
          id: 'session-$index',
          updatedAt: now,
          syncStatus: SyncStatus.synced,
          classId: section.id,
          title: section.name,
          startedAt: now.add(Duration(days: index)),
          endedAt: now.add(Duration(days: index, minutes: 15)),
          status: AttendanceSessionStatus.completed,
        ),
    ];
    AttendanceRecord recordFor(AttendanceSession item, int index) =>
        AttendanceRecord(
          id: 'record-${item.id}',
          updatedAt: now,
          syncStatus: SyncStatus.synced,
          sessionId: item.id,
          studentId: student.id,
          isPresent: index.isEven,
          detectedAt: index.isEven ? item.startedAt : null,
          recordStatus: index.isEven
              ? AttendanceRecordStatus.present
              : AttendanceRecordStatus.absent,
        );
    final records = [
      for (var index = 0; index < sessions.length; index++)
        recordFor(sessions[index], index),
    ];
    final pdf = PdfReportGenerator();

    final classBytes = await pdf.classAttendance(
      ClassAttendanceReport(
        teacher: teacher,
        section: section,
        sessions: sessions,
        students: [
          ClassAttendanceStudentRow(student: student, records: records),
        ],
      ),
    );
    final studentBytes = await pdf.studentAttendance(
      StudentAttendanceReport(
        teacher: teacher,
        section: section,
        student: student,
        rows: [
          for (var index = 0; index < sessions.length; index++)
            AttendanceReportRow(
              student: student,
              record: records[index],
              session: sessions[index],
            ),
        ],
      ),
    );
    final rosterBytes = await pdf.classRoster(
      ClassRosterReport(
        teacher: teacher,
        section: section,
        students: [student],
      ),
    );

    expect(String.fromCharCodes(classBytes.take(5)), '%PDF-');
    expect(String.fromCharCodes(studentBytes.take(5)), '%PDF-');
    expect(String.fromCharCodes(rosterBytes.take(5)), '%PDF-');
  });

  test('report filenames sanitize separators and long or empty names', () {
    final name = ReportFileName.create(
      reportType: 'class attendance',
      subject: 'GRADE12-STEM A',
      date: now,
      format: ReportFormat.csv,
    );
    expect(name, 'classattend_class_attendance_grade12_stem_a_20260924.csv');
    expect(name, isNot(contains('internal-id')));

    final specialCharacters = ReportFileName.create(
      reportType: 'student/attendance',
      subject: 'Grade 12: STEM / Filipinoñ',
      date: now,
      format: ReportFormat.pdf,
    );
    expect(
      specialCharacters,
      'classattend_student_attendance_grade_12_stem_filipino_20260924.pdf',
    );
    expect(specialCharacters, isNot(contains('/')));
    expect(specialCharacters, isNot(contains(':')));

    final longName = ReportFileName.create(
      reportType: 'session',
      subject: List.filled(400, 'Very long class name ').join(),
      date: now,
      format: ReportFormat.pdf,
    );
    expect(longName.length, lessThan(255));

    expect(
      ReportFileName.create(
        reportType: '',
        subject: '',
        date: now,
        format: ReportFormat.pdf,
      ),
      'classattend_report_report_20260924.pdf',
    );
  });
}
