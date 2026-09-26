import 'package:attendance_system_paete/core/auth/application_session.dart';
import 'package:attendance_system_paete/core/auth/teacher_session.dart';
import 'package:attendance_system_paete/core/providers/repository_providers.dart';
import 'package:attendance_system_paete/domain/attendance_access_invitation.dart';
import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/domain/subject_invitation.dart';
import 'package:attendance_system_paete/features/attendance/data/drift_attendance_access_repository.dart';
import 'package:attendance_system_paete/features/attendance/data/drift_attendance_repository.dart';
import 'package:attendance_system_paete/features/attendance/presentation/providers/attendance_controller.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/mock_ble_service.dart';

void main() {
  test('officer scans the transferred roster and BLE UUIDs offline', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final teacher = TeacherSession();
    final application = ApplicationSession(
      database: database,
      teacherSession: teacher,
    );
    final access = DriftAttendanceAccessRepository(database);
    final invitation = AttendanceAccessInvitation(
      invitationId: 'capability-offline',
      issuedAt: DateTime.utc(2026, 9, 26),
      teacherId: 'remote-teacher',
      teacherName: 'Ana Reyes',
      offering: const SubjectInvitationOffering(
        id: 'offering-offline',
        subject: 'Mathematics',
        sectionCode: 'GRADE12-STEM A',
        gradeLevel: 12,
        sectionLabel: 'STEM A',
        room: 'Room 1',
        scheduleDays: {Weekday.monday},
        startMinutesOfDay: 480,
        endMinutesOfDay: 540,
      ),
      roster: const [
        AttendanceAccessStudent(
          id: 'source-student-1',
          name: 'Maria Santos',
          studentNumber: 'S-001',
          bleUuid: 'de305d54-75b4-431b-adb2-eb6b9e546014',
          deviceName: 'ClassAttend phone',
        ),
      ],
    );
    final grant = await access.importInvitation(invitation);
    await application.selectAttendanceOfficer();
    final ble = MockBleService();
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        teacherSessionProvider.overrideWithValue(teacher),
        applicationSessionProvider.overrideWithValue(application),
        attendanceAccessRepositoryProvider.overrideWithValue(access),
        attendanceRepositoryProvider.overrideWithValue(
          DriftAttendanceRepository(
            database,
            canAccessOffering: (offeringId) async =>
                application.entry == ApplicationEntry.attendanceOfficer &&
                await access.findForOffering(offeringId) != null,
          ),
        ),
        bleServiceProvider.overrideWithValue(ble),
      ],
    );
    addTearDown(() async {
      container.dispose();
      application.dispose();
      teacher.dispose();
      await ble.dispose();
      await database.close();
    });

    final attendance = container.read(attendanceRepositoryProvider);
    final session = await container
        .read(attendanceControllerProvider.notifier)
        .prepareSession(grant.grant.localOfferingId, manualOverride: true);
    await container
        .read(attendanceControllerProvider.notifier)
        .start(session.id);

    expect(ble.lastRoster.single.name, 'Maria Santos');
    expect(ble.lastRoster.single.deviceRegistered, isTrue);
    expect(
      ble.lastRegisteredDevices.single.bleUuid,
      invitation.roster.single.bleUuid,
    );
    expect(
      ble.lastRegisteredDevices.single.ownerStudentId,
      ble.lastRoster.single.id,
    );
    expect(await attendance.getRecords(session.id), hasLength(1));
    expect(await database.select(database.enrollments).get(), isEmpty);
    await container.read(attendanceControllerProvider.notifier).stopForReview();
    await container
        .read(attendanceControllerProvider.notifier)
        .finalize(session.id);
    expect(
      (await attendance.getSession(session.id))?.status,
      AttendanceSessionStatus.completed,
    );
  });
}
