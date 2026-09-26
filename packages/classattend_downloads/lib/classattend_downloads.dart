import 'package:flutter/services.dart';

/// Saves generated attendance PDFs into the public Downloads collection.
class ClassAttendDownloads {
  ClassAttendDownloads._();

  static const _channel = MethodChannel('classattend/downloads');

  static Future<String> savePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final result = await _channel.invokeMethod<String>('savePdf', {
      'bytes': bytes,
      'fileName': fileName,
    });
    if (result == null || result.isEmpty) {
      throw PlatformException(
        code: 'save-failed',
        message: 'The report was not saved to Downloads.',
      );
    }
    return result;
  }
}
