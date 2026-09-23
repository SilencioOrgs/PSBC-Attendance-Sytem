import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../services/storage/app_database.dart';

class DriftClassRepository implements ClassRepository {
  DriftClassRepository(this._db);
  final AppDatabase _db;
  @override
  Future<List<ClassSection>> getClasses() => _db.classDao.getClasses();
  @override
  Stream<List<ClassSection>> watchClasses() => _db.classDao.watchClasses();
  @override
  Future<ClassSection?> getClass(String classId) =>
      _db.classDao.getClass(classId);
  @override
  Stream<ClassSection?> watchClass(String classId) =>
      _db.classDao.watchClass(classId);
  @override
  Future<ClassSection?> getClassByCode(String sectionCode) =>
      _db.classDao.getByCode(sectionCode);
  @override
  Future<List<Student>> getStudents(String classId) =>
      _db.classDao.getStudents(classId);
  @override
  Stream<List<Student>> watchStudents(String classId) =>
      _db.classDao.watchStudents(classId);
}
