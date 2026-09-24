import 'dart:async';

import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/services/ble/ble_service.dart';

/// A controllable BLE boundary for provider and workflow tests only.
class MockBleService implements BleService {
  StreamController<BleScanUpdate>? _scanController;
  int stopScanCount = 0;
  int startAdvertisingCount = 0;
  String? advertisedServiceUuid;

  void emit(BleScanUpdate update) => _scanController?.add(update);

  @override
  BleAvailability get adapterAvailability => BleAvailability.ready;

  @override
  Stream<BleAvailability> watchAdapterState() =>
      Stream.value(BleAvailability.ready);

  @override
  Stream<BleScanUpdate> scan(
    List<Student> roster, {
    List<Device> registeredDevices = const [],
    Duration timeout = const Duration(seconds: 30),
  }) {
    _scanController ??= StreamController<BleScanUpdate>.broadcast();
    return _scanController!.stream;
  }

  @override
  Future<void> requestScanAccess() async {}

  @override
  Future<void> requestAdvertisingAccess() async {}

  @override
  Future<void> stopScan() async {
    stopScanCount++;
    if (_scanController case final controller? when !controller.isClosed) {
      await controller.close();
    }
  }

  @override
  Future<void> startAdvertising(String serviceUuid) async {
    startAdvertisingCount++;
    advertisedServiceUuid = serviceUuid;
  }

  @override
  Future<void> stopAdvertising() async {}

  Future<void> dispose() async => _scanController?.close();
}
