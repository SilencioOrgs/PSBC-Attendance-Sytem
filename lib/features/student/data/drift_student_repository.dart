import 'package:drift/drift.dart';

import '../../../core/utils/section_code.dart';
import '../../../core/utils/ble_identity.dart';
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
    if (await _db.studentDao.byNumber(studentNumber.trim()) != null) {
      throw const DuplicateStudentNumberException();
    }

    final section = await _db.classDao.getByCode(normalizedCode);

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
            declaredSectionCode: Value(normalizedCode),
          ),
        );
        if (section != null) {
          await _db.enrollmentDao.insert(
            EnrollmentsCompanion.insert(
              id: enrollmentId,
              updatedAt: now,
              syncStatus: SyncStatus.pendingCreate,
              studentId: id,
              classSectionId: section.id,
            ),
          );
        }
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
      classId: section?.id ?? '',
      gradeLevel: 'Grade ${parsed.gradeLevel}',
      deviceRegistered: false,
      sectionCode: normalizedCode,
    );
  }

  @override
  Future<Student> addStudentToClass({
    required String name,
    required String studentNumber,
    required String classId,
    String? bleUuid,
  }) async {
    if (name.trim().isEmpty || studentNumber.trim().isEmpty) {
      throw const ClassValidationException();
    }
    if (await _db.studentDao.byNumber(studentNumber.trim()) != null) {
      throw const DuplicateStudentNumberException();
    }
    final normalizedBleUuid = bleUuid?.trim().isNotEmpty == true
        ? normalizeBleIdentity(bleUuid!)
        : null;
    if (bleUuid?.trim().isNotEmpty == true && normalizedBleUuid == null) {
      throw const InvalidBleUuidException();
    }
    final section = await _db.classDao.getClass(classId);
    if (section == null) throw const ClassSectionNotFoundException();
    final id = newDatabaseId();
    final enrollmentId = newDatabaseId();
    final now = DateTime.now();
    try {
      await _db.transaction(() async {
        await _db.studentDao.insert(
          StudentsCompanion.insert(
            id: id,
            updatedAt: now,
            syncStatus: SyncStatus.pendingCreate,
            studentNumber: studentNumber.trim(),
            fullName: name.trim(),
          ),
        );
        await _db.enrollmentDao.insert(
          EnrollmentsCompanion.insert(
            id: enrollmentId,
            updatedAt: now,
            syncStatus: SyncStatus.pendingCreate,
            studentId: id,
            classSectionId: classId,
          ),
        );
        if (bleUuid?.trim().isNotEmpty == true) {
          await _db.deviceDao.insert(
            DevicesCompanion.insert(
              id: newDatabaseId(),
              updatedAt: now,
              syncStatus: SyncStatus.pendingCreate,
              studentId: id,
              bleUuid: normalizedBleUuid!,
              deviceModel: 'Student device',
              registeredAt: now,
            ),
          );
        }
      });
    } catch (error) {
      if (error.toString().contains('students.student_number')) {
        throw const DuplicateStudentNumberException();
      }
      if (error.toString().contains('devices.ble_uuid')) {
        throw const DuplicateBleUuidException();
      }
      if (error.toString().contains('devices.student_id')) {
        throw const StudentAlreadyHasDeviceException();
      }
      rethrow;
    }
    final student = (await _db.studentDao.getOne(id))!;
    return student;
  }

  @override
  Future<Student> updateStudent({
    required String studentId,
    required String name,
    required String studentNumber,
  }) async {
    if (name.trim().isEmpty || studentNumber.trim().isEmpty) {
      throw const ClassValidationException();
    }
    final duplicate = await _db.studentDao.byNumber(studentNumber.trim());
    if (duplicate != null && duplicate.id != studentId) {
      throw const DuplicateStudentNumberException();
    }
    final now = DateTime.now();
    try {
      await _db.studentDao.updateStudent(
        studentId,
        StudentsCompanion(
          fullName: Value(name.trim()),
          studentNumber: Value(studentNumber.trim()),
          updatedAt: Value(now),
          syncStatus: const Value(SyncStatus.pendingUpdate),
        ),
      );
    } catch (error) {
      if (error.toString().contains('students.student_number')) {
        throw const DuplicateStudentNumberException();
      }
      rethrow;
    }
    final student = await _db.studentDao.getOne(studentId);
    if (student == null) throw const ClassSectionNotFoundException();
    return student;
  }

  @override
  Future<void> removeStudentFromClass({
    required String studentId,
    required String classId,
  }) => _db.enrollmentDao.deletePair(studentId, classId);
}
