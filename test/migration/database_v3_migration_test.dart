import 'dart:io';

import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v2 to v3 migration preserves teacher, student, device, offering, enrollment and attendance', () async {
    final directory = await Directory.systemTemp.createTemp(
      'classattend-v2-migration-',
    );
    final file = File(
      '${directory.path}${Platform.pathSeparator}classattend.sqlite',
    );
    var database = AppDatabase(NativeDatabase(file));
    addTearDown(() async {
      await database.close();
      if (await directory.exists()) await directory.delete(recursive: true);
    });

    final now = DateTime(2026, 9, 25, 9, 30);
    await database.teacherDao.save(
      TeachersCompanion.insert(
        id: 'teacher-existing',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        name: 'Ana Reyes',
      ),
    );
    await database.classDao.insert(
      ClassSectionsCompanion.insert(
        id: 'offering-existing',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        gradeLevel: 12,
        sectionLabel: 'STEM A',
        sectionCode: 'GRADE12-STEM A',
        subject: const Value('CPE1'),
        room: '301',
        scheduleStart: DateTime(2000, 1, 1, 9, 30),
        scheduleEnd: DateTime(2000, 1, 1, 10, 30),
        bleBeaconId: '',
        teacherId: 'teacher-existing',
      ),
    );
    await database.studentDao.insert(
      StudentsCompanion.insert(
        id: 'student-existing',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        studentNumber: 'S-001',
        fullName: 'Asnor Sumdad',
        isCurrent: const Value(true),
      ),
    );
    await database.deviceDao.insert(
      DevicesCompanion.insert(
        id: 'device-existing',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        studentId: 'student-existing',
        bleUuid: '12345678-1234-4234-8234-123456789abc',
        deviceModel: 'Android phone',
        registeredAt: now,
      ),
    );
    await database.enrollmentDao.insert(
      EnrollmentsCompanion.insert(
        id: 'enrollment-existing',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        studentId: 'student-existing',
        classSectionId: 'offering-existing',
      ),
    );
    await database.attendanceDao.upsertSession(
      AttendanceSessionsCompanion.insert(
        id: 'session-existing',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        classSectionId: 'offering-existing',
        title: const Value('CPE1'),
        date: now,
        startedAt: now,
        endedAt: Value(now.add(const Duration(minutes: 30))),
        status: AttendanceSessionStatus.completed,
      ),
    );
    await database.attendanceDao.upsertRecord(
      AttendanceRecordsCompanion.insert(
        id: 'record-existing',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        sessionId: 'session-existing',
        studentId: 'student-existing',
        status: AttendanceRecordStatus.present,
        detectedAt: Value(now),
      ),
    );
    await database.close();

    database = AppDatabase(
      NativeDatabase(
        file,
        setup: (sqlite) {
          sqlite.execute('DROP INDEX class_offering_identity_unique');
          sqlite.execute(
            'ALTER TABLE class_sections DROP COLUMN schedule_days',
          );
          sqlite.execute(
            'ALTER TABLE class_sections DROP COLUMN start_minutes_of_day',
          );
          sqlite.execute(
            'ALTER TABLE class_sections DROP COLUMN end_minutes_of_day',
          );
          sqlite.execute('ALTER TABLE teachers DROP COLUMN is_local');
          sqlite.execute(
            'ALTER TABLE attendance_sessions DROP COLUMN manual_override',
          );
          sqlite.execute('DROP TABLE app_session_preferences');
          sqlite.execute('PRAGMA user_version = 2');
        },
      ),
    );

    expect(
      (await database.teacherDao.getTeacherOrNull())?.id,
      'teacher-existing',
    );
    expect((await database.studentDao.getCurrent())?.id, 'student-existing');
    expect(
      (await database.deviceDao.getStudent('student-existing'))?.bleUuid,
      '12345678-1234-4234-8234-123456789abc',
    );
    final offering = await database.classDao.getClass('offering-existing');
    expect(offering?.subject, 'CPE1');
    expect(offering?.startMinutesOfDay, 570);
    expect(
      await database.classDao.getStudents('offering-existing'),
      hasLength(1),
    );
    expect(
      (await database.attendanceDao.getSession('session-existing'))?.status,
      AttendanceSessionStatus.completed,
    );
    expect(
      (await database.attendanceDao.getRecords('session-existing'))
          .single
          .recordStatus,
      AttendanceRecordStatus.present,
    );
  });
}
