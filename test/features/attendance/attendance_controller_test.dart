import 'package:attendance_system_paete/core/providers/repository_providers.dart';
import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/features/attendance/presentation/providers/attendance_controller.dart';
import 'package:attendance_system_paete/features/classes/data/drift_class_repository.dart';
import 'package:attendance_system_paete/features/device/data/drift_device_repository.dart';
import 'package:attendance_system_paete/features/student/data/drift_student_repository.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_ble_service.dart';

void main() {
  test(
    'scan, review, manual overrides, and finalization preserve each status',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final ble = MockBleService();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          bleServiceProvider.overrideWithValue(ble),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await ble.dispose();
        await database.close();
      });

      final now = DateTime(2026, 9, 24, 8);
      await database.teacherDao.save(
        TeachersCompanion.insert(
          id: 'teacher-1',
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
      final roster = [
        for (var index = 0; index < 4; index++)
          await students.addStudentToClass(
            name: 'Student $index',
            studentNumber: 'T-00$index',
            classId: section.id,
          ),
      ];
      final registeredDevice = await DriftDeviceRepository(database)
          .registerDevice(
            roster.first.id,
            'Student phone',
            bleUuid: '8f3f5d3e-54e2-4e15-9b2c-810859f38d33',
          );

      final controller = container.read(attendanceControllerProvider.notifier);
      final session = await controller.prepareSession(section.id);
      await controller.start(session.id);
      expect(
        container.read(attendanceControllerProvider).state,
        AttendanceWorkflowState.scanning,
      );

      ble.emit(
        BleScanUpdate(
          progress: 0.5,
          discoveredDevices: [
            Device(
              id: registeredDevice.id,
              updatedAt: now,
              syncStatus: SyncStatus.synced,
              name: 'Student phone',
              bleUuid: registeredDevice.bleUuid,
              ownerStudentId: roster.first.id,
              rssi: -48,
            ),
          ],
          isComplete: false,
          unknownDeviceCount: 2,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(
        container
            .read(attendanceControllerProvider)
            .discoveredDevices
            .single
            .rssi,
        -48,
      );
      await controller.stopForReview();
      expect(
        container.read(attendanceControllerProvider).state,
        AttendanceWorkflowState.review,
      );

      final attendance = container.read(attendanceRepositoryProvider);
      await attendance.toggleStatus(session.id, roster[1].id);
      await attendance.toggleStatus(session.id, roster[2].id);
      await attendance.toggleStatus(session.id, roster[2].id);
      await controller.finalize(session.id);

      final records = {
        for (final record in await attendance.getRecords(session.id))
          record.studentId: record,
      };
      expect(
        records[roster[0].id]?.recordStatus,
        AttendanceRecordStatus.present,
      );
      expect(records[roster[0].id]?.rssi, -48);
      expect(
        records[roster[1].id]?.recordStatus,
        AttendanceRecordStatus.manualPresent,
      );
      expect(
        records[roster[2].id]?.recordStatus,
        AttendanceRecordStatus.manualAbsent,
      );
      expect(
        records[roster[3].id]?.recordStatus,
        AttendanceRecordStatus.absent,
      );
      expect(
        (await attendance.getSession(session.id))?.status,
        AttendanceSessionStatus.completed,
      );
      expect(
        container.read(attendanceControllerProvider).state,
        AttendanceWorkflowState.completed,
      );
    },
  );
}
