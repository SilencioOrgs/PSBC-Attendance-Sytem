import 'dart:io';

import 'package:attendance_system_paete/core/providers/repository_providers.dart';
import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/domain/repositories.dart';
import 'package:attendance_system_paete/features/classes/data/drift_class_repository.dart';
import 'package:attendance_system_paete/features/device/data/drift_device_repository.dart';
import 'package:attendance_system_paete/features/device/presentation/providers/device_provider.dart';
import 'package:attendance_system_paete/features/student/data/drift_student_repository.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/mock_ble_service.dart';

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
      expect(replacement.bleUuid, isNot(original.bleUuid));
      expect(replacement.id, isNot(original.id));
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

  test(
    'student BLE identity survives database reopen and beacon restarts',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'classattend-stable-ble-',
      );
      final databaseFile = File(
        '${directory.path}${Platform.pathSeparator}attendance.sqlite',
      );
      var database = AppDatabase(NativeDatabase(databaseFile));
      addTearDown(() async {
        await database.close();
        if (await directory.exists()) await directory.delete(recursive: true);
      });

      final now = DateTime(2026, 9, 25, 8);
      await database.studentDao.insert(
        StudentsCompanion.insert(
          id: 'student-stable-ble',
          updatedAt: now,
          syncStatus: SyncStatus.synced,
          studentNumber: 'BLE-001',
          fullName: 'Asnor Sumdad',
        ),
      );

      final devices = DriftDeviceRepository(database);
      final registered = await devices.registerDevice(
        'student-stable-ble',
        'Student phone',
      );
      final uuidA = registered.bleUuid;
      expect(
        uuidA,
        matches(RegExp(r'^[0-9a-f]{8}(-[0-9a-f]{4}){3}-[0-9a-f]{12}$')),
      );

      await DriftStudentRepository(database).updateStudent(
        studentId: 'student-stable-ble',
        name: 'Asnor Sumdad Updated',
        studentNumber: 'BLE-001-UPDATED',
      );
      final retry = await devices.registerDevice(
        'student-stable-ble',
        'Another phone name',
        bleUuid: 'not-a-valid-replacement',
      );
      expect(retry.id, registered.id);
      expect(retry.bleUuid, uuidA);

      await database.close();
      for (var restart = 0; restart < 5; restart++) {
        database = AppDatabase(NativeDatabase(databaseFile));
        final repository = DriftDeviceRepository(database);
        final reloaded = await repository.getStudentDevice(
          'student-stable-ble',
        );
        expect(reloaded, isNotNull);
        expect(reloaded!.id, registered.id);
        expect(reloaded.bleUuid, uuidA);
        expect(
          (await repository.watchStudentDevice('student-stable-ble').first)
              ?.bleUuid,
          uuidA,
        );

        final ble = MockBleService();
        final container = ProviderContainer(
          overrides: [
            appDatabaseProvider.overrideWithValue(database),
            bleServiceProvider.overrideWithValue(ble),
          ],
        );
        try {
          final controller = container.read(
            deviceRegistrationControllerProvider.notifier,
          );
          await controller.startBeacon(reloaded.bleUuid);
          await controller.stopBeacon();
          await controller.startBeacon(reloaded.bleUuid);
          expect(ble.startAdvertisingCount, 2);
          expect(ble.advertisedServiceUuid, uuidA);
        } finally {
          container.dispose();
          await ble.dispose();
        }

        if (restart < 4) await database.close();
      }
    },
  );

  test(
    'invalid legacy device UUID is repaired once and then persists',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'classattend-repair-ble-',
      );
      final databaseFile = File(
        '${directory.path}${Platform.pathSeparator}attendance.sqlite',
      );
      var database = AppDatabase(NativeDatabase(databaseFile));
      addTearDown(() async {
        await database.close();
        if (await directory.exists()) await directory.delete(recursive: true);
      });

      final now = DateTime(2026, 9, 25, 8);
      await database.studentDao.insert(
        StudentsCompanion.insert(
          id: 'student-invalid-ble',
          updatedAt: now,
          syncStatus: SyncStatus.synced,
          studentNumber: 'BLE-002',
          fullName: 'Maria Santos',
        ),
      );
      await DriftDeviceRepository(database)
          .registerDevice('student-invalid-ble', 'Student phone');
      await (database.update(database.devices)
            ..where((row) => row.studentId.equals('student-invalid-ble')))
          .write(const DevicesCompanion(bleUuid: Value('')));

      final repaired = await DriftDeviceRepository(database)
          .getStudentDevice('student-invalid-ble');
      expect(repaired!.bleUuid, matches(RegExp(r'^[0-9a-f-]{36}$')));
      final uuidA = repaired.bleUuid;

      await database.close();
      database = AppDatabase(NativeDatabase(databaseFile));
      final reloaded = await DriftDeviceRepository(database)
          .getStudentDevice('student-invalid-ble');
      expect(reloaded!.bleUuid, uuidA);
    },
  );
}
