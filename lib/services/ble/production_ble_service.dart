import 'dart:async';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';
import 'package:flutter/foundation.dart';

import '../../domain/models.dart';
import 'ble_device_mapper.dart';
import 'ble_service.dart';

/// Android BLE central and peripheral implementation.
///
/// Student devices advertise a generated 128 bit service UUID. A teacher stores
/// that same UUID after the student shares their device code. Device names and
/// platform addresses are never used for attendance matching.
class ProductionBleService implements BleService {
  ProductionBleService({CentralManager? central, PeripheralManager? peripheral})
    : _central = central ?? CentralManager(),
      _peripheral = peripheral ?? PeripheralManager();

  final CentralManager _central;
  final PeripheralManager _peripheral;
  StreamController<BleScanUpdate>? _scanController;
  StreamSubscription<DiscoveredEventArgs>? _discoverySubscription;
  StreamSubscription<BluetoothLowEnergyStateChangedEventArgs>?
  _adapterSubscription;
  Timer? _tick;
  Timer? _timeout;
  DateTime? _scanStartedAt;
  final Map<String, Device> _detected = {};
  final Set<String> _seenUnknownPeripherals = {};
  int _unknownDeviceCount = 0;
  int _scanSeconds = 30;
  bool _scanning = false;

  @override
  BleAvailability get adapterAvailability => _availability(_central.state);

  @override
  Stream<BleAvailability> watchAdapterState() =>
      Stream<BleAvailability>.multi((controller) {
        var lastState = adapterAvailability;
        controller.add(lastState);
        final subscription = _central.stateChanged.listen((event) {
          final nextState = _availability(event.state);
          if (nextState != lastState) {
            lastState = nextState;
            controller.add(nextState);
          }
        });
        controller.onCancel = subscription.cancel;
      });

  BleAvailability _availability(BluetoothLowEnergyState state) =>
      switch (state) {
        BluetoothLowEnergyState.poweredOn => BleAvailability.ready,
        BluetoothLowEnergyState.poweredOff => BleAvailability.poweredOff,
        BluetoothLowEnergyState.unauthorized =>
          BleAvailability.permissionDenied,
        BluetoothLowEnergyState.unsupported => BleAvailability.unsupported,
        BluetoothLowEnergyState.unknown => BleAvailability.unknown,
      };

  Future<void> _requestAccess(BluetoothLowEnergyManager manager) async {
    final beforeRequest = manager.state;
    if (beforeRequest == BluetoothLowEnergyState.unsupported) {
      throw StateError('This device does not support Bluetooth Low Energy.');
    }
    if (beforeRequest == BluetoothLowEnergyState.poweredOff) {
      throw StateError('Bluetooth is off. Turn on Bluetooth to continue.');
    }
    if (beforeRequest == BluetoothLowEnergyState.unauthorized &&
        defaultTargetPlatform == TargetPlatform.android) {
      final granted = await manager.authorize();
      if (!granted) {
        throw StateError('Bluetooth permission is required to continue.');
      }
    }
  }

  @override
  Future<void> requestScanAccess() => _requestAccess(_central);

  @override
  Future<void> requestAdvertisingAccess() => _requestAccess(_peripheral);

