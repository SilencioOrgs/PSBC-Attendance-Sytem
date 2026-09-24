import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/services/ble/ble_device_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const registeredUuid = '8f3f5d3e-54e2-4e15-9b2c-810859f38d33';
  const studentId = 'student-1';

  test('matches a registered advertised service UUID case insensitively', () {
    final device = Device(
      id: 'device-1',
      updatedAt: DateTime(2026),
      syncStatus: SyncStatus.synced,
      name: 'Student phone',
      address: registeredUuid,
      ownerStudentId: studentId,
      isConnected: false,
      lastSeenAt: null,
    );
    final match = BleDeviceMapper.matchAdvertisement(
      serviceUuids: [registeredUuid.toUpperCase()],
      targets: BleDeviceMapper.targets([device]),
      rosterStudentIds: {studentId},
      rssi: -47,
      detectedAt: DateTime(2026, 9, 24, 8),
    );

    expect(match?.ownerStudentId, studentId);
    expect(match?.rssi, -47);
    expect(match?.lastSeenAt, DateTime(2026, 9, 24, 8));
  });

  test(
    'ignores unknown UUIDs, unregistered identifiers, and non-roster owners',
    () {
      final known = Device(
        id: 'device-1',
        updatedAt: DateTime(2026),
        syncStatus: SyncStatus.synced,
        name: 'Student phone',
        address: registeredUuid,
        ownerStudentId: studentId,
        isConnected: false,
        lastSeenAt: null,
      );
      final targets = BleDeviceMapper.targets([known]);

      expect(
        BleDeviceMapper.matchAdvertisement(
          serviceUuids: const ['00000000-0000-4000-8000-000000000000'],
          targets: targets,
          rosterStudentIds: {studentId},
          rssi: -60,
          detectedAt: DateTime(2026),
        ),
        isNull,
      );
      expect(
        BleDeviceMapper.matchAdvertisement(
          serviceUuids: const [registeredUuid],
          targets: targets,
          rosterStudentIds: const {},
          rssi: -60,
          detectedAt: DateTime(2026),
        ),
        isNull,
      );
      expect(
        BleDeviceMapper.targets([
          Device(
            id: 'bad',
            updatedAt: DateTime(2026),
            syncStatus: SyncStatus.synced,
            name: 'bad',
            address: 'random-not-a-ble-uuid',
            ownerStudentId: studentId,
            isConnected: false,
            lastSeenAt: null,
          ),
        ]),
        isEmpty,
      );
    },
  );
}
