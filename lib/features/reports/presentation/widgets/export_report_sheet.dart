import 'package:flutter/material.dart';

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

  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(const SnackBar(content: Text('Generating report...')));
  try {
    final result = await export(format, action);
    messenger.hideCurrentSnackBar();
    if (!context.mounted || result.wasCancelled) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.wasSaved
              ? 'Report saved: ${result.fileName}'
              : 'Report is ready to share.',
        ),
      ),
    );
  } catch (_) {
    messenger.hideCurrentSnackBar();
    if (!context.mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text("We couldn't generate this report. Try again."),
      ),
    );
  }
}
