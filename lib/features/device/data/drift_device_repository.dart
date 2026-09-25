import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../core/utils/ble_identity.dart';
import '../../../services/storage/app_database.dart';

class DriftDeviceRepository implements DeviceRepository {
  DriftDeviceRepository(this._db);
  final AppDatabase _db;
  @override
  Future<List<Device>> getDevices() => _db.deviceDao.getAll();
  @override
  Stream<List<Device>> watchDevices() => _db.deviceDao.watchAll();
  @override
  Future<Device?> getStudentDevice(String studentId) async {
    final device = await _db.deviceDao.getStudent(studentId);
    if (device == null) return null;
    return _db.transaction(() => _ensureDeviceIdentity(device));
  }

  @override
  Stream<Device?> watchStudentDevice(String studentId) =>
      _db.deviceDao.watchStudent(studentId).asyncMap((device) async {
        if (device == null) return null;
        return _db.transaction(() => _ensureDeviceIdentity(device));
      });
  @override
  Future<Device> registerDevice(
    String studentId,
    String deviceName, {
    String? bleUuid,
  }) async {
    try {
      return await _db.transaction(() async {
        final existing = await _db.deviceDao.getStudent(studentId);
        if (existing != null) {
          // Registration can be retried safely. Existing physical identity is
          // authoritative; a retry must never replace it with a new value.
          return _ensureDeviceIdentity(existing);
        }

        final requestedUuid = bleUuid?.trim().isNotEmpty == true
            ? normalizeBleIdentity(bleUuid!)
            : null;
        if (bleUuid?.trim().isNotEmpty == true && requestedUuid == null) {
          throw const InvalidBleUuidException();
        }

        final id = newDatabaseId();
        final now = DateTime.now();
        for (var attempt = 0; attempt < 5; attempt++) {
          final uuid = requestedUuid ?? newBleServiceUuid();
          try {
            await _db.deviceDao.insert(
              _deviceRow(id, studentId, deviceName, uuid, now),
            );
            return _device(id, studentId, deviceName, uuid, now);
          } catch (error) {
            if (requestedUuid == null && _isDuplicateBleUuid(error)) {
              continue;
            }
            rethrow;
          }
        }
        throw const DuplicateBleUuidException();
      });
    } catch (error) {
      if (error is RepositoryException) rethrow;
      _rethrowDeviceConflict(error);
    }
  }

  @override
  Future<Device> replaceDevice(
    String studentId,
    String deviceName, {
    required String bleUuid,
  }) async {
    final uuid = normalizeBleIdentity(bleUuid);
    if (uuid == null) throw const InvalidBleUuidException();
    final id = newDatabaseId();
    final now = DateTime.now();
    try {
      await _db.transaction(() async {
        await _db.deviceDao.deleteStudentDevice(studentId);
        await _db.deviceDao.insert(
          _deviceRow(id, studentId, deviceName, uuid, now),
        );
      });
    } catch (error) {
      _rethrowDeviceConflict(error);
    }
    return _device(id, studentId, deviceName, uuid, now);
  }

  @override
  Future<void> removeDevice(String studentId) =>
      _db.deviceDao.deleteStudentDevice(studentId);

  Future<Device> _ensureDeviceIdentity(Device device) async {
    // Re-read inside the transaction: a concurrent registration/repair may
    // already have persisted the canonical UUID.
    final current = await _db.deviceDao.getStudent(device.ownerStudentId!);
    if (current == null) return device;
    final normalized = normalizeBleIdentity(current.bleUuid);
    if (normalized == current.bleUuid) return current;

    if (normalized != null) {
      await _db.deviceDao.updateStudentBleUuid(
        current.ownerStudentId!,
        normalized,
      );
      return (await _db.deviceDao.getStudent(current.ownerStudentId!))!;
    }

    for (var attempt = 0; attempt < 5; attempt++) {
      final uuid = newBleServiceUuid();
      try {
        await _db.deviceDao.updateStudentBleUuid(current.ownerStudentId!, uuid);
        return (await _db.deviceDao.getStudent(current.ownerStudentId!))!;
      } catch (error) {
        if (!_isDuplicateBleUuid(error)) rethrow;
      }
    }
    throw const DuplicateBleUuidException();
  }

  DevicesCompanion _deviceRow(
    String id,
    String studentId,
    String deviceName,
    String uuid,
    DateTime now,
  ) => DevicesCompanion.insert(
    id: id,
    updatedAt: now,
    syncStatus: SyncStatus.pendingCreate,
    studentId: studentId,
    bleUuid: uuid,
    deviceModel: deviceName.trim().isEmpty
        ? 'Student device'
        : deviceName.trim(),
    registeredAt: now,
  );

  Device _device(
    String id,
    String studentId,
    String deviceName,
    String uuid,
    DateTime now,
  ) => Device(
    id: id,
    updatedAt: now,
    syncStatus: SyncStatus.pendingCreate,
    name: deviceName.trim().isEmpty ? 'Student device' : deviceName.trim(),
    deviceModel: deviceName.trim().isEmpty
        ? 'Student device'
        : deviceName.trim(),
    bleUuid: uuid,
    ownerStudentId: studentId,
    registeredAt: now,
  );

  Never _rethrowDeviceConflict(Object error) {
    if (_isDuplicateBleUuid(error)) throw const DuplicateBleUuidException();
    final message = error.toString();
    if (message.contains('devices.student_id')) {
      throw const StudentAlreadyHasDeviceException();
    }
    Error.throwWithStackTrace(error, StackTrace.current);
  }

  bool _isDuplicateBleUuid(Object error) =>
      error.toString().contains('devices.ble_uuid');
}
