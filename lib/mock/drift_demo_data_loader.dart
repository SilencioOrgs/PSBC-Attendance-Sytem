import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/section_code.dart';
import '../domain/models.dart';
import '../services/auth/teacher_pin_service.dart';
import '../services/storage/app_database.dart';
import '../services/storage/demo_data_loader.dart';
import 'seed_data.dart';

/// Debug-only adapter that copies Phase 1 fixtures into local Drift storage.
class DriftDemoDataLoader implements DemoDataLoader {
  DriftDemoDataLoader(this._db, this._pinService);
  final AppDatabase _db;
  final TeacherPinService _pinService;

  String _id(String value) =>
      const Uuid().v5(Namespace.url.value, 'classattend:demo:$value');

  @override
  Future<void> load() async {
    if (!kDebugMode) {
      throw StateError('Demo data cannot be loaded in a release build.');
    }
    final existingTeacher = await _db.teacherDao.getTeacherOrNull();
    final teacherId = existingTeacher?.id ?? _id(seedTeacher.id);
    await _db.transaction(() async {
      if (existingTeacher == null) {
        await _db.teacherDao.save(
          TeachersCompanion.insert(
            id: teacherId,
            updatedAt: seedTeacher.updatedAt,
            syncStatus: SyncStatus.synced,
            name: seedTeacher.name,
          ),
        );
      }
      for (final section in seedClasses) {
        await _db.classDao.upsert(
          ClassSectionsCompanion.insert(
            id: _id(section.id),
            updatedAt: section.updatedAt,
            syncStatus: SyncStatus.synced,
            gradeLevel: section.gradeLevel,
            sectionLabel: section.sectionLabel,
            sectionCode: normalizeSectionCode(
              'GRADE${section.gradeLevel}-${section.sectionLabel}',
            ),
            subject: Value(section.subject),
            room: section.room,
            scheduleStart: section.scheduleStart!,
            scheduleEnd: section.scheduleEnd!,
            bleBeaconId: section.bleBeaconId,
            teacherId: teacherId,
          ),
        );
      }
      await _db.studentDao.setAllNotCurrent();
      for (final student in seedStudents) {
        await _db.studentDao.upsert(
          StudentsCompanion.insert(
            id: _id(student.id),
            updatedAt: student.updatedAt,
            syncStatus: SyncStatus.synced,
            studentNumber: student.studentNumber,
            fullName: student.name,
            isCurrent: Value(student.id == 'student-01'),
          ),
        );
        await _db.enrollmentDao.upsert(
          EnrollmentsCompanion.insert(
            id: _id('enrollment:${student.id}'),
            updatedAt: student.updatedAt,
            syncStatus: SyncStatus.synced,
            studentId: _id(student.id),
            classSectionId: _id(student.classId),
          ),
        );
      }
      final sessions = [seedTodaySession, ...seedHistoricalSessions];
      for (final session in sessions) {
        await _db.attendanceDao.upsertSession(
          AttendanceSessionsCompanion.insert(
            id: _id(session.id),
            updatedAt: session.updatedAt,
            syncStatus: SyncStatus.synced,
            classSectionId: _id(session.classId),
            date: session.date ?? session.startedAt,
            startedAt: session.startedAt,
            endedAt: Value(session.endedAt),
            scanDurationSeconds: Value(session.scanDurationSeconds),
            title: Value(session.title),
            status: AttendanceSessionStatus.completed,
          ),
        );
      }
      for (final record in [
        ...seedAttendanceRecords,
        ...seedHistoricalRecords,
      ]) {
        await _db.attendanceDao.upsertRecord(
          AttendanceRecordsCompanion.insert(
            id: _id(record.id),
            updatedAt: record.updatedAt,
            syncStatus: SyncStatus.synced,
            sessionId: _id(record.sessionId),
            studentId: _id(record.studentId),
            status: record.isPresent
                ? AttendanceRecordStatus.present
                : AttendanceRecordStatus.absent,
            rssi: Value(record.isPresent ? -54 : null),
            detectedAt: Value(record.detectedAt),
          ),
        );
      }
      for (final device in seedDevices) {
        await _db.deviceDao.upsert(
          DevicesCompanion.insert(
            id: _id(device.id),
            updatedAt: device.updatedAt,
            syncStatus: SyncStatus.synced,
            studentId: _id(device.ownerStudentId!),
            bleUuid: device.address,
            deviceModel: device.name,
            registeredAt: device.registeredAt ?? device.updatedAt,
          ),
        );
      }
      await _db.settingsDao.save(
        AppSettingsRowsCompanion.insert(
          id: _id(seedSettings.id),
          updatedAt: seedSettings.updatedAt,
          syncStatus: SyncStatus.synced,
          singletonKey: const Value('settings'),
          scanDurationSeconds: seedSettings.scanDurationSeconds,
          rssiThreshold: seedSettings.rssiThreshold,
          soundEnabled: seedSettings.soundEnabled,
          vibrationEnabled: seedSettings.vibrationEnabled,
        ),
      );
    });
    if (!await _pinService.hasPin()) await _pinService.savePin(seedTeacherPin);
  }
}
