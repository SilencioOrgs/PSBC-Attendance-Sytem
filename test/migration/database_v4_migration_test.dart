import 'dart:io';

import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'v3 to current schema preserves local data and creates new storage',
    () async {
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'classattend-v4-${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      final before = AppDatabase(NativeDatabase(file));
      final now = DateTime(2026, 9, 23, 8);
      await before.teacherDao.save(
        TeachersCompanion.insert(
          id: 'teacher-v3',
          updatedAt: now,
          syncStatus: SyncStatus.synced,
          name: 'Ana Reyes',
        ),
      );
      await before.classDao.insert(
        ClassSectionsCompanion.insert(
          id: 'class-v3',
          updatedAt: now,
          syncStatus: SyncStatus.synced,
          gradeLevel: 12,
          sectionLabel: 'STEM A',
          sectionCode: 'GRADE12-STEM A',
          room: 'Room 1',
          scheduleStart: now,
          scheduleEnd: now.add(const Duration(hours: 1)),
          bleBeaconId: '',
          teacherId: 'teacher-v3',
        ),
      );
      await before.studentDao.insert(
        StudentsCompanion.insert(
          id: 'student-v3',
          updatedAt: now,
          syncStatus: SyncStatus.synced,
          studentNumber: 'S-001',
          fullName: 'Maria Santos',
        ),
      );
      await before.enrollmentDao.insert(
        EnrollmentsCompanion.insert(
          id: 'enrollment-v3',
          updatedAt: now,
          syncStatus: SyncStatus.synced,
          studentId: 'student-v3',
          classSectionId: 'class-v3',
        ),
      );
      await before.deviceDao.insert(
        DevicesCompanion.insert(
          id: 'device-v3',
          updatedAt: now,
          syncStatus: SyncStatus.synced,
          studentId: 'student-v3',
          bleUuid: 'de305d54-75b4-431b-adb2-eb6b9e546014',
          deviceModel: 'Phone',
          registeredAt: now,
        ),
      );
      await before.attendanceDao.startSession(
        session: AttendanceSessionsCompanion.insert(
          id: 'session-v3',
          updatedAt: now,
          syncStatus: SyncStatus.synced,
          classSectionId: 'class-v3',
          date: DateTime(now.year, now.month, now.day),
          startedAt: now,
          status: AttendanceSessionStatus.completed,
        ),
        roster: [
          Student(
            id: 'student-v3',
            updatedAt: now,
            syncStatus: SyncStatus.synced,
            name: 'Maria Santos',
            studentNumber: 'S-001',
          ),
        ],
      );

      await before.customStatement('DROP TABLE auto_report_executions');
      await before.customStatement('DROP TABLE auto_report_runs');
      await before.customStatement('DROP TABLE attendance_access_offerings');
      await before.customStatement('DROP TABLE attendance_access_grants');
      await before.customStatement(
        'ALTER TABLE app_settings DROP COLUMN automatic_report_mode',
      );
      await before.customStatement(
        'ALTER TABLE app_settings DROP COLUMN automatic_report_hour',
      );
      await before.customStatement(
        'ALTER TABLE app_settings DROP COLUMN automatic_report_minute',
      );
      await before.customStatement(
        'ALTER TABLE app_settings DROP COLUMN automatic_report_weekday',
      );
      await before.customStatement('PRAGMA user_version = 3');
      await before.close();

      final after = AppDatabase(NativeDatabase(file));
      addTearDown(() async {
        await after.close();
        if (await file.exists()) await file.delete();
      });

      expect(after.schemaVersion, 7);
      expect((await after.teacherDao.getTeacherOrNull())?.name, 'Ana Reyes');
      expect((await after.classDao.getClass('class-v3'))?.subject, 'General');
      expect(
        (await after.enrollmentDao.containsPair('student-v3', 'class-v3')),
        isTrue,
      );
      expect(
        (await after.deviceDao.getStudent('student-v3'))?.bleUuid,
        'de305d54-75b4-431b-adb2-eb6b9e546014',
      );
      expect((await after.attendanceDao.getSessions()).single.id, 'session-v3');
      expect(await after.attendanceAccessDao.getAll(), isEmpty);
    },
  );
}
