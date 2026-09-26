import 'package:flutter/material.dart';

import '../../../../core/widgets/app_feedback.dart';
import '../../models/report_models.dart';

Future<ReportFormat?> showExportReportSheet(
  BuildContext context,
) => showModalBottomSheet<ReportFormat>(
  context: context,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Export report', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('PDF'),
            subtitle: const Text('Formatted report for printing or sharing'),
            onTap: () => Navigator.pop(context, ReportFormat.pdf),
          ),
          ListTile(
            leading: const Icon(Icons.table_chart_outlined),
            title: const Text('CSV'),
            subtitle: const Text('Spreadsheet-friendly attendance data'),
            onTap: () => Navigator.pop(context, ReportFormat.csv),
          ),
        ],
      ),
    ),
  ),
);

Future<ReportExportAction?> showExportDestinationSheet(BuildContext context) =>
    showModalBottomSheet<ReportExportAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.save_alt_outlined),
              title: const Text('Save to device'),
              onTap: () => Navigator.pop(context, ReportExportAction.save),
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share report'),
              onTap: () => Navigator.pop(context, ReportExportAction.share),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

Future<void> exportReportFlow({
  required BuildContext context,
  required Future<ReportExportResult> Function(
    ReportFormat format,
    ReportExportAction action,
  )
  export,
}) async {
  final format = await showExportReportSheet(context);
  if (format == null || !context.mounted) return;
  final action = await showExportDestinationSheet(context);
  if (action == null || !context.mounted) return;

  AppFeedback.loading(context, 'Generating report...');
  try {
    final result = await export(format, action);
    if (!context.mounted) return;
    AppFeedback.hideLoading(context);
    if (result.wasCancelled) return;
    if (result.wasSaved) {
      AppFeedback.success(context, 'Report saved: ${result.fileName}');
    } else {
      AppFeedback.success(context, 'Report shared: ${result.fileName}');
    }
  } catch (_) {
    if (!context.mounted) return;
    AppFeedback.hideLoading(context);
    AppFeedback.error(context, "We couldn't generate this report. Try again.");
  }
}
