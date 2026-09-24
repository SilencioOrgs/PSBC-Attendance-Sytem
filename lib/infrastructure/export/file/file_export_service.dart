import 'dart:typed_data';

import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:share_plus/share_plus.dart';

import '../../../features/reports/models/report_models.dart';

/// Saves reports through the native document picker or opens the platform share sheet.
class FileExportService {
  Future<ReportExportResult> save(GeneratedReportFile file) async {
    final location = await FlutterFileDialog.saveFile(
      params: SaveFileDialogParams(
        data: Uint8List.fromList(file.bytes),
        fileName: file.fileName,
        mimeTypesFilter: [file.mimeType],
      ),
    );
    if (location == null) return const ReportExportResult.cancelled();
    return ReportExportResult.saved(file.fileName, location);
  }

  Future<ReportExportResult> share(GeneratedReportFile file) async {
    final result = await SharePlus.instance.share(
      ShareParams(
        title: file.fileName,
        files: [
          XFile.fromData(
            Uint8List.fromList(file.bytes),
            mimeType: file.mimeType,
          ),
        ],
        fileNameOverrides: [file.fileName],
      ),
    );
    if (result.status == ShareResultStatus.dismissed) {
      return const ReportExportResult.cancelled();
    }
    return ReportExportResult.shared(file.fileName);
  }
}
