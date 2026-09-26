import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:classattend_downloads/classattend_downloads.dart';

import '../../domain/models.dart';
import '../../features/attendance/data/drift_attendance_repository.dart';
import '../../features/classes/data/drift_class_repository.dart';
import '../../features/reports/application/report_data_service.dart';
import '../../features/reports/application/report_export_service.dart';
import '../../features/reports/models/report_models.dart';
import '../../features/student/data/drift_student_repository.dart';
import '../../features/teacher/data/drift_teacher_repository.dart';
import '../../infrastructure/export/csv/csv_report_generator.dart';
import '../../infrastructure/export/file/file_export_service.dart';
import '../../infrastructure/export/pdf/pdf_report_generator.dart';
import '../../services/auth/teacher_pin_service.dart';
import '../../services/storage/app_database.dart';
import 'automatic_report_scheduler.dart';

typedef AutoReportPdfGenerator = Future<GeneratedReportFile> Function(
  String sessionId,
  String fileName,
);
typedef AutoReportPdfSaver = Future<void> Function(
  Uint8List bytes,
  String fileName,
);
typedef AutoReportNotifier = Future<void> Function({
  required bool succeeded,
  required int generatedCount,
});

/// Creates and saves completed-session PDFs for one daily or weekly window.
class AutoAttendanceReportRunner {
  AutoAttendanceReportRunner(
    this._database, {
    this._generatePdf,
    this._savePdf,
    this._notify,
  });

  final AppDatabase _database;
  final AutoReportPdfGenerator? _generatePdf;
  final AutoReportPdfSaver? _savePdf;
  final AutoReportNotifier? _notify;

