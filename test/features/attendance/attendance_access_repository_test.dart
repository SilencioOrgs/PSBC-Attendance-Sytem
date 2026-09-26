import 'dart:io';

import 'package:attendance_system_paete/domain/attendance_access_invitation.dart';
import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/domain/repositories.dart';
import 'package:attendance_system_paete/domain/subject_invitation.dart';
import 'package:attendance_system_paete/features/attendance/data/drift_attendance_access_repository.dart';
import 'package:attendance_system_paete/features/attendance/data/drift_attendance_repository.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grant import is separate from enrollment and duplicate safe', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final access = DriftAttendanceAccessRepository(database);
    final invitation = _invitation('offering-a');

    final first = await access.importInvitation(invitation);
    final duplicate = await access.importInvitation(invitation);

    expect(first.alreadyExists, isFalse);
    expect(duplicate.alreadyExists, isTrue);
    expect(await access.hasAnyAccess(), isTrue);
    expect(await database.select(database.enrollments).get(), isEmpty);
    expect(await access.getRoster(first.grant.localOfferingId), hasLength(2));
    expect(await access.getDevices(first.grant.localOfferingId), hasLength(1));
  });

  test(
    'grant persists, stays scoped, and supports offline attendance',
    () async {
      final file = File(
        '${Directory.systemTemp.path}${Platform.pathSeparator}'
        'classattend-access-${DateTime.now().microsecondsSinceEpoch}.sqlite',
      );
      var database = AppDatabase(NativeDatabase(file));
      var access = DriftAttendanceAccessRepository(database);
      final invitation = _invitation('offering-a');
      final imported = await access.importInvitation(invitation);
      final unrelated = _invitation('offering-b');
      final repository = DriftAttendanceRepository(
        database,
        canAccessOffering: (id) async =>
            await access.findForOffering(id) != null,
      );

      final session = await repository.startSession(
        imported.grant.localOfferingId,
        manualOverride: true,
      );
      expect(await repository.getRecords(session.id), hasLength(2));
      await expectLater(
        repository.startSession(unrelated.offering.id, manualOverride: true),
        throwsA(isA<AttendancePermissionDeniedException>()),
      );
      expect(await database.select(database.enrollments).get(), isEmpty);

      await database.close();
      database = AppDatabase(NativeDatabase(file));
      access = DriftAttendanceAccessRepository(database);
      addTearDown(() async {
        await database.close();
        if (await file.exists()) await file.delete();
      });
      final restored = await access.findForSourceOffering(
        invitation.teacherId,
        invitation.offering.id,
      );
      expect(restored, isNotNull);
      expect(await access.getRoster(restored!.localOfferingId), hasLength(2));
      expect(await database.select(database.enrollments).get(), isEmpty);
    },
  );
}

AttendanceAccessInvitation _invitation(String offeringId) =>
    AttendanceAccessInvitation(
      invitationId: 'capability-$offeringId',
      issuedAt: DateTime.utc(2026, 9, 26),
      teacherId: 'remote-teacher-1',
      teacherName: 'Ana Reyes',
      offering: SubjectInvitationOffering(
        id: offeringId,
        subject: 'Mathematics',
        sectionCode: 'GRADE12-STEM-${offeringId.toUpperCase()}',
        gradeLevel: 12,
        sectionLabel: 'STEM A',
        room: 'Room 1',
        scheduleDays: Weekday.values.toSet(),
        startMinutesOfDay: 0,
        endMinutesOfDay: 1439,
      ),
      roster: const [
        AttendanceAccessStudent(
          id: 'student-1',
          name: 'Maria Santos',
          studentNumber: 'S-001',
          bleUuid: 'de305d54-75b4-431b-adb2-eb6b9e546014',
        ),
        AttendanceAccessStudent(
          id: 'student-2',
          name: 'Juan Cruz',
          studentNumber: 'S-002',
        ),
      ],
    );
