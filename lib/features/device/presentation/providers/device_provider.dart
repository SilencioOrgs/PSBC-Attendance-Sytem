import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/models.dart';

final deviceListProvider = StreamProvider<List<Device>>(
  (ref) => ref.watch(deviceRepositoryProvider).watchDevices(),
);

final bleAdvertisingStateProvider = StreamProvider<BleAdvertisingState>(
  (ref) => ref.watch(bleServiceProvider).watchAdvertisingState(),
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
