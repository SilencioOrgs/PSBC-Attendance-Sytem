import '../../domain/models.dart';

/// Matches advertised BLE service identifiers to teacher-registered students.
class BleDeviceMapper {
  const BleDeviceMapper._();

  static Map<String, Device> targets(Iterable<Device> devices) => {
    for (final device in devices)
      if (device.ownerStudentId != null && _isUuid(device.address))
        device.address.toLowerCase(): device,
  };

  static Device? matchAdvertisement({
    required Iterable<String> serviceUuids,
    required Map<String, Device> targets,
    required Set<String> rosterStudentIds,
    required int rssi,
    required DateTime detectedAt,
  }) {
    for (final serviceUuid in serviceUuids) {
      final device = targets[serviceUuid.toLowerCase()];
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
        address: device.address,
        ownerStudentId: studentId,
        isConnected: true,
        lastSeenAt: detectedAt,
        deviceModel: device.deviceModel,
        registeredAt: device.registeredAt,
        rssi: rssi,
      );
    }
    return null;
  }

  static bool _isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);
}
