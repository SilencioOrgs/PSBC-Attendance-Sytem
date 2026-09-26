import 'package:drift/drift.dart';

import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../core/utils/section_code.dart';
import '../../../services/storage/app_database.dart';

class DriftClassRepository implements ClassRepository {
  DriftClassRepository(
    this._db, {
    Future<bool> Function(String? classId)? canManage,
  }) : _canManage = canManage ?? _allowManagement;
  final AppDatabase _db;
  final Future<bool> Function(String? classId) _canManage;

  static Future<bool> _allowManagement(String? classId) async => true;

  Future<void> _assertCanManage([String? classId]) async {
    if (!await _canManage(classId)) throw const PermissionDeniedException();
  }

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
  Stream<ClassSection?> watchClassByCode(String sectionCode) =>
      _db.classDao.watchByCode(sectionCode);
  @override
  Future<List<ClassSection>> getStudentOfferings(String studentId) =>
      _db.classDao.getStudentOfferings(studentId);
  @override
  Stream<List<ClassSection>> watchStudentOfferings(String studentId) =>
      _db.classDao.watchStudentOfferings(studentId);
  @override
  Future<List<Student>> getStudents(String classId) =>
      _db.classDao.getStudents(classId);
  @override
  Stream<List<Student>> watchStudents(String classId) =>
      _db.classDao.watchStudents(classId);

  @override
  Future<ClassSection> createClass({
    required int gradeLevel,
    required String sectionLabel,
    required String subject,
    required String room,
    required DateTime scheduleStart,
    required DateTime scheduleEnd,
    Set<Weekday> scheduleDays = const {},
  }) async {
    await _assertCanManage();
    final parsed = parseSectionCode('GRADE$gradeLevel-$sectionLabel');
    if (gradeLevel <= 0 ||
        parsed == null ||
        subject.trim().isEmpty ||
        room.trim().isEmpty ||
        !scheduleEnd.isAfter(scheduleStart)) {
      throw const ClassValidationException();
    }
    final sectionCode = normalizeSectionCode('GRADE$gradeLevel-$sectionLabel');
    final teacher = await _db.teacherDao.getTeacherOrNull();
    if (teacher == null) throw const ClassSectionNotFoundException();
    if (await _db.classDao.findOffering(teacher.id, sectionCode, subject) !=
        null) {
      throw const DuplicateClassException();
    }
    final id = newDatabaseId();
    final now = DateTime.now();
    try {
      await _db.classDao.insert(
        ClassSectionsCompanion.insert(
          id: id,
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate,
          gradeLevel: gradeLevel,
          sectionLabel: parsed.sectionLabel,
          sectionCode: sectionCode,
          subject: Value(subject.trim()),
          room: room.trim(),
          scheduleStart: scheduleStart,
          scheduleEnd: scheduleEnd,
          scheduleDays: Value(weekdayMask(scheduleDays)),
          startMinutesOfDay: Value(
            scheduleStart.hour * 60 + scheduleStart.minute,
          ),
          endMinutesOfDay: Value(scheduleEnd.hour * 60 + scheduleEnd.minute),
          bleBeaconId: '',
          teacherId: teacher.id,
        ),
      );
    } catch (error) {
      if (error.toString().contains('class_offering_identity_unique')) {
        throw const DuplicateClassException();
      }
      rethrow;
    }
    return (await _db.classDao.getClass(id))!;
  }

  @override
  Future<ClassSection> updateClass(ClassSection section) async {
    await _assertCanManage(section.id);
    final parsed = parseSectionCode(
      'GRADE${section.gradeLevel}-${section.sectionLabel}',
    );
    if (parsed == null ||
        section.subject.trim().isEmpty ||
        section.room.trim().isEmpty ||
        section.scheduleStart == null ||
        section.scheduleEnd == null ||
        !section.scheduleEnd!.isAfter(section.scheduleStart!)) {
      throw const ClassValidationException();
    }
    final code = normalizeSectionCode(
      'GRADE${section.gradeLevel}-${parsed.sectionLabel}',
    );
    final duplicate = await _db.classDao.findOffering(
      section.teacherId,
      code,
      section.subject,
    );
    if (duplicate != null && duplicate.id != section.id) {
      throw const DuplicateClassException();
    }
    await _db.classDao.updateClass(
      section.id,
      ClassSectionsCompanion(
        updatedAt: Value(DateTime.now()),
        syncStatus: const Value(SyncStatus.pendingUpdate),
        gradeLevel: Value(section.gradeLevel),
        sectionLabel: Value(parsed.sectionLabel),
        sectionCode: Value(code),
        subject: Value(section.subject.trim()),
        room: Value(section.room.trim()),
        scheduleStart: Value(section.scheduleStart!),
        scheduleEnd: Value(section.scheduleEnd!),
        scheduleDays: Value(weekdayMask(section.scheduleDays)),
        startMinutesOfDay: Value(
          section.startMinutesOfDay ??
              section.scheduleStart!.hour * 60 + section.scheduleStart!.minute,
        ),
        endMinutesOfDay: Value(
          section.endMinutesOfDay ??
              section.scheduleEnd!.hour * 60 + section.scheduleEnd!.minute,
        ),
      ),
    );
    final saved = await _db.classDao.getClass(section.id);
    if (saved == null) throw const ClassSectionNotFoundException();
    return saved;
  }

  @override
  Future<void> deleteClass(String classId) async {
    await _assertCanManage(classId);
    await _db.classDao.deleteClass(classId);
  }
}
