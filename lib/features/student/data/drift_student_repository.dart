import 'package:drift/drift.dart';

import '../../../core/utils/section_code.dart';
import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../services/storage/app_database.dart';

class DriftStudentRepository implements StudentRepository {
  DriftStudentRepository(this._db);
  final AppDatabase _db;

  @override
  Future<List<Student>> getStudents() => _db.studentDao.getAll();
  @override
  Stream<List<Student>> watchStudents() => _db.studentDao.watchAll();
  @override
  Future<Student?> getStudent(String studentId) =>
      _db.studentDao.getOne(studentId);
  @override
  Stream<Student?> watchStudent(String studentId) =>
      _db.studentDao.watchOne(studentId);
  @override
  Future<Student?> getCurrentStudent() => _db.studentDao.getCurrent();
  @override
  Stream<Student?> watchCurrentStudent() => _db.studentDao.watchCurrent();

  @override
  Future<Student> registerStudent({
    required String name,
    required String studentNumber,
    required String sectionCode,
  }) async {
    final parsed = parseSectionCode(sectionCode);
    if (parsed == null) {
      throw const InvalidSectionCodeException();
    }
    final normalizedCode = normalizeSectionCode(sectionCode);
    final section = await _db.classDao.getByCode(normalizedCode);
    if (section == null) {
      throw const ClassSectionNotFoundException();
    }
    if (await _db.studentDao.byNumber(studentNumber.trim()) != null) {
      throw const DuplicateStudentNumberException();
    }

    final id = newDatabaseId();
    final enrollmentId = newDatabaseId();
    final now = DateTime.now();
    try {
      await _db.transaction(() async {
        await _db.studentDao.setAllNotCurrent();
        await _db.studentDao.insert(
          StudentsCompanion.insert(
            id: id,
            updatedAt: now,
            syncStatus: SyncStatus.pendingCreate,
            studentNumber: studentNumber.trim(),
            fullName: name.trim(),
            isCurrent: const Value(true),
          ),
        );
        await _db.enrollmentDao.insert(
          EnrollmentsCompanion.insert(
            id: enrollmentId,
            updatedAt: now,
            syncStatus: SyncStatus.pendingCreate,
            studentId: id,
            classSectionId: section.id,
          ),
        );
      });
    } catch (error) {
      if (error.toString().contains(
        'UNIQUE constraint failed: students.student_number',
      )) {
        throw const DuplicateStudentNumberException();
      }
      rethrow;
    }
    return Student(
      id: id,
      updatedAt: now,
      syncStatus: SyncStatus.pendingCreate,
      name: name.trim(),
      studentNumber: studentNumber.trim(),
      classId: section.id,
      gradeLevel: 'Grade ${parsed.gradeLevel}',
      deviceRegistered: false,
    );
  }
}
