import '../../domain/models.dart';
import '../../core/utils/ble_identity.dart';

/// Matches advertised BLE service identifiers to teacher-registered students.
class BleDeviceMapper {
  const BleDeviceMapper._();

  static Map<String, Device> targets(Iterable<Device> devices) {
    final targets = <String, Device>{};
    for (final device in devices) {
      final identity = normalizeBleIdentity(device.bleUuid);
      if (device.ownerStudentId != null && identity != null) {
        targets[identity] = device;
      }
    }
    return targets;
  }

  static Device? matchAdvertisement({
    required Iterable<String> serviceUuids,
    required Map<String, Device> targets,
    required Set<String> rosterStudentIds,
    required int rssi,
    required DateTime detectedAt,
  }) {
    for (final serviceUuid in serviceUuids) {
      final identity = normalizeBleIdentity(serviceUuid);
      if (identity == null) continue;
      final device = targets[identity];
      final studentId = device?.ownerStudentId;
      if (device == null ||
          studentId == null ||
          !rosterStudentIds.contains(studentId)) {
        continue;
      }
      return Device(
        id: device.id,
        updatedAt: detectedAt,
        syncStatus: device.syncStatus,
        name: device.name,
        bleUuid: device.bleUuid,
        ownerStudentId: studentId,
        deviceModel: device.deviceModel,
        registeredAt: device.registeredAt,
        rssi: rssi,
      );
    }
    return null;
  }
}
