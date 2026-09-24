import 'dart:async';
import 'dart:io';

import 'package:attendance_system_paete/core/providers/repository_providers.dart';
import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/domain/repositories.dart';
import 'package:attendance_system_paete/features/attendance/presentation/providers/attendance_provider.dart';
import 'package:attendance_system_paete/features/attendance/data/drift_attendance_repository.dart';
import 'package:attendance_system_paete/features/classes/data/drift_class_repository.dart';
import 'package:attendance_system_paete/features/classes/presentation/providers/class_provider.dart';
import 'package:attendance_system_paete/features/device/data/drift_device_repository.dart';
import 'package:attendance_system_paete/features/student/data/drift_student_repository.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _teacherId = '10000000-0000-4000-8000-000000000001';
const _classId = '20000000-0000-4000-8000-000000000001';
const _sessionId = '30000000-0000-4000-8000-000000000001';
const _studentId = '40000000-0000-4000-8000-000000000001';
const _student2Id = '40000000-0000-4000-8000-000000000002';

void main() {
  // These tests intentionally open separate in-memory executors per scenario.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    final now = DateTime(2026, 9, 23, 8);
    await database.teacherDao.save(
      TeachersCompanion.insert(
        id: _teacherId,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        name: 'Test Teacher',
      ),
    );
    await database.classDao.upsert(
      ClassSectionsCompanion.insert(
        id: _classId,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        gradeLevel: 12,
        sectionLabel: 'STEM A',
        sectionCode: 'GRADE12-STEM A',
        room: 'Room 1',
        scheduleStart: now,
        scheduleEnd: now.add(const Duration(minutes: 90)),
        bleBeaconId: 'test-beacon',
        teacherId: _teacherId,
      ),
    );
    await database.studentDao.upsert(
      StudentsCompanion.insert(
        id: _studentId,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        studentNumber: 'T-001',
        fullName: 'Maria Santos',
      ),
    );
    await database.enrollmentDao.upsert(
      EnrollmentsCompanion.insert(
        id: '50000000-0000-4000-8000-000000000001',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        studentId: _studentId,
        classSectionId: _classId,
      ),
    );
    await database.attendanceDao.upsertSession(
      AttendanceSessionsCompanion.insert(
        id: _sessionId,
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        classSectionId: _classId,
        title: const Value('Test session'),
        date: now,
        startedAt: now,
        status: AttendanceSessionStatus.completed,
      ),
    );
    await database.attendanceDao.upsertRecord(
      AttendanceRecordsCompanion.insert(
        id: '60000000-0000-4000-8000-000000000001',
        updatedAt: now,
        syncStatus: SyncStatus.synced,
        sessionId: _sessionId,
        studentId: _studentId,
        status: AttendanceRecordStatus.present,
        detectedAt: Value(now),
      ),
    );
  });

  tearDown(() => database.close());

  test(
    'attendance provider receives DAO writes without invalidation',
    () async {
      final repository = DriftAttendanceRepositoryForTest(database);
      final container = ProviderContainer(
        overrides: [attendanceRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final changed = Completer<void>();
      final provider = attendanceRecordsProvider(_sessionId);
      container.listen(provider, (previous, next) {
        final record = next.value?.firstOrNull;
        if (record != null && !record.isPresent && !changed.isCompleted) {
          changed.complete();
        }
      });

      await container.read(provider.future);
      await container.read(provider.notifier).toggleStudent(_studentId);
      await changed.future.timeout(const Duration(seconds: 3));
      expect(container.read(provider).requireValue.single.isPresent, isFalse);
    },
  );

  test('roster stream re-emits when an enrollment is inserted', () async {
    final repository = DriftClassRepository(database);
    final container = ProviderContainer(
      overrides: [classRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final updated = Completer<void>();
    final countUpdated = Completer<void>();
    final provider = classRosterProvider(_classId);
    final sectionProvider = classByIdProvider(_classId);
    container.listen(provider, (previous, next) {
      if (next.value?.length == 2 && !updated.isCompleted) updated.complete();
    });
    container.listen(sectionProvider, (previous, next) {
      if (next.value?.studentCount == 2 && !countUpdated.isCompleted) {
        countUpdated.complete();
      }
    });
    await container.read(provider.future);
    await container.read(sectionProvider.future);

    final now = DateTime.now();
    await database.studentDao.upsert(
      StudentsCompanion.insert(
        id: _student2Id,
        updatedAt: now,
        syncStatus: SyncStatus.pendingCreate,
        studentNumber: 'T-002',
        fullName: 'Juan Dela Cruz',
      ),
    );
    await database.enrollmentDao.upsert(
      EnrollmentsCompanion.insert(
        id: '50000000-0000-4000-8000-000000000002',
        updatedAt: now,
        syncStatus: SyncStatus.pendingCreate,
        studentId: _student2Id,
        classSectionId: _classId,
      ),
    );
    await updated.future.timeout(const Duration(seconds: 3));
    await countUpdated.future.timeout(const Duration(seconds: 3));
    expect(container.read(provider).requireValue, hasLength(2));
    expect(container.read(sectionProvider).requireValue?.studentCount, 2);
  });

  test(
    'student write normalizes section input and rejects duplicate numbers',
    () async {
      final repository = DriftStudentRepository(database);
      final first = await repository.registerStudent(
        name: 'New Student',
        studentNumber: 'T-003',
        sectionCode: ' grade 12   stem a ',
      );
      expect(first.classId, _classId);
      await expectLater(
        repository.registerStudent(
          name: 'Another Student',
          studentNumber: 'T-003',
          sectionCode: 'GRADE12-STEM A',
        ),
        throwsA(isA<DuplicateStudentNumberException>()),
      );
    },
  );

  test('duplicate BLE UUID reports a repository validation error', () async {
    final studentRepository = DriftStudentRepository(database);
    final firstStudent = await studentRepository.registerStudent(
      name: 'Device Owner One',
      studentNumber: 'D-001',
      sectionCode: 'GRADE12-STEM A',
    );
    final secondStudent = await studentRepository.registerStudent(
      name: 'Device Owner Two',
      studentNumber: 'D-002',
      sectionCode: 'GRADE12-STEM A',
    );
    final devices = DriftDeviceRepository(database);
    await devices.registerDevice(
      firstStudent.id,
      'Band',
      bleUuid: '8f3f5d3e-54e2-4e15-9b2c-810859f38d33',
    );
    await expectLater(
      devices.registerDevice(
        secondStudent.id,
        'Band',
        bleUuid: '8f3f5d3e-54e2-4e15-9b2c-810859f38d33',
      ),
      throwsA(isA<DuplicateBleUuidException>()),
    );
  });

  test(
    'attendance review keeps undetected students unconfirmed until save',
    () async {
      final repository = DriftAttendanceRepository(database);
      final session = await repository.startSession(_classId);
      final initial = await repository.getRecords(session.id);
      expect(initial, hasLength(1));
      expect(initial.single.recordStatus, AttendanceRecordStatus.notDetected);

      await repository.markDetected(session.id, _studentId, rssi: -48);
      expect(
        (await repository.getRecords(session.id)).single.isPresent,
        isTrue,
      );
      await repository.finishScan(session.id);
      await repository.completeSession(session.id);
      expect(
        (await repository.getSession(session.id))?.status,
        AttendanceSessionStatus.completed,
      );
      expect(
        (await repository.getRecords(session.id)).single.recordStatus,
        AttendanceRecordStatus.present,
      );
    },
  );

  test(
    'attendance finalization rolls back when a critical write fails',
    () async {
      final repository = DriftAttendanceRepository(database);
      final session = await repository.startSession(_classId);
      await repository.finishScan(session.id);
      expect(
        (await repository.getSession(session.id))?.status,
        AttendanceSessionStatus.review,
      );

      await database.customStatement('''
      CREATE TRIGGER fail_session_completion
      BEFORE UPDATE ON attendance_sessions
      WHEN NEW.status = 'completed'
      BEGIN
        SELECT RAISE(ABORT, 'simulated session write failure');
      END
    ''');
      await expectLater(
        repository.completeSession(session.id),
        throwsA(anything),
      );
      expect(
        (await repository.getSession(session.id))?.status,
        AttendanceSessionStatus.review,
      );
      expect(
        (await repository.getRecords(session.id)).single.recordStatus,
        AttendanceRecordStatus.notDetected,
      );

      await database.customStatement('DROP TRIGGER fail_session_completion');
      await repository.completeSession(session.id);
      expect(
        (await repository.getRecords(session.id)).single.recordStatus,
        AttendanceRecordStatus.absent,
      );
    },
  );

  test(
    'class and student management validate and persist through repositories',
    () async {
      final classes = DriftClassRepository(database);
      final created = await classes.createClass(
        gradeLevel: 11,
        sectionLabel: 'HUMSS A',
        subject: 'English',
        room: 'Room 2',
        scheduleStart: DateTime(2000, 1, 1, 10),
        scheduleEnd: DateTime(2000, 1, 1, 11),
      );
      expect(created.sectionCode, 'GRADE11-HUMSS A');
      final updatedClass = await classes.updateClass(
        ClassSection(
          id: created.id,
          updatedAt: created.updatedAt,
          syncStatus: created.syncStatus,
          name: created.name,
          subject: 'English 2',
          room: 'Room 3',
          schedule: created.schedule,
          studentCount: created.studentCount,
          gradeLevel: created.gradeLevel,
          sectionLabel: created.sectionLabel,
          sectionCode: created.sectionCode,
          scheduleStart: DateTime(2000, 1, 1, 10),
          scheduleEnd: DateTime(2000, 1, 1, 11),
          teacherId: created.teacherId,
        ),
      );
      expect(updatedClass.subject, 'English 2');
      await expectLater(
        classes.createClass(
          gradeLevel: 11,
          sectionLabel: 'humss a',
          subject: 'English',
          room: 'Room 2',
          scheduleStart: DateTime(2000, 1, 1, 10),
          scheduleEnd: DateTime(2000, 1, 1, 11),
        ),
        throwsA(isA<DuplicateClassException>()),
      );

      final students = DriftStudentRepository(database);
      final added = await students.addStudentToClass(
        name: 'Juan Dela Cruz',
        studentNumber: 'T-004',
        classId: created.id,
      );
      expect(
        (await classes.getStudents(created.id)).single.name,
        'Juan Dela Cruz',
      );
      await expectLater(
        students.addStudentToClass(
          name: 'Duplicate',
          studentNumber: 'T-004',
          classId: created.id,
        ),
        throwsA(isA<DuplicateStudentNumberException>()),
      );
      await students.updateStudent(
        studentId: added.id,
        name: 'Juan Cruz',
        studentNumber: 'T-004',
      );
      expect((await classes.getStudents(created.id)).single.name, 'Juan Cruz');
      final session = await DriftAttendanceRepository(database)
          .startSession(created.id);
      await students.removeStudentFromClass(
        studentId: added.id,
        classId: created.id,
      );
      expect(await classes.getStudents(created.id), isEmpty);

      await classes.deleteClass(created.id);
      expect(await classes.getClass(created.id), isNull);
      expect(await classes.getStudents(created.id), isEmpty);
      expect(
        await DriftAttendanceRepository(database).getSession(session.id),
        isNull,
      );
    },
  );

  test('fresh database starts without preloaded classroom data', () async {
    final cleanDatabase = AppDatabase(NativeDatabase.memory());
    addTearDown(cleanDatabase.close);

    expect(await cleanDatabase.classDao.getClasses(), isEmpty);
    expect(await cleanDatabase.studentDao.getAll(), isEmpty);
    expect(await cleanDatabase.attendanceDao.getSessions(), isEmpty);
    expect(await cleanDatabase.deviceDao.getAll(), isEmpty);
  });

  test('student-only setup stores its declared section without creating teacher or class rows', () async {
    final cleanDatabase = AppDatabase(NativeDatabase.memory());
    addTearDown(cleanDatabase.close);
    final repository = DriftStudentRepository(cleanDatabase);
    final student = await repository.registerStudent(
      name: 'Maria Santos',
      studentNumber: 'S-001',
      sectionCode: 'GRADE12-STEM A',
    );

    expect(student.classId, isEmpty);
    expect(student.sectionCode, 'GRADE12-STEM A');
    expect(await cleanDatabase.teacherDao.getTeacherOrNull(), isNull);
    expect(await cleanDatabase.classDao.getClasses(), isEmpty);
    expect(
      await cleanDatabase.select(cleanDatabase.enrollments).get(),
      isEmpty,
    );
    expect(await cleanDatabase.attendanceDao.getSessions(), isEmpty);
    expect(await cleanDatabase.deviceDao.getAll(), isEmpty);
    expect(
      (await repository.getCurrentStudent())?.sectionCode,
      'GRADE12-STEM A',
    );
  });

  test(
    'version 1 synthetic student classes migrate to declared section data',
    () async {
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'classattend-migration-${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      var database = AppDatabase(NativeDatabase(file));
      final now = DateTime(2026, 9, 24, 8);
      await database.teacherDao.save(
        TeachersCompanion.insert(
          id: 'local-teacher',
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate,
          name: 'Local enrollment metadata',
        ),
      );
      await database.classDao.insert(
        ClassSectionsCompanion.insert(
          id: 'local-class',
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate,
          gradeLevel: 12,
          sectionLabel: 'STEM A',
          sectionCode: 'GRADE12-STEM A',
          subject: const Value('Awaiting teacher details'),
          room: 'Not provided',
          scheduleStart: DateTime(2000),
          scheduleEnd: DateTime(2000),
          bleBeaconId: '',
          teacherId: 'local-teacher',
        ),
      );
      await database.studentDao.insert(
        StudentsCompanion.insert(
          id: 'local-student',
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate,
          studentNumber: 'S-MIGRATE',
          fullName: 'Maria Santos',
          isCurrent: const Value(true),
        ),
      );
      await database.enrollmentDao.insert(
        EnrollmentsCompanion.insert(
          id: 'local-enrollment',
          updatedAt: now,
          syncStatus: SyncStatus.pendingCreate,
          studentId: 'local-student',
          classSectionId: 'local-class',
        ),
      );
      await database.close();

      database = AppDatabase(
        NativeDatabase(
          file,
          setup: (sqlite) {
            sqlite.execute(
              'ALTER TABLE students DROP COLUMN declared_section_code',
            );
            sqlite.execute('PRAGMA user_version = 1');
          },
        ),
      );
      addTearDown(() async {
        await database.close();
        if (await file.exists()) await file.delete();
      });

      final migratedStudent = await database.studentDao.getCurrent();
      expect(migratedStudent?.sectionCode, 'GRADE12-STEM A');
      expect(migratedStudent?.classId, isEmpty);
      expect(await database.classDao.getClasses(), isEmpty);
      expect(await database.teacherDao.getTeacherOrNull(), isNull);
      expect(await database.select(database.enrollments).get(), isEmpty);
    },
  );
}

/// The actual concrete repository is the public Drift implementation; this
/// named subclass keeps the test constructor type readable.
class DriftAttendanceRepositoryForTest extends DriftAttendanceRepository {
  DriftAttendanceRepositoryForTest(super.db);
}
