import '../../domain/models.dart';

/// Interface for BLE discovery used by attendance capture.
abstract interface class BleService {
  Stream<BleScanUpdate> scan(List<Student> roster);
  Future<void> stopScan();
}
