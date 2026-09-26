import 'package:drift/drift.dart';

import '../../../core/utils/ble_identity.dart';
import '../../../core/utils/iterable_extensions.dart';
import '../../../domain/attendance_access_invitation.dart';
import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../services/storage/app_database.dart';

class DriftStudentRepository implements StudentRepository {
  DriftStudentRepository(
    this._db, {
    Future<bool> Function(String? classId, String? studentId)? canManage,
    Future<bool> Function()? canRegisterProfile,
  }) : _canManage = canManage ?? _allowManagement,
       _canRegisterProfile = canRegisterProfile ?? _allowProfileRegistration;
  final AppDatabase _db;
  final Future<bool> Function(String? classId, String? studentId) _canManage;
  final Future<bool> Function() _canRegisterProfile;

  static Future<bool> _allowManagement(
    String? classId,
    String? studentId,
  ) async => true;
  static Future<bool> _allowProfileRegistration() async => true;

  Future<void> _assertCanManage({String? classId, String? studentId}) async {
    if (!await _canManage(classId, studentId)) {
      throw const PermissionDeniedException();
    }
  }

  @override
  Future<List<Student>> getStudents() async => (await _db.studentDao.getAll())
      .where((student) => !student.id.startsWith('attendance:'))
      .toList(growable: false);
  @override
  Stream<List<Student>> watchStudents() => _db.studentDao.watchAll().map(
    (students) => students
        .where((student) => !student.id.startsWith('attendance:'))
        .toList(growable: false),
  );
  @override
  Future<Student?> getStudent(String studentId) async {
    final local = await _db.studentDao.getOne(studentId);
    if (!studentId.startsWith('attendance:')) return local;
    for (final entry in await _db.attendanceAccessDao.getAllOfferings()) {
      final grant = entry.$1;
      final offeringLink = entry.$2;
      final invitation = AttendanceAccessInvitation.decode(grant.payload);
      final offering = invitation.offerings
          .where((item) => item.offering.id == offeringLink.sourceOfferingId)
          .firstOrNull;
      if (offering == null) continue;
      final rosterIds = offering.rosterStudentIds.toSet();
      final source = invitation.roster
          .where(
            (item) =>
                rosterIds.contains(item.id) &&
                (attendanceAccessStudentId(item.id) == studentId ||
                    legacyAttendanceAccessStudentId(
                          offeringLink.localOfferingId,
                          item.id,
                        ) ==
                        studentId),
          )
          .firstOrNull;
      if (source != null) {
        return Student(
          id: studentId,
          updatedAt: grant.grantedAt,
          syncStatus: SyncStatus.synced,
          name: source.name,
          studentNumber: source.studentNumber,
          deviceRegistered: source.bleUuid != null,
        );
      }
    }
    return local;
  }

  @override
  Stream<Student?> watchStudent(String studentId) => _db.studentDao
      .watchOne(studentId)
      .asyncMap(
        (student) async => student == null ? null : await getStudent(studentId),
      );
  @override
  Future<Student?> getCurrentStudent() => _db.studentDao.getCurrent();
  @override
  Stream<Student?> watchCurrentStudent() => _db.studentDao.watchCurrent();

  @override
  Future<Student> registerStudent({
    required String name,
    required String studentNumber,
    String? sectionCode,
  }) async {
    if (!await _canRegisterProfile()) {
      throw const PermissionDeniedException();
    }
    if (name.trim().isEmpty || studentNumber.trim().isEmpty) {
      throw const ClassValidationException();
    }
    if (await _db.studentDao.byNumber(studentNumber.trim()) != null) {
      throw const DuplicateStudentNumberException();
    }
    final id = newDatabaseId();
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
            declaredSectionCode: const Value(null),
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
    await _assertCanManage(classId: classId);
    final existing = await _db.studentDao.byNumber(studentNumber.trim());
    if (existing != null &&
        await _db.enrollmentDao.containsPair(existing.id, classId)) {
      throw const DuplicateEnrollmentException();
    }
    return addStudentToOfferings(
      name: name,
      studentNumber: studentNumber,
      offeringIds: {classId},
      bleUuid: bleUuid,
    );
  }

