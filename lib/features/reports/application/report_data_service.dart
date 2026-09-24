import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../models/report_models.dart';

/// Loads typed report inputs from repository contracts, never from widgets.
class ReportDataService {
  const ReportDataService(this._teachers, this._classes, this._attendance);

  final TeacherRepository _teachers;
  final ClassRepository _classes;
  final AttendanceRepository _attendance;

  Future<AttendanceSessionReport> attendanceSession(String sessionId) async {
    final session = await _requiredSession(sessionId);
    final section = await _requiredClass(session.classId);
    final teacher = await _teachers.getTeacher();
    final roster = await _classes.getStudents(section.id);
    final records = await _attendance.getRecords(sessionId);
    return AttendanceSessionReport(
      teacher: teacher,
      section: section,
      session: session,
      rows: [
        for (final student in roster)
          if (_recordFor(records, student.id) case final record?)
            AttendanceReportRow(
              student: student,
              record: record,
              session: session,
            ),
      ],
    );
  }

  Future<ClassAttendanceReport> classAttendance(String classId) async {
    final section = await _requiredClass(classId);
    final teacher = await _teachers.getTeacher();
    final students = await _classes.getStudents(classId);
    final sessions =
        (await _attendance.getSessions())
            .where(
              (session) =>
                  session.classId == classId &&
                  session.status == AttendanceSessionStatus.completed,
            )
            .toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
    final recordsBySession = <String, List<AttendanceRecord>>{
      for (final session in sessions)
        session.id: await _attendance.getRecords(session.id),
    };
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
                  session.classId == classId &&
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
