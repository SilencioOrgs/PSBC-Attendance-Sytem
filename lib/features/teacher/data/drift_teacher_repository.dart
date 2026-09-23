import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../services/auth/teacher_pin_service.dart';
import '../../../services/storage/app_database.dart';

class DriftTeacherRepository implements TeacherRepository {
  DriftTeacherRepository(this._db, this._pinService);
  final AppDatabase _db;
  final TeacherPinService _pinService;

  Teacher _map(TeacherRow row) => Teacher(
    id: row.id,
    updatedAt: row.updatedAt,
    syncStatus: row.syncStatus,
    name: row.name,
  );

  @override
  Future<Teacher> getTeacher() async => _map(await _db.teacherDao.getTeacher());

  @override
  Stream<Teacher> watchTeacher() => _db.teacherDao.watchTeacher().map(_map);

  @override
  Future<Teacher> setupTeacher({
    required String name,
    required String pin,
  }) async {
    final now = DateTime.now();
    final existing = await _db.teacherDao.getTeacherOrNull();
    final id = existing?.id ?? newDatabaseId();
    await _pinService.savePin(pin);
    final companion = TeachersCompanion.insert(
      id: id,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
      name: name.trim(),
    );
    await _db.teacherDao.save(companion);
    return Teacher(
      id: id,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
      name: name.trim(),
    );
  }
}