  Future<bool> run({
    required AutomaticReportMode mode,
    required DateTime occurrenceAt,
  }) async {
    final window = AutomaticReportSchedule.windowFor(
      mode: mode,
      occurrenceAt: occurrenceAt,
    );
    final runId = 'auto_${mode.name}_${occurrenceAt.millisecondsSinceEpoch}';
    final now = DateTime.now();
    final previousRun = await _database.autoReportDao.getRun(
      mode,
      occurrenceAt,
    );
    if (previousRun?.status == AutoReportRunStatus.succeeded) return true;
    var run = AutoReportRun(
      id: runId,
      mode: mode,
      occurrenceAt: occurrenceAt,
      windowStart: window.start,
      windowEnd: window.end,
      attemptedAt: now,
      status: AutoReportRunStatus.running,
      generatedCount: previousRun?.generatedCount ?? 0,
      failedCount: 0,
    );
    await _database.autoReportDao.saveRun(run);

    try {
      final localTeacher = await _database.teacherDao.getTeacherOrNull();
      if (localTeacher == null) throw StateError('Teacher profile is missing.');
      final ownedOfferingIds = (await _database.classDao.getClasses())
          .where((offering) => offering.teacherId == localTeacher.id)
          .map((offering) => offering.id)
          .toSet();
      final sessions =
          (await _database.attendanceDao.getSessions())
              .where(
                (session) =>
                    ownedOfferingIds.contains(session.classOfferingId) &&
                    session.status == AttendanceSessionStatus.completed &&
                    !session.startedAt.isBefore(window.start) &&
                    !session.startedAt.isAfter(window.end),
              )
              .toList()
            ..sort((a, b) => a.startedAt.compareTo(b.startedAt));

      final exporter = _generatePdf == null ? _reportExporter() : null;
      var generatedCount = (await _database.autoReportDao.getExecutions(runId))
          .where((item) => item.status == AutoReportExecutionStatus.succeeded)
          .length;
      var failedCount = 0;
      for (final session in sessions) {
        final previous = await _database.autoReportDao.getExecution(
          runId,
          session.id,
        );
        if (previous?.status == AutoReportExecutionStatus.succeeded) continue;

        final fileName = _fileName(mode, occurrenceAt, session);
        final executionId = '${runId}_${session.id}';
        await _database.autoReportDao.saveExecution(
          AutoReportExecution(
            id: executionId,
            runId: runId,
            sessionId: session.id,
            attemptedAt: DateTime.now(),
            status: AutoReportExecutionStatus.pending,
            fileName: fileName,
          ),
        );
        try {
          final file = _generatePdf == null
              ? await exporter!.generateAttendanceSessionPdf(
                  session.id,
                  fileName: fileName,
                )
              : await _generatePdf(session.id, fileName);
          final bytes = Uint8List.fromList(file.bytes);
          if (_savePdf == null) {
            await ClassAttendDownloads.savePdf(
              bytes: bytes,
              fileName: file.fileName,
            );
          } else {
            await _savePdf(bytes, file.fileName);
          }
          generatedCount++;
          await _database.autoReportDao.saveExecution(
            AutoReportExecution(
              id: executionId,
              runId: runId,
              sessionId: session.id,
              attemptedAt: DateTime.now(),
              status: AutoReportExecutionStatus.succeeded,
              fileName: file.fileName,
            ),
          );
        } catch (_) {
          failedCount++;
          await _database.autoReportDao.saveExecution(
            AutoReportExecution(
              id: executionId,
              runId: runId,
              sessionId: session.id,
              attemptedAt: DateTime.now(),
              status: AutoReportExecutionStatus.failed,
              fileName: fileName,
            ),
          );
        }
      }

      final succeeded = failedCount == 0;
      run = AutoReportRun(
        id: runId,
        mode: mode,
        occurrenceAt: occurrenceAt,
        windowStart: window.start,
        windowEnd: window.end,
        attemptedAt: DateTime.now(),
        status: succeeded
            ? AutoReportRunStatus.succeeded
            : AutoReportRunStatus.failed,
        generatedCount: generatedCount,
        failedCount: failedCount,
      );
      await _database.autoReportDao.saveRun(run);
      await (_notify ?? showAutomaticReportNotification)(
        succeeded: succeeded,
        generatedCount: generatedCount,
      );
      return succeeded;
    } catch (_) {
      await _database.autoReportDao.saveRun(
        AutoReportRun(
          id: runId,
          mode: mode,
          occurrenceAt: occurrenceAt,
          windowStart: window.start,
          windowEnd: window.end,
          attemptedAt: DateTime.now(),
          status: AutoReportRunStatus.failed,
          generatedCount: run.generatedCount,
          failedCount: run.failedCount + 1,
        ),
      );
      await (_notify ?? showAutomaticReportNotification)(
        succeeded: false,
        generatedCount: run.generatedCount,
      );
      return false;
    }
  }

  ReportExportService _reportExporter() {
    final teachers = DriftTeacherRepository(
      _database,
      SecureTeacherPinService(const FlutterSecureStorage()),
    );
    final classes = DriftClassRepository(_database);
    final students = DriftStudentRepository(_database);
    final attendance = DriftAttendanceRepository(
      _database,
      canAccessOffering: (_) async => true,
    );
    return ReportExportService(
      ReportDataService(teachers, classes, students, attendance),
      PdfReportGenerator(),
      CsvReportGenerator(),
      FileExportService(),
    );
  }

  String _fileName(
    AutomaticReportMode mode,
    DateTime occurrenceAt,
    AttendanceSession session,
  ) {
    final offering = session.classOfferingId.replaceAll(
      RegExp(r'[^A-Za-z0-9_-]'),
      '_',
    );
    final sessionId = session.id.replaceAll(RegExp(r'[^A-Za-z0-9_-]'), '_');
    final timestamp = [
      occurrenceAt.year,
      occurrenceAt.month.toString().padLeft(2, '0'),
      occurrenceAt.day.toString().padLeft(2, '0'),
      occurrenceAt.hour.toString().padLeft(2, '0'),
      occurrenceAt.minute.toString().padLeft(2, '0'),
    ].join();
    return 'classattend_${mode.name}_${timestamp}_${offering}_$sessionId.pdf';
  }
}