  @override
  Stream<BleScanUpdate> scan(
    List<Student> roster, {
    List<Device> registeredDevices = const [],
    Duration timeout = const Duration(seconds: 30),
  }) {
    if (_scanning) return _scanController!.stream;

    final targets = BleDeviceMapper.targets(registeredDevices);
    final rosterStudentIds = {for (final student in roster) student.id};
    final controller = StreamController<BleScanUpdate>();
    _scanController = controller;
    _detected.clear();
    _seenUnknownPeripherals.clear();
    _unknownDeviceCount = 0;
    _scanSeconds = timeout.inSeconds.clamp(1, 600);
    _scanStartedAt = DateTime.now();
    _scanning = true;

    unawaited(() async {
      try {
        await requestScanAccess();
        _adapterSubscription = _central.stateChanged.listen((event) {
          if (event.state == BluetoothLowEnergyState.poweredOff ||
              event.state == BluetoothLowEnergyState.unauthorized ||
              event.state == BluetoothLowEnergyState.unsupported) {
            if (!controller.isClosed) {
              controller.addError(
                StateError(_stateError(event.state)),
                StackTrace.current,
              );
            }
            unawaited(_finish(controller));
          }
        });
        _discoverySubscription = _central.discovered.listen((event) {
          final serviceUuids = event.advertisement.serviceUUIDs
              .map((uuid) => uuid.toString())
              .toList(growable: false);
          final detected = BleDeviceMapper.matchAdvertisement(
            serviceUuids: serviceUuids,
            targets: targets,
            rosterStudentIds: rosterStudentIds,
            rssi: event.rssi,
            detectedAt: DateTime.now(),
          );
          if (detected != null) {
            _detected[detected.ownerStudentId!] = detected;
          } else {
            final peripheralId = event.peripheral.uuid.toString();
            if (_seenUnknownPeripherals.add(peripheralId)) {
              _unknownDeviceCount++;
            }
          }
          _emit(controller);
        });

        // Scan without an OS UUID filter so unknown adverts can be counted and
        // registered service identifiers can still be compared in Dart.
        await _central.startDiscovery();
        _tick = Timer.periodic(
          const Duration(milliseconds: 500),
          (_) => _emit(controller),
        );
        _timeout = Timer(timeout, () => unawaited(_finish(controller)));
        _emit(controller);
      } catch (error, stack) {
        if (!controller.isClosed) controller.addError(error, stack);
        await _finish(controller);
      }
    }());
    return controller.stream;
  }

  String _stateError(BluetoothLowEnergyState state) => switch (state) {
    BluetoothLowEnergyState.poweredOff =>
      'Bluetooth was turned off during the scan.',
    BluetoothLowEnergyState.unauthorized =>
      'Bluetooth permission was revoked during the scan.',
    BluetoothLowEnergyState.unsupported =>
      'Bluetooth Low Energy is unavailable on this device.',
    BluetoothLowEnergyState.unknown =>
      'Bluetooth is not ready. Try scanning again.',
    BluetoothLowEnergyState.poweredOn => 'Bluetooth is ready.',
  };

  void _emit(
    StreamController<BleScanUpdate> controller, {
    bool complete = false,
  }) {
    if (controller.isClosed) return;
    final elapsed = DateTime.now()
        .difference(_scanStartedAt ?? DateTime.now())
        .inMilliseconds;
    controller.add(
      BleScanUpdate(
        progress: complete ? 1 : (elapsed / (_scanSeconds * 1000)).clamp(0, 1),
        discoveredDevices: List.unmodifiable(_detected.values),
        isComplete: complete,
        unknownDeviceCount: _unknownDeviceCount,
      ),
    );
  }

  Future<void> _finish(StreamController<BleScanUpdate> controller) async {
    if (!_scanning) return;
    _scanning = false;
    _timeout?.cancel();
    _tick?.cancel();
    await _adapterSubscription?.cancel();
    _adapterSubscription = null;
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;
    try {
      await _central.stopDiscovery();
    } catch (_) {
      // The adapter may have stopped already after a radio or permission error.
    }
    _emit(controller, complete: true);
    await controller.close();
    if (identical(_scanController, controller)) _scanController = null;
  }

  @override
  Future<void> stopScan() async {
    final controller = _scanController;
    if (controller != null) await _finish(controller);
  }

  @override
  Future<void> startAdvertising(String serviceUuid) async {
    await requestAdvertisingAccess();
    await _peripheral.removeAllServices();
    await _peripheral.startAdvertising(
      Advertisement(serviceUUIDs: [UUID.fromString(serviceUuid)]),
    );
  }

  @override
  Future<void> stopAdvertising() => _peripheral.stopAdvertising();
}
