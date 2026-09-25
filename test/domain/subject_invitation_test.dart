import 'dart:convert';

import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/domain/subject_invitation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final invitation = SubjectInvitation(
    teacherId: 'teacher-1',
    teacherName: 'Ana Reyes',
    offerings: [
      SubjectInvitationOffering(
        id: 'offering-1',
        subject: 'CPE1',
        sectionCode: 'GRADE12-STEM A',
        gradeLevel: 12,
        sectionLabel: 'STEM A',
        room: '301',
        scheduleDays: {Weekday.monday},
        startMinutesOfDay: 570,
        endMinutesOfDay: 630,
      ),
    ],
  );

  test(
    'versioned invitation encodes and decodes its required subject data',
    () {
      final restored = SubjectInvitation.decode(invitation.encode());
      expect(restored.teacherName, 'Ana Reyes');
      expect(restored.offerings.single.id, 'offering-1');
      expect(restored.offerings.single.scheduleDays, {Weekday.monday});
    },
  );

  test(
    'rejects malformed, unknown-version, duplicate, and invalid schedules',
    () {
      expect(() => SubjectInvitation.decode('not json'), throwsFormatException);
      expect(
        () => SubjectInvitation.decode(
          jsonEncode({'type': SubjectInvitation.type, 'version': 2}),
        ),
        throwsFormatException,
      );
      final duplicate = jsonDecode(invitation.encode()) as Map<String, dynamic>;
      duplicate['offerings'] = [
        duplicate['offerings'][0],
        duplicate['offerings'][0],
      ];
      expect(
        () => SubjectInvitation.decode(jsonEncode(duplicate)),
        throwsFormatException,
      );
      final invalidSchedule =
          jsonDecode(invitation.encode()) as Map<String, dynamic>;
      invalidSchedule['offerings'][0]['endMinutesOfDay'] = 500;
      expect(
        () => SubjectInvitation.decode(jsonEncode(invalidSchedule)),
        throwsFormatException,
      );
    },
  );
}
