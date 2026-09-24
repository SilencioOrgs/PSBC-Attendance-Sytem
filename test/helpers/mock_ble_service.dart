import 'dart:async';

import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/services/ble/ble_service.dart';

/// A controllable BLE boundary for provider and workflow tests only.
class MockBleService implements BleService {
  StreamController<BleScanUpdate>? _scanController;
  final StreamController<BleAvailability> _adapterChanges =
      StreamController<BleAvailability>.broadcast();
  final StreamController<BleAdvertisingState> _advertisingChanges =
      StreamController<BleAdvertisingState>.broadcast();
  BleAvailability _availability = BleAvailability.ready;
  BleAdvertisingState _advertisingState = BleAdvertisingState.stopped;
  int stopScanCount = 0;
  int startAdvertisingCount = 0;
  int stopAdvertisingCount = 0;
  String? advertisedServiceUuid;
  List<Student> lastRoster = const [];
  List<Device> lastRegisteredDevices = const [];
  Duration? lastTimeout;

  void emit(BleScanUpdate update) => _scanController?.add(update);

  void setAvailability(BleAvailability value) {
    _availability = value;
    _adapterChanges.add(value);
    _advertisingState = switch (value) {
      BleAvailability.ready => BleAdvertisingState.stopped,
      BleAvailability.poweredOff => BleAdvertisingState.bluetoothOff,
      BleAvailability.permissionDenied =>
        BleAdvertisingState.permissionRequired,
      BleAvailability.unsupported => BleAdvertisingState.unsupported,
      BleAvailability.unknown => BleAdvertisingState.unknown,
    };
    _advertisingChanges.add(_advertisingState);
  }

  @override
  BleAvailability get adapterAvailability => _availability;

  @override
  Stream<BleAvailability> watchAdapterState() =>
      Stream<BleAvailability>.multi((controller) {
        controller.add(_availability);
        final subscription = _adapterChanges.stream.listen(controller.add);
        controller.onCancel = subscription.cancel;
      });

  @override
  Stream<BleAdvertisingState> watchAdvertisingState() =>
      Stream<BleAdvertisingState>.multi((controller) {
        controller.add(_advertisingState);
        final subscription = _advertisingChanges.stream.listen(controller.add);
        controller.onCancel = subscription.cancel;
      });

  @override
  Stream<BleScanUpdate> scan(
    List<Student> roster, {
    List<Device> registeredDevices = const [],
    Duration timeout = const Duration(seconds: 30),
  }) {
    lastRoster = List.unmodifiable(roster);
    lastRegisteredDevices = List.unmodifiable(registeredDevices);
    lastTimeout = timeout;
    _scanController = StreamController<BleScanUpdate>.broadcast();
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
    _scanController = null;
  }

  @override
  Future<void> startAdvertising(String serviceUuid) async {
    startAdvertisingCount++;
    advertisedServiceUuid = serviceUuid;
    _availability = BleAvailability.ready;
    _advertisingState = BleAdvertisingState.active;
    _advertisingChanges.add(_advertisingState);
  }

  @override
  Future<void> stopAdvertising() async {
    stopAdvertisingCount++;
    _advertisingState = BleAdvertisingState.stopped;
    _advertisingChanges.add(_advertisingState);
  }

  Future<void> dispose() async {
    await _scanController?.close();
    await _adapterChanges.close();
    await _advertisingChanges.close();
  }
}
