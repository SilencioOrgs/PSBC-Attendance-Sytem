import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../models/report_models.dart';

/// Loads typed report inputs from repository contracts, never from widgets.
class ReportDataService {
  const ReportDataService(
    this._teachers,
    this._classes,
    this._students,
    this._attendance,
  );

  final TeacherRepository _teachers;
  final ClassRepository _classes;
  final StudentRepository _students;
  final AttendanceRepository _attendance;

  Future<AttendanceSessionReport> attendanceSession(String sessionId) async {
    final session = await _requiredSession(sessionId);
    final section = await _requiredClass(session.classOfferingId);
    final teacher = await _teachers.getTeacher();
    final records = await _attendance.getRecords(sessionId);
    final rows = <AttendanceReportRow>[];
    for (final record in records) {
      final student = await _students.getStudent(record.studentId);
      if (student != null) {
        rows.add(
          AttendanceReportRow(
            student: student,
            record: record,
            session: session,
          ),
        );
      }
    }
    rows.sort(
      (a, b) => a.student.studentNumber.compareTo(b.student.studentNumber),
    );
    return AttendanceSessionReport(
      teacher: teacher,
      section: section,
      session: session,
      rows: rows,
    );
  }

  Future<ClassAttendanceReport> classAttendance(String classId) async {
    final section = await _requiredClass(classId);
    final teacher = await _teachers.getTeacher();
    final studentsById = {
      for (final student in await _classes.getStudents(classId))
        student.id: student,
    };
    final sessions =
        (await _attendance.getSessions())
            .where(
              (session) =>
                  session.classOfferingId == classId &&
                  session.status == AttendanceSessionStatus.completed,
            )
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final recordsBySession = <String, List<AttendanceRecord>>{
      for (final session in sessions)
        session.id: await _attendance.getRecords(session.id),
    };
    for (final records in recordsBySession.values) {
      for (final record in records) {
        if (studentsById.containsKey(record.studentId)) continue;
        final student = await _students.getStudent(record.studentId);
        if (student != null) studentsById[student.id] = student;
      }
    }
    final students = studentsById.values.toList()
      ..sort((a, b) => a.studentNumber.compareTo(b.studentNumber));
    return ClassAttendanceReport(
      teacher: teacher,
      section: section,
      sessions: sessions,
      students: [
        for (final student in students)
          ClassAttendanceStudentRow(
            student: student,
            records: [
              for (final session in sessions)
                _recordFor(recordsBySession[session.id] ?? [], student.id),
            ],
          ),
      ],
    );
  }

  Future<StudentAttendanceReport> studentAttendance({
    required String classId,
    required String studentId,
  }) async {
    final section = await _requiredClass(classId);
    final roster = await _classes.getStudents(classId);
    final student = roster.where((item) => item.id == studentId).firstOrNull;
    if (student == null) throw const ClassSectionNotFoundException();
    final teacher = await _teachers.getTeacher();
    final sessions =
        (await _attendance.getSessions())
            .where(
              (session) =>
                  session.classOfferingId == classId &&
                  session.status == AttendanceSessionStatus.completed,
            )
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final rows = <AttendanceReportRow>[];
    for (final session in sessions) {
      final records = await _attendance.getRecords(session.id);
      final record = _recordFor(records, studentId);
      if (record != null) {
        rows.add(
          AttendanceReportRow(
            student: student,
            record: record,
            session: session,
          ),
        );
      }
    }
    return StudentAttendanceReport(
      teacher: teacher,
      section: section,
      student: student,
      rows: rows,
    );
  }

  Future<ClassRosterReport> classRoster(String classId) async {
    final section = await _requiredClass(classId);
    return ClassRosterReport(
      teacher: await _teachers.getTeacher(),
      section: section,
      students: await _classes.getStudents(classId),
    );
  }

  Future<AttendanceSession> _requiredSession(String sessionId) async =>
      await _attendance.getSession(sessionId) ??
      (throw const ClassSectionNotFoundException());

  Future<ClassSection> _requiredClass(String classId) async =>
      await _classes.getClass(classId) ??
      (throw const ClassSectionNotFoundException());

  AttendanceRecord? _recordFor(
    List<AttendanceRecord> records,
    String studentId,
  ) => records.where((record) => record.studentId == studentId).firstOrNull;
}
