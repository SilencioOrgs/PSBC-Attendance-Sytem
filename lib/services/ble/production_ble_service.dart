import 'dart:async';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../../domain/models.dart';
import 'ble_service.dart';

/// Android BLE central/peripheral service. Student devices advertise a private
/// per-install service UUID; teachers match advertisements against local rows.
class ProductionBleService implements BleService {
  ProductionBleService({CentralManager? central, PeripheralManager? peripheral})
    : _central = central ?? CentralManager(),
      _peripheral = peripheral ?? PeripheralManager();

  final CentralManager _central;
  final PeripheralManager _peripheral;
  StreamController<BleScanUpdate>? _scanController;
  StreamSubscription<DiscoveredEventArgs>? _discoverySubscription;
  Timer? _tick;
  Timer? _timeout;
  DateTime? _scanStartedAt;
  final Map<String, Device> _detected = {};
  int _scanSeconds = 30;
  bool _scanning = false;

  @override
  Future<void> requestAccess() async {
    for (final manager in [_central, _peripheral]) {
      if (manager.state == BluetoothLowEnergyState.unauthorized) {
        final granted = await manager.authorize();
        if (!granted) {
          throw StateError(
            'Bluetooth permission is required for attendance scanning.',
          );
        }
      }
      if (manager.state == BluetoothLowEnergyState.unsupported) {
        throw StateError('This device does not support Bluetooth Low Energy.');
      }
      if (manager.state == BluetoothLowEnergyState.poweredOff) {
        throw StateError('Bluetooth is off. Turn on Bluetooth to continue.');
      }
    }
  }

  @override
  Stream<BleScanUpdate> scan(
    List<Student> roster, {
    List<Device> registeredDevices = const [],
    Duration timeout = const Duration(seconds: 30),
  }) {
    if (_scanning) return _scanController!.stream;
    final targets = <String, Device>{
      for (final device in registeredDevices)
        if (device.ownerStudentId != null && device.address.isNotEmpty)
          device.address.toLowerCase(): device,
    };
    final students = {for (final student in roster) student.id: student};
    final controller = StreamController<BleScanUpdate>();
    _scanController = controller;
    _detected.clear();
    _scanSeconds = timeout.inSeconds.clamp(1, 600);
    _scanning = true;
    _scanStartedAt = DateTime.now();

    unawaited(() async {
      try {
        await requestAccess();
        final uuids = targets.keys.map(UUID.fromString).toList();
        _discoverySubscription = _central.discovered.listen((event) {
          final ids = event.advertisement.serviceUUIDs
              .map((uuid) => uuid.toString().toLowerCase())
              .toSet();
          for (final uuid in ids) {
            final device = targets[uuid];
            final studentId = device?.ownerStudentId;
            if (device == null ||
                studentId == null ||
                !students.containsKey(studentId)) {
              continue;
            }
            _detected[studentId] = Device(
              id: device.id,
              updatedAt: DateTime.now(),
              syncStatus: device.syncStatus,
              name: event.advertisement.name ?? device.name,
              address: uuid,
              ownerStudentId: studentId,
              isConnected: true,
              lastSeenAt: DateTime.now(),
              deviceModel: device.deviceModel,
              registeredAt: device.registeredAt,
            );
            _emit(controller);
          }
        });
        await _central.startDiscovery(
          serviceUUIDs: uuids.isEmpty ? null : uuids,
        );
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
      ),
    );
  }

  Future<void> _finish(StreamController<BleScanUpdate> controller) async {
    if (!_scanning) return;
    _scanning = false;
    _timeout?.cancel();
    _tick?.cancel();
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;
    try {
      await _central.stopDiscovery();
    } catch (_) {
      // The adapter can already have stopped after a permission or radio error.
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
    await requestAccess();
    await _peripheral.removeAllServices();
    await _peripheral.startAdvertising(
      Advertisement(serviceUUIDs: [UUID.fromString(serviceUuid)]),
    );
  }

  @override
  Future<void> stopAdvertising() => _peripheral.stopAdvertising();
}
