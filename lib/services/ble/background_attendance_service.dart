import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum BackgroundAttendanceStatus {
  inactive,
  active,
  bluetoothOff,
  permissionRequired,
  unsupported,
  error,
}

class BackgroundAttendanceState {
  const BackgroundAttendanceState(this.status, {this.error});
  final BackgroundAttendanceStatus status;
  final String? error;
}

class BackgroundAttendanceService {
  static const _channel = MethodChannel('classattend/background_attendance');

  Future<void> start(String serviceUuid) async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      throw UnsupportedError(
        'Background attendance advertising is supported on Android only.',
      );
    }
    await _channel.invokeMethod<void>('start', {'serviceUuid': serviceUuid});
  }

  Future<void> stop() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _channel.invokeMethod<void>('stop');
    }
  }

  Future<BackgroundAttendanceState> getState() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const BackgroundAttendanceState(
        BackgroundAttendanceStatus.unsupported,
      );
    }
    try {
      final result = await _channel.invokeMapMethod<String, Object?>('state');
      final status = switch (result?['status']) {
        'active' => BackgroundAttendanceStatus.active,
        'bluetoothOff' => BackgroundAttendanceStatus.bluetoothOff,
        'permissionRequired' => BackgroundAttendanceStatus.permissionRequired,
        'unsupported' => BackgroundAttendanceStatus.unsupported,
        _ when result?['error'] != null => BackgroundAttendanceStatus.error,
        _ => BackgroundAttendanceStatus.inactive,
      };
      return BackgroundAttendanceState(
        status,
        error: result?['error'] as String?,
      );
    } on PlatformException catch (error) {
      return BackgroundAttendanceState(
        BackgroundAttendanceStatus.error,
        error: error.message,
      );
    }
  }

  Future<BackgroundAttendanceState> waitUntilStarted() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      final current = await getState();
      if (current.status == BackgroundAttendanceStatus.active ||
          current.status == BackgroundAttendanceStatus.error ||
          current.status == BackgroundAttendanceStatus.bluetoothOff ||
          current.status == BackgroundAttendanceStatus.permissionRequired ||
          current.status == BackgroundAttendanceStatus.unsupported) {
        return current;
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    return const BackgroundAttendanceState(
      BackgroundAttendanceStatus.error,
      error: 'Android did not confirm BLE advertising.',
    );
  }

  Stream<BackgroundAttendanceState> watchState() async* {
    while (true) {
      yield await getState();
      await Future<void>.delayed(const Duration(seconds: 1));
    }
  }
}
