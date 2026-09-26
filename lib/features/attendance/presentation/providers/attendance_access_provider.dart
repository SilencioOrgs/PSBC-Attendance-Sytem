import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/auth/application_session.dart';
import '../../../../core/auth/teacher_session.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/attendance_access_invitation.dart';
import '../../../../domain/models.dart';
import '../../../../domain/repositories.dart';
import '../../../../domain/subject_invitation.dart';

final attendanceAccessGrantsProvider =
    StreamProvider<List<AttendanceAccessGrant>>(
      (ref) => ref.watch(attendanceAccessRepositoryProvider).watchGrants(),
    );

final attendanceAccessAvailableProvider = FutureProvider<bool>(
  (ref) => ref.watch(attendanceAccessRepositoryProvider).hasAnyAccess(),
);

final attendanceAccessQrControllerProvider =
    NotifierProvider<AttendanceAccessQrController, bool>(
      AttendanceAccessQrController.new,
    );

class AttendanceAccessQrController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<List<AttendanceAccessQrFrame>> create(String offeringId) async {
    final session = ref.read(applicationSessionProvider);
    if (session.entry != ApplicationEntry.teacher ||
        ref.read(teacherSessionProvider).state !=
            TeacherSessionState.authenticated) {
      throw const AttendancePermissionDeniedException();
    }
    state = true;
    try {
      final offering = await ref
          .read(classRepositoryProvider)
          .getClass(offeringId);
      final teacher = await ref.read(teacherRepositoryProvider).getTeacher();
      if (offering == null || offering.teacherId != teacher.id) {
        throw const ClassSectionNotFoundException();
      }
      final roster = await ref
          .read(classRepositoryProvider)
          .getStudents(offeringId);
      if (roster.isEmpty) throw const EmptyClassRosterException();
      final devices = await ref.read(deviceRepositoryProvider).getDevices();
      final deviceByStudent = {
        for (final device in devices)
          if (device.ownerStudentId != null) device.ownerStudentId!: device,
      };
      final invitation = AttendanceAccessInvitation(
        invitationId: const Uuid().v4(),
        issuedAt: DateTime.now().toUtc(),
        teacherId: teacher.id,
        teacherName: teacher.name,
        offering: SubjectInvitationOffering(
          id: offering.id,
          subject: offering.subject,
          sectionCode: offering.sectionCode,
          gradeLevel: offering.gradeLevel,
          sectionLabel: offering.sectionLabel,
          room: offering.room,
          scheduleDays: offering.scheduleDays,
          startMinutesOfDay:
              offering.startMinutesOfDay ??
              offering.scheduleStart!.hour * 60 +
                  offering.scheduleStart!.minute,
          endMinutesOfDay:
              offering.endMinutesOfDay ??
              offering.scheduleEnd!.hour * 60 + offering.scheduleEnd!.minute,
        ),
        roster: roster
            .map((student) {
              final device = deviceByStudent[student.id];
              return AttendanceAccessStudent(
                id: student.id,
                name: student.name,
                studentNumber: student.studentNumber,
                bleUuid: device?.bleUuid,
                deviceName: device?.name,
              );
            })
            .toList(growable: false),
      );
      return AttendanceAccessQrFrame.createFrames(invitation);
    } finally {
      state = false;
    }
  }
}