  @override
  Future<Student> addStudentToOfferings({
    required String name,
    required String studentNumber,
    required Set<String> offeringIds,
    String? bleUuid,
  }) async {
    if (offeringIds.isEmpty) throw const ClassValidationException();
    for (final offeringId in offeringIds) {
      await _assertCanManage(classId: offeringId);
    }
    if (name.trim().isEmpty || studentNumber.trim().isEmpty) {
      throw const ClassValidationException();
    }
    final existing = await _db.studentDao.byNumber(studentNumber.trim());
    final normalizedBleUuid = bleUuid?.trim().isNotEmpty == true
        ? normalizeBleIdentity(bleUuid!)
        : null;
    if (bleUuid?.trim().isNotEmpty == true && normalizedBleUuid == null) {
      throw const InvalidBleUuidException();
    }
    for (final offeringId in offeringIds) {
      if (await _db.classDao.getClass(offeringId) == null) {
        throw const ClassSectionNotFoundException();
      }
    }
    final id = existing?.id ?? newDatabaseId();
    final existingDevice = await _db.deviceDao.getStudent(id);
    if (normalizedBleUuid != null &&
        existingDevice != null &&
        normalizeBleIdentity(existingDevice.bleUuid) != normalizedBleUuid) {
      throw const StudentAlreadyHasDeviceException();
    }
    final now = DateTime.now();
    try {
      await _db.transaction(() async {
        if (existing == null) {
          await _db.studentDao.insert(
            StudentsCompanion.insert(
              id: id,
              updatedAt: now,
              syncStatus: SyncStatus.pendingCreate,
              studentNumber: studentNumber.trim(),
              fullName: name.trim(),
            ),
          );
        } else if (existing.name != name.trim()) {
          await _db.studentDao.updateStudent(
            id,
            StudentsCompanion(
              fullName: Value(name.trim()),
              updatedAt: Value(now),
              syncStatus: const Value(SyncStatus.pendingUpdate),
            ),
          );
        }
        for (final offeringId in offeringIds) {
          if (await _db.enrollmentDao.containsPair(id, offeringId)) continue;
          await _db.enrollmentDao.insert(
            EnrollmentsCompanion.insert(
              id: newDatabaseId(),
              updatedAt: now,
              syncStatus: SyncStatus.pendingCreate,
              studentId: id,
              classSectionId: offeringId,
            ),
          );
        }
        if (normalizedBleUuid != null && existingDevice == null) {
          await _db.deviceDao.insert(
            DevicesCompanion.insert(
              id: newDatabaseId(),
              updatedAt: now,
              syncStatus: SyncStatus.pendingCreate,
              studentId: id,
              bleUuid: normalizedBleUuid,
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
  Future<void> setStudentOfferings({
    required String studentId,
    required Set<String> offeringIds,
  }) async {
    await _assertCanManage(studentId: studentId);
    for (final offeringId in offeringIds) {
      await _assertCanManage(classId: offeringId);
    }
    final teacher = await _db.teacherDao.getTeacherOrNull();
    if (teacher == null) throw const PermissionDeniedException();
    final memberships = await _db.classDao.getStudentOfferings(studentId);
    final managedMemberships = memberships
        .where((offering) => offering.teacherId == teacher.id)
        .map((offering) => offering.id)
        .toSet();
    await _db.transaction(() async {
      for (final offeringId in managedMemberships.difference(offeringIds)) {
        await _db.enrollmentDao.deletePair(studentId, offeringId);
      }
      for (final offeringId in offeringIds.difference(managedMemberships)) {
        await _db.enrollmentDao.insert(
          EnrollmentsCompanion.insert(
            id: newDatabaseId(),
            updatedAt: DateTime.now(),
            syncStatus: SyncStatus.pendingCreate,
            studentId: studentId,
            classSectionId: offeringId,
          ),
        );
      }
    });
  }

  @override
  Future<Student> updateStudent({
    required String studentId,
    required String name,
    required String studentNumber,
  }) async {
    await _assertCanManage(studentId: studentId);
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
  }) async {
    await _assertCanManage(classId: classId, studentId: studentId);
    await _db.enrollmentDao.deletePair(studentId, classId);
  }
}
