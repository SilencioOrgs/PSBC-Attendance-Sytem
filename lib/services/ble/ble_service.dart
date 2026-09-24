import '../../domain/models.dart';

/// Interface for BLE discovery used by attendance capture.
abstract interface class BleService {
  BleAvailability get adapterAvailability;
  Stream<BleAvailability> watchAdapterState();
  Stream<BleScanUpdate> scan(
    List<Student> roster, {
    List<Device> registeredDevices = const [],
    Duration timeout = const Duration(seconds: 30),
  });
  Future<void> stopScan();
  Future<void> requestScanAccess();
  Future<void> requestAdvertisingAccess();
  Future<void> startAdvertising(String serviceUuid);
  Future<void> stopAdvertising();
}
