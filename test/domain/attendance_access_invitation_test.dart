import 'dart:convert';

import 'package:attendance_system_paete/domain/attendance_access_invitation.dart';
import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/domain/subject_invitation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final invitation = AttendanceAccessInvitation(
    invitationId: 'capability-1',
    issuedAt: DateTime.utc(2026, 9, 26),
    teacherId: 'teacher-1',
    teacherName: 'Ana Reyes',
    offering: const SubjectInvitationOffering(
      id: 'offering-1',
      subject: 'Mathematics',
      sectionCode: 'GRADE12-STEM A',
      gradeLevel: 12,
      sectionLabel: 'STEM A',
      room: 'Room 1',
      scheduleDays: {Weekday.monday, Weekday.wednesday},
      startMinutesOfDay: 480,
      endMinutesOfDay: 540,
    ),
    roster: [
      const AttendanceAccessStudent(
        id: 'student-1',
        name: 'Maria Santos',
        studentNumber: 'S-001',
        bleUuid: 'de305d54-75b4-431b-adb2-eb6b9e546014',
        deviceName: 'ClassAttend Companion',
      ),
    ],
  );

  test('attendance invitation validates role and class-specific roster', () {
    final decoded = AttendanceAccessInvitation.decode(invitation.encode());
    expect(decoded.role, 'attendance');
    expect(decoded.offering.id, 'offering-1');
    expect(decoded.offering.subject, 'Mathematics');
    expect(decoded.roster.single.studentNumber, 'S-001');
    expect(decoded.roster.single.bleUuid, isNotNull);
  });

  test('rejects malformed payloads, wrong roles, and unknown versions', () {
    expect(
      () => AttendanceAccessInvitation.decode('not json'),
      throwsFormatException,
    );
    final wrongRole = jsonDecode(invitation.encode()) as Map<String, Object?>
      ..['role'] = 'teacher';
    expect(
      () => AttendanceAccessInvitation.decode(jsonEncode(wrongRole)),
      throwsFormatException,
    );
    final unknownVersion =
        jsonDecode(invitation.encode()) as Map<String, Object?>
          ..['version'] = 3;
    expect(
      () => AttendanceAccessInvitation.decode(jsonEncode(unknownVersion)),
      throwsFormatException,
    );
  });

  test('QR frames transfer a roster and reject missing or mismatched frames', () {
    final largeInvitation = AttendanceAccessInvitation(
      invitationId: invitation.invitationId,
      issuedAt: invitation.issuedAt,
      teacherId: invitation.teacherId,
      teacherName: invitation.teacherName,
      offering: invitation.offering,
      roster: List.generate(
        100,
        (index) => AttendanceAccessStudent(
          id: 'student-$index-7d82a0aa-0311-4f4e-a4f4-9c4b7d',
          name: 'Student Name $index',
          studentNumber: 'S-${index.toString().padLeft(4, '0')}',
          bleUuid:
              'de305d54-75b4-431b-adb2-eb6b9e54${index.toString().padLeft(4, '0')}',
        ),
      ),
    );
    final frames = AttendanceAccessQrFrame.createFrames(largeInvitation);
    expect(frames.length, greaterThan(1));
    final decoded = AttendanceAccessQrFrame.decodeFrames(
      frames.reversed.toList(),
    );
    expect(decoded.invitationId, invitation.invitationId);
    expect(decoded.roster, hasLength(100));
    expect(
      () => AttendanceAccessQrFrame.decodeFrames(frames.take(1).toList()),
      throwsFormatException,
    );
  });
}
