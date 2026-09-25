import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/models.dart';
import '../../../../services/ble/background_attendance_service.dart';

final deviceListProvider = StreamProvider<List<Device>>(
  (ref) => ref.watch(deviceRepositoryProvider).watchDevices(),
);

final bleAdvertisingStateProvider = StreamProvider<BleAdvertisingState>(
  (ref) => ref.watch(bleServiceProvider).watchAdvertisingState(),
);

final backgroundAttendanceStateProvider =
    StreamProvider<BackgroundAttendanceState>(
      (ref) => ref.watch(backgroundAttendanceServiceProvider).watchState(),
    );

final myDeviceProvider = StreamProvider<Device?>((ref) {
  final students = ref.watch(studentRepositoryProvider);
  final devices = ref.watch(deviceRepositoryProvider);
  return students.watchCurrentStudent().asyncExpand(
    (student) => student == null
        ? Stream.value(null)
        : devices.watchStudentDevice(student.id),
  );
});

final deviceRegistrationControllerProvider =
    NotifierProvider<DeviceRegistrationController, bool>(
      DeviceRegistrationController.new,
    );

class DeviceRegistrationController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> register(
    String studentId,
    String deviceName, {
    String? bleUuid,
  }) async {
    state = true;
    try {
      await ref
          .read(deviceRepositoryProvider)
          .registerDevice(studentId, deviceName, bleUuid: bleUuid);
      ref.invalidate(myDeviceProvider);
      ref.invalidate(deviceListProvider);
    } finally {
      state = false;
    }
  }

  Future<void> startBeacon(String serviceUuid) async {
    if (state) return;
    state = true;
    try {
      await ref.read(bleServiceProvider).startAdvertising(serviceUuid);
    } finally {
      state = false;
    }
  }

  Future<void> enableBackgroundAttendance(String serviceUuid) async {
    if (state) return;
    state = true;
    try {
      if (defaultTargetPlatform != TargetPlatform.android) {
        throw UnsupportedError(
          'Background attendance advertising is Android only.',
        );
      }
      final notifications = await Permission.notification.request();
      if (!notifications.isGranted) {
        throw StateError(
          'Notification permission is required for background attendance.',
        );
      }
      final bluetoothPermissions = await <Permission>[
        Permission.bluetoothAdvertise,
        Permission.bluetoothConnect,
      ].request();
      if (bluetoothPermissions.values.any((status) => !status.isGranted)) {
        throw StateError('Bluetooth advertising permission is required.');
      }
      await ref.read(bleServiceProvider).requestAdvertisingAccess();
      await ref.read(bleServiceProvider).stopAdvertising();
      final service = ref.read(backgroundAttendanceServiceProvider);
      await service.start(serviceUuid);
      final result = await service.waitUntilStarted();
      if (result.status != BackgroundAttendanceStatus.active) {
        throw StateError(
          result.error ?? 'Background attendance could not start.',
        );
      }
    } finally {
      state = false;
    }
  }

  Future<void> stopBackgroundAttendance() async {
    if (state) return;
    state = true;
    try {
      await ref.read(backgroundAttendanceServiceProvider).stop();
    } finally {
      state = false;
    }
  }

  Future<void> stopBeacon() async {
    if (state) return;
    state = true;
    try {
      await ref.read(bleServiceProvider).stopAdvertising();
    } finally {
      state = false;
    }
  }
}
