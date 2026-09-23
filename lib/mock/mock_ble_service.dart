import '../domain/models.dart';
import '../services/ble/ble_service.dart';

/// Timer-driven BLE simulator that discovers the first 32 enrolled students.
class MockBleService implements BleService {
  bool _isScanning = false;

  @override
  Stream<BleScanUpdate> scan(List<Student> roster) async* {
    _isScanning = true;
    final presentStudents = roster.take(32).toList(growable: false);
    final discovered = <Device>[];
    const totalTicks = 8;
    for (var tick = 1; tick <= totalTicks; tick++) {
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!_isScanning) return;
      final targetCount = (presentStudents.length * tick / totalTicks).ceil();
      for (var index = discovered.length; index < targetCount; index++) {
        final student = presentStudents[index];
        discovered.add(
          Device(
            id: 'scan-${student.id}',
            updatedAt: DateTime.now(),
            syncStatus: SyncStatus.synced,
            name: 'ClassAttend ${student.name.split(' ').first}',
            address: 'E4:71:21:60:${(index + 1).toString().padLeft(2, '0')}:B2',
            ownerStudentId: student.id,
            isConnected: true,
            lastSeenAt: DateTime.now(),
          ),
        );
      }
      yield BleScanUpdate(
        progress: tick / totalTicks,
        discoveredDevices: List.unmodifiable(discovered),
        isComplete: tick == totalTicks,
      );
    }
    _isScanning = false;
  }

  @override
  Future<void> stopScan() async {
    _isScanning = false;
  }
}
