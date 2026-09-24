import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../infrastructure/export/csv/csv_report_generator.dart';
import '../../../../infrastructure/export/file/file_export_service.dart';
import '../../../../infrastructure/export/pdf/pdf_report_generator.dart';
import '../../application/report_data_service.dart';
import '../../application/report_export_service.dart';
import '../../models/report_models.dart';

final reportExportServiceProvider = Provider<ReportExportService>((ref) {
  final data = ReportDataService(
    ref.watch(teacherRepositoryProvider),
    ref.watch(classRepositoryProvider),
    ref.watch(attendanceRepositoryProvider),
  );
  return ReportExportService(
    data,
    PdfReportGenerator(),
    CsvReportGenerator(),
    FileExportService(),
  );
});

final reportExportControllerProvider =
    NotifierProvider<ReportExportController, bool>(ReportExportController.new);

class ReportExportController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<ReportExportResult> export({
    required ReportRequest request,
    required ReportFormat format,
    required ReportExportAction action,
  }) async {
    state = true;
    try {
      return await ref
          .read(reportExportServiceProvider)
          .export(request: request, format: format, action: action);
    } finally {
      state = false;
    }
  }
}
