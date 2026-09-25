import 'package:attendance_system_paete/core/auth/application_session.dart';
import 'package:attendance_system_paete/core/auth/teacher_session.dart';
import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/features/student/data/drift_student_repository.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'student-only startup restores the persisted student without login',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final student = await DriftStudentRepository(database)
          .registerStudent(name: 'Asnor Sumdad', studentNumber: 'S-001');
      final session = ApplicationSession(
        database: database,
        teacherSession: TeacherSession(),
      );
      addTearDown(session.dispose);
      await session.initialize(teacherPinExists: false);
      expect(session.entry, ApplicationEntry.student);
      expect(session.currentStudentId, student.id);
      expect(session.initialLocation, '/student');
    },
  );

  test('coexisting teacher and student restore the last role and guard teacher with PIN', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final now = DateTime(2026, 9, 25);
    await database.teacherDao.save(
      TeachersCompanion.insert(
        id: 'teacher-local',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        name: 'Ana Reyes',
      ),
    );
    final student = await DriftStudentRepository(database)
        .registerStudent(name: 'Asnor Sumdad', studentNumber: 'S-001');
    final teacherSession = TeacherSession(state: TeacherSessionState.locked);
    final session = ApplicationSession(
      database: database,
      teacherSession: teacherSession,
    );
    addTearDown(session.dispose);
    await database.appSessionDao.savePreferences(
      lastActiveRole: 'student',
      activeStudentId: student.id,
    );
    await session.initialize(teacherPinExists: true);
    expect(session.entry, ApplicationEntry.student);
    await session.selectTeacher();
    expect(session.entry, ApplicationEntry.teacherLocked);
    teacherSession.authenticate();
    expect(session.entry, ApplicationEntry.teacher);

    final restarted = ApplicationSession(
      database: database,
      teacherSession: TeacherSession(state: TeacherSessionState.locked),
    );
    addTearDown(restarted.dispose);
    await restarted.initialize(teacherPinExists: true);
    expect(restarted.entry, ApplicationEntry.teacherLocked);
  });

  test('empty install starts at role selection', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final session = ApplicationSession(
      database: database,
      teacherSession: TeacherSession(),
    );
    addTearDown(session.dispose);
    await session.initialize(teacherPinExists: false);
    expect(session.entry, ApplicationEntry.welcome);
    expect(session.initialLocation, '/welcome');
  });
}
