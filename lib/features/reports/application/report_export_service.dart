import '../../../infrastructure/export/csv/csv_report_generator.dart';
import '../../../infrastructure/export/file/file_export_service.dart';
import '../../../infrastructure/export/file/report_file_name.dart';
import '../../../infrastructure/export/pdf/pdf_report_generator.dart';
import '../models/report_models.dart';
import 'report_data_service.dart';

/// Coordinates typed report data, byte generation, and a user-visible export action.
class ReportExportService {
  const ReportExportService(this._data, this._pdf, this._csv, this._files);

  final ReportDataService _data;
  final PdfReportGenerator _pdf;
  final CsvReportGenerator _csv;
  final FileExportService _files;

  Future<ReportExportResult> export({
    required ReportRequest request,
    required ReportFormat format,
    required ReportExportAction action,
  }) async {
    final file = await _generate(request, format);
    return switch (action) {
      ReportExportAction.save => _files.save(file),
      ReportExportAction.share => _files.share(file),
    };
  }

  /// Generates a single session PDF without opening a picker or share sheet.
  /// Background report jobs use this same typed report path as manual exports.
  Future<GeneratedReportFile> generateAttendanceSessionPdf(
    String sessionId, {
    required String fileName,
  }) async {
    final file = await _generate(
      AttendanceSessionRequest(sessionId),
      ReportFormat.pdf,
    );
    return GeneratedReportFile(
      bytes: file.bytes,
      fileName: fileName,
      mimeType: file.mimeType,
    );
  }

  Future<GeneratedReportFile> _generate(
    ReportRequest request,
    ReportFormat format,
  ) async {
    late final List<int> bytes;
    late final String type;
    late final String subject;
    late final DateTime date;
    final mimeType = format == ReportFormat.pdf
        ? 'application/pdf'
        : 'text/csv';

    switch (request) {
      case AttendanceSessionRequest(:final sessionId):
        final report = await _data.attendanceSession(sessionId);
        type = 'attendance';
        subject = report.section.sectionCode;
        date = report.session.startedAt;
        bytes = format == ReportFormat.pdf
            ? await _pdf.attendanceSession(report)
            : _csv.attendanceSession(report);
      case ClassAttendanceRequest(:final classId):
        final report = await _data.classAttendance(classId);
        type = 'class_attendance';
        subject = report.section.sectionCode;
        date = DateTime.now();
        bytes = format == ReportFormat.pdf
            ? await _pdf.classAttendance(report)
            : _csv.classAttendance(report);
      case StudentAttendanceRequest(:final classId, :final studentId):
        final report = await _data.studentAttendance(
          classId: classId,
          studentId: studentId,
        );
        type = 'student_attendance';
        subject = report.student.studentNumber;
        date = DateTime.now();
        bytes = format == ReportFormat.pdf
            ? await _pdf.studentAttendance(report)
            : _csv.studentAttendance(report);
      case ClassRosterRequest(:final classId):
        final report = await _data.classRoster(classId);
        type = 'class_roster';
        subject = report.section.sectionCode;
        date = DateTime.now();
        bytes = format == ReportFormat.pdf
            ? await _pdf.classRoster(report)
            : _csv.classRoster(report);
    }

    return GeneratedReportFile(
      bytes: bytes,
      fileName: ReportFileName.create(
        reportType: type,
        subject: subject,
        date: date,
        format: format,
      ),
      mimeType: mimeType,
    );
  }
}
