import 'dart:async';

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
import 'package:attendance_system_paete/mock/drift_demo_data_loader.dart';
import 'package:attendance_system_paete/services/auth/teacher_pin_service.dart';
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
      bleUuid: 'ble-shared',
    );
    await expectLater(
      devices.registerDevice(secondStudent.id, 'Band', bleUuid: 'ble-shared'),
      throwsA(isA<DuplicateBleUuidException>()),
    );
  });

  test('debug loader inserts repeatable fixture data through Drift', () async {
    final demoDatabase = AppDatabase(NativeDatabase.memory());
    addTearDown(demoDatabase.close);
    final pinService = _MemoryPinService();
    final loader = DriftDemoDataLoader(demoDatabase, pinService);
    await loader.load();
    await loader.load();

    final classes = await demoDatabase.classDao.getClasses();
    expect(classes, hasLength(3));
    final stemA = classes.singleWhere(
      (section) => section.sectionCode == 'GRADE12-STEM A',
    );
    expect(await demoDatabase.classDao.getStudents(stemA.id), hasLength(35));
    expect(await demoDatabase.attendanceDao.getSessions(), hasLength(3));
    expect(await demoDatabase.deviceDao.getAll(), hasLength(32));
    expect(await demoDatabase.settingsDao.getSettings(), isNotNull);
    expect(pinService.pin, '2468');
  });
}

/// The actual concrete repository is the public Drift implementation; this
/// named subclass keeps the test constructor type readable.
class DriftAttendanceRepositoryForTest extends DriftAttendanceRepository {
  DriftAttendanceRepositoryForTest(super.db);
}

class _MemoryPinService implements TeacherPinService {
  String? pin;
  @override
  Future<bool> hasPin() async => pin != null;
  @override
  Future<void> savePin(String pin) async {
    this.pin = pin;
  }

  @override
  Future<bool> verifyPin(String pin) async => this.pin == pin;
}
