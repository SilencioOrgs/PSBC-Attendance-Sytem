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
    if (await _db.studentDao.byNumber(studentNumber.trim()) != null) {
      throw const DuplicateStudentNumberException();
    }

    var section = await _db.classDao.getByCode(normalizedCode);
    if (section == null) {
      // Separate student and teacher phones have independent offline databases.
      // Keep the student's declared section locally; the teacher confirms the
      // code when adding the student to their own roster.
      final teacher = await _db.teacherDao.getTeacherOrNull();
      final teacherId = teacher?.id ?? newDatabaseId();
      final sectionId = newDatabaseId();
      final now = DateTime.now();
      if (teacher == null) {
        await _db.teacherDao.save(
          TeachersCompanion.insert(
            id: teacherId,
            updatedAt: now,
            syncStatus: SyncStatus.pendingCreate,
            name: 'Local enrollment metadata',
          ),
        );
      }
      await _db.classDao.insert(
        ClassSectionsCompanion.insert(
          id: sectionId,
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate,
          gradeLevel: parsed.gradeLevel,
          sectionLabel: parsed.sectionLabel,
          sectionCode: normalizedCode,
          subject: const Value('Awaiting teacher details'),
          room: 'Not provided',
          scheduleStart: DateTime(2000),
          scheduleEnd: DateTime(2000),
          bleBeaconId: '',
          teacherId: teacherId,
        ),
      );
      section = await _db.classDao.getClass(sectionId);
    }
    final registeredSection = section;
    if (registeredSection == null) {
      throw const ClassSectionNotFoundException();
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
            classSectionId: registeredSection.id,
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
      classId: registeredSection.id,
      gradeLevel: 'Grade ${parsed.gradeLevel}',
      deviceRegistered: false,
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
    if (bleUuid?.trim().isNotEmpty == true && !_isUuid(bleUuid!.trim())) {
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
              bleUuid: bleUuid!.trim(),
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

  bool _isUuid(String value) => RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  ).hasMatch(value);

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
