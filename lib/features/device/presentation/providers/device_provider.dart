import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/models.dart';

final deviceListProvider = StreamProvider<List<Device>>(
  (ref) => ref.watch(deviceRepositoryProvider).watchDevices(),
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
    final ble = ref.read(bleServiceProvider);
    await ble.requestAdvertisingAccess();
    await ref
        .read(deviceRepositoryProvider)
        .registerDevice(studentId, deviceName, bleUuid: bleUuid);
    final device = await ref
        .read(deviceRepositoryProvider)
        .getStudentDevice(studentId);
    if (device != null) await ble.startAdvertising(device.address);
    state = true;
    ref.invalidate(myDeviceProvider);
    ref.invalidate(deviceListProvider);
  }

  Future<void> startBeacon(String serviceUuid) async {
    if (state) return;
    await ref.read(bleServiceProvider).startAdvertising(serviceUuid);
    state = true;
  }

  Future<void> stopBeacon() async {
    await ref.read(bleServiceProvider).stopAdvertising();
    state = false;
  }
}
