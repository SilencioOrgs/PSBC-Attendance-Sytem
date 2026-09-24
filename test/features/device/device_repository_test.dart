import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/domain/repositories.dart';
import 'package:attendance_system_paete/features/classes/data/drift_class_repository.dart';
import 'package:attendance_system_paete/features/device/data/drift_device_repository.dart';
import 'package:attendance_system_paete/features/student/data/drift_student_repository.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'registration validates and replacement atomically revokes old UUID',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final now = DateTime(2026, 9, 24, 8);
      await database.teacherDao.save(
        TeachersCompanion.insert(
          id: 'teacher-device-test',
          updatedAt: now,
          syncStatus: SyncStatus.synced,
          name: 'Ana Reyes',
        ),
      );
      final section = await DriftClassRepository(database).createClass(
        gradeLevel: 12,
        sectionLabel: 'STEM A',
        subject: 'Science',
        room: 'Room 1',
        scheduleStart: now,
        scheduleEnd: now.add(const Duration(hours: 1)),
      );
      final students = DriftStudentRepository(database);
      final first = await students.addStudentToClass(
        name: 'Maria Santos',
        studentNumber: 'D-001',
        classId: section.id,
      );
      final second = await students.addStudentToClass(
        name: 'Juan Cruz',
        studentNumber: 'D-002',
        classId: section.id,
      );
      final devices = DriftDeviceRepository(database);
      final original = await devices.registerDevice(first.id, 'Old phone');
      expect(original.bleUuid, matches(RegExp(r'^[0-9a-f-]{36}$')));
      expect(original.ownerStudentId, first.id);
      expect(original.registeredAt, isNotNull);

      await expectLater(
        devices.registerDevice(
          second.id,
          'Invalid code',
          bleUuid: 'not-a-uuid',
        ),
        throwsA(isA<InvalidBleUuidException>()),
      );

      const replacementUuid = '8f3f5d3e-54e2-4e15-9b2c-810859f38d33';
      final replacement = await devices.replaceDevice(
        first.id,
        'New phone',
        bleUuid: replacementUuid,
      );
      expect(replacement.bleUuid, replacementUuid);
      expect(replacement.ownerStudentId, first.id);
      expect((await devices.getDevices()).map((device) => device.bleUuid), [
        replacementUuid,
      ]);

      const otherUuid = '1165a4f2-0bc7-4cb5-9cb2-cf6e7f6d9f1e';
      await devices.registerDevice(
        second.id,
        'Second phone',
        bleUuid: otherUuid,
      );
      await expectLater(
        devices.replaceDevice(
          first.id,
          'Failed replacement',
          bleUuid: otherUuid,
        ),
        throwsA(isA<DuplicateBleUuidException>()),
      );
      expect(
        (await devices.getStudentDevice(first.id))?.bleUuid,
        replacementUuid,
      );
      expect((await devices.getStudentDevice(second.id))?.bleUuid, otherUuid);

      await devices.removeDevice(first.id);
      expect(await devices.getStudentDevice(first.id), isNull);
      expect(await devices.getStudentDevice(second.id), isNotNull);
    },
  );
}
