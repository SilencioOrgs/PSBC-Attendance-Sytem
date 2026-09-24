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
  Future<Device?> getStudentDevice(String studentId) =>
      _db.deviceDao.getStudent(studentId);
  @override
  Stream<Device?> watchStudentDevice(String studentId) =>
      _db.deviceDao.watchStudent(studentId);
  @override
  Future<Device> registerDevice(
    String studentId,
    String deviceName, {
    String? bleUuid,
  }) async {
    if (await _db.deviceDao.getStudent(studentId) != null) {
      throw const StudentAlreadyHasDeviceException();
    }
    final uuid = bleUuid == null || bleUuid.trim().isEmpty
        ? newDatabaseId()
        : normalizeBleIdentity(bleUuid);
    if (uuid == null) throw const InvalidBleUuidException();
    return _saveDevice(studentId, deviceName, uuid);
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

  Future<Device> _saveDevice(
    String studentId,
    String deviceName,
    String uuid,
  ) async {
    final id = newDatabaseId();
    final now = DateTime.now();
    try {
      await _db.deviceDao.insert(
        _deviceRow(id, studentId, deviceName, uuid, now),
      );
    } catch (error) {
      _rethrowDeviceConflict(error);
    }
    return _device(id, studentId, deviceName, uuid, now);
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
    final message = error.toString();
    if (message.contains('devices.ble_uuid')) {
      throw const DuplicateBleUuidException();
    }
    if (message.contains('devices.student_id')) {
      throw const StudentAlreadyHasDeviceException();
    }
    Error.throwWithStackTrace(error, StackTrace.current);
  }
}
