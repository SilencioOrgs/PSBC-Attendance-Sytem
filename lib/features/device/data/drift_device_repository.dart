import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
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
    final id = newDatabaseId();
    final uuid = bleUuid?.trim().isNotEmpty == true
        ? bleUuid!.trim()
        : newDatabaseId();
    final now = DateTime.now();
    try {
      await _db.deviceDao.insert(
        DevicesCompanion.insert(
          id: id,
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate,
          studentId: studentId,
          bleUuid: uuid,
          deviceModel: deviceName.trim(),
          registeredAt: now,
        ),
      );
    } catch (error) {
      if (error.toString().contains('devices.ble_uuid')) {
        throw const DuplicateBleUuidException();
      }
      if (error.toString().contains('devices.student_id')) {
        throw const StudentAlreadyHasDeviceException();
      }
      rethrow;
    }
    return Device(
      id: id,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
      name: deviceName.trim(),
      deviceModel: deviceName.trim(),
      address: uuid,
      ownerStudentId: studentId,
      isConnected: false,
      lastSeenAt: null,
      registeredAt: now,
    );
  }
}
