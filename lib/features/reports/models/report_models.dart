import '../../../domain/models.dart';

enum ReportFormat { pdf, csv }

enum ReportExportAction { save, share }

sealed class ReportRequest {
  const ReportRequest();
}

class AttendanceSessionRequest extends ReportRequest {
  const AttendanceSessionRequest(this.sessionId);
  final String sessionId;
}

class ClassAttendanceRequest extends ReportRequest {
  const ClassAttendanceRequest(this.classId);
  final String classId;
}

class StudentAttendanceRequest extends ReportRequest {
  const StudentAttendanceRequest({
    required this.classId,
    required this.studentId,
  });
  final String classId;
  final String studentId;
}

class ClassRosterRequest extends ReportRequest {
  const ClassRosterRequest(this.classId);
  final String classId;
}

class AttendanceSessionReport {
  const AttendanceSessionReport({
    required this.teacher,
    required this.section,
    required this.session,
    required this.rows,
  });

  final Teacher teacher;
  final ClassSection section;
  final AttendanceSession session;
  final List<AttendanceReportRow> rows;

  int get present =>
      rows.where((row) => row.status == AttendanceRecordStatus.present).length;
  int get absent =>
      rows.where((row) => row.status == AttendanceRecordStatus.absent).length;
  int get notDetected => rows
      .where((row) => row.status == AttendanceRecordStatus.notDetected)
      .length;
  int get manualPresent => rows
      .where((row) => row.status == AttendanceRecordStatus.manualPresent)
      .length;
  int get manualAbsent => rows
      .where((row) => row.status == AttendanceRecordStatus.manualAbsent)
      .length;
  int get manual => manualPresent + manualAbsent;
}

class AttendanceReportRow {
  const AttendanceReportRow({
    required this.student,
    required this.record,
    this.session,
  });

  final Student student;
  final AttendanceRecord record;
  final AttendanceSession? session;
  AttendanceRecordStatus get status =>
      record.recordStatus ?? AttendanceRecordStatus.notDetected;
  bool get hasManualOverride =>
      status == AttendanceRecordStatus.manualPresent ||
      status == AttendanceRecordStatus.manualAbsent;
  String get detectionMethod => switch (status) {
    AttendanceRecordStatus.present => 'BLE',
    AttendanceRecordStatus.manualPresent ||
    AttendanceRecordStatus.manualAbsent => 'Manual',
    AttendanceRecordStatus.notDetected || AttendanceRecordStatus.absent => '',
  };
  String get statusLabel => switch (status) {
    AttendanceRecordStatus.present => 'Present',
    AttendanceRecordStatus.absent => 'Absent',
    AttendanceRecordStatus.notDetected => 'Not Detected',
    AttendanceRecordStatus.manualPresent => 'Manual Present',
    AttendanceRecordStatus.manualAbsent => 'Manual Absent',
  };
}

class ClassAttendanceReport {
  const ClassAttendanceReport({
    required this.teacher,
    required this.section,
    required this.sessions,
    required this.students,
  });

  final Teacher teacher;
  final ClassSection section;
  final List<AttendanceSession> sessions;
  final List<ClassAttendanceStudentRow> students;
}

class ClassAttendanceStudentRow {
  const ClassAttendanceStudentRow({
    required this.student,
    required this.records,
  });

  final Student student;
  final List<AttendanceRecord?> records;

  int get presentCount => records.where(_countsAsPresent).length;
  double get attendancePercent =>
      records.isEmpty ? 0 : presentCount * 100 / records.length;

  bool _countsAsPresent(AttendanceRecord? record) =>
      record?.recordStatus == AttendanceRecordStatus.present ||
      record?.recordStatus == AttendanceRecordStatus.manualPresent;
}

class StudentAttendanceReport {
  const StudentAttendanceReport({
    required this.teacher,
    required this.section,
    required this.student,
    required this.rows,
  });

  final Teacher teacher;
  final ClassSection section;
  final Student student;
  final List<AttendanceReportRow> rows;

  int get totalSessions => rows.length;
  int get present => rows
      .where(
        (row) =>
            row.status == AttendanceRecordStatus.present ||
            row.status == AttendanceRecordStatus.manualPresent,
      )
      .length;
  int get absent => rows
      .where(
        (row) =>
            row.status == AttendanceRecordStatus.absent ||
            row.status == AttendanceRecordStatus.manualAbsent,
      )
      .length;
  int get notDetected => rows
      .where((row) => row.status == AttendanceRecordStatus.notDetected)
      .length;
  double get attendancePercent =>
      totalSessions == 0 ? 0 : present * 100 / totalSessions;
}

class ClassRosterReport {
  const ClassRosterReport({
    required this.teacher,
    required this.section,
    required this.students,
  });

  final Teacher teacher;
  final ClassSection section;
  final List<Student> students;
}

class GeneratedReportFile {
  const GeneratedReportFile({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final List<int> bytes;
  final String fileName;
  final String mimeType;
}

class ReportExportResult {
  const ReportExportResult.saved(this.fileName, this.location)
    : wasSaved = true,
      wasShared = false,
      wasCancelled = false;
  const ReportExportResult.shared(this.fileName)
    : location = null,
      wasSaved = false,
      wasShared = true,
      wasCancelled = false;
  const ReportExportResult.cancelled()
    : fileName = null,
      location = null,
      wasSaved = false,
      wasShared = false,
      wasCancelled = true;

  final String? fileName;
  final String? location;
  final bool wasSaved;
  final bool wasShared;
  final bool wasCancelled;
}
