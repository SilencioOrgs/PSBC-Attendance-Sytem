import 'package:attendance_system_paete/domain/attendance_window_policy.dart';
import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/domain/repositories.dart';
import 'package:attendance_system_paete/features/attendance/data/drift_attendance_repository.dart';
import 'package:attendance_system_paete/features/classes/data/drift_class_repository.dart';
import 'package:attendance_system_paete/features/student/data/drift_student_repository.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rejects starts before the early grace unless manually overridden',
    () async {
      final database = await _database(scheduleDays: {Weekday.wednesday});
      addTearDown(database.close);
      final section = (await DriftClassRepository(
        database,
      ).getClasses()).single;
      final repository = DriftAttendanceRepository(
        database,
        clock: () => DateTime(2026, 9, 23, 7, 49),
        canAccessOffering: _allow,
      );

      await expectLater(
        repository.startSession(section.id),
        throwsA(
          isA<AttendanceWindowException>().having(
            (error) => error.status,
            'status',
            AttendanceWindowStatus.tooEarly,
          ),
        ),
      );
      final override = await repository.startSession(
        section.id,
        manualOverride: true,
      );
      expect(override.manualOverride, isTrue);
    },
  );

  test('allows an inside-window start without a manual override', () async {
    final database = await _database(scheduleDays: {Weekday.wednesday});
    addTearDown(database.close);
    final section = (await DriftClassRepository(database).getClasses()).single;
    final session = await DriftAttendanceRepository(
      database,
      clock: () => DateTime(2026, 9, 23, 8, 30),
      canAccessOffering: _allow,
    ).startSession(section.id);
    expect(session.manualOverride, isFalse);
  });

  test('rejects the wrong schedule day at the repository boundary', () async {
    final database = await _database(scheduleDays: {Weekday.wednesday});
    addTearDown(database.close);
    final section = (await DriftClassRepository(database).getClasses()).single;
    await expectLater(
      DriftAttendanceRepository(
        database,
        clock: () => DateTime(2026, 9, 24, 8, 30),
        canAccessOffering: _allow,
      ).startSession(section.id),
      throwsA(
        isA<AttendanceWindowException>().having(
          (error) => error.status,
          'status',
          AttendanceWindowStatus.wrongDay,
        ),
      ),
    );
  });

  test('preserves the existing no-schedule manual override behavior', () async {
    final database = await _database(scheduleDays: const {});
    addTearDown(database.close);
    final section = (await DriftClassRepository(database).getClasses()).single;
    final repository = DriftAttendanceRepository(
      database,
      clock: () => DateTime(2026, 9, 23, 8, 30),
      canAccessOffering: _allow,
    );
    await expectLater(
      repository.startSession(section.id),
      throwsA(
        isA<AttendanceWindowException>().having(
          (error) => error.status,
          'status',
          AttendanceWindowStatus.noSchedule,
        ),
      ),
    );
    expect(
      (await repository.startSession(
        section.id,
        manualOverride: true,
      )).manualOverride,
      isTrue,
    );
  });
}

Future<AppDatabase> _database({required Set<Weekday> scheduleDays}) async {
  final database = AppDatabase(NativeDatabase.memory());
  final teacher = DateTime(2026, 9, 23);
  await database.teacherDao.save(
    TeachersCompanion.insert(
      id: 'teacher-window-test',
      updatedAt: teacher,
      syncStatus: SyncStatus.synced,
      name: 'Test Teacher',
    ),
  );
  final section = await DriftClassRepository(database).createClass(
    gradeLevel: 12,
    sectionLabel: 'STEM A',
    subject: 'Mathematics',
    room: 'Room 1',
    scheduleStart: DateTime(2000, 1, 1, 8),
    scheduleEnd: DateTime(2000, 1, 1, 9),
    scheduleDays: scheduleDays,
  );
  await DriftStudentRepository(database).addStudentToClass(
    name: 'Maria Santos',
    studentNumber: 'W-001',
    classId: section.id,
  );
  return database;
}

Future<bool> _allow(String offeringId) async => true;
