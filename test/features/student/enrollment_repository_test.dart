import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/domain/subject_invitation.dart';
import 'package:attendance_system_paete/features/student/data/drift_enrollment_repository.dart';
import 'package:attendance_system_paete/features/student/data/drift_student_repository.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'confirmed QR selections persist as multiple idempotent enrollments',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final student = await DriftStudentRepository(database)
          .registerStudent(name: 'Asnor Sumdad', studentNumber: 'S-001');
      const invitation = SubjectInvitation(
        teacherId: 'teacher-inviter',
        teacherName: 'Ana Reyes',
        offerings: [
          SubjectInvitationOffering(
            id: 'offering-cpe1',
            subject: 'CPE1',
            sectionCode: 'GRADE12-STEM A',
            gradeLevel: 12,
            sectionLabel: 'STEM A',
            room: '301',
            scheduleDays: {Weekday.monday},
            startMinutesOfDay: 570,
            endMinutesOfDay: 630,
          ),
          SubjectInvitationOffering(
            id: 'offering-database',
            subject: 'Database Systems',
            sectionCode: 'GRADE12-STEM A',
            gradeLevel: 12,
            sectionLabel: 'STEM A',
            room: '302',
            scheduleDays: {Weekday.tuesday},
            startMinutesOfDay: 780,
            endMinutesOfDay: 840,
          ),
        ],
      );
      final repository = DriftEnrollmentRepository(database);
      final ids = invitation.offerings.map((item) => item.id).toSet();
      expect(
        await repository.addFromInvitation(
          studentId: student.id,
          invitation: invitation,
          selectedOfferingIds: ids,
        ),
        2,
      );
      expect(
        await repository.addFromInvitation(
          studentId: student.id,
          invitation: invitation,
          selectedOfferingIds: ids,
        ),
        0,
      );
      final enrollments = await DriftStudentRepository(database)
          .getStudent(student.id);
      expect(enrollments?.id, student.id);
      final classes = await database.classDao.getStudentOfferings(student.id);
      expect(classes.map((item) => item.subject), ['CPE1', 'Database Systems']);
      expect((await database.teacherDao.getTeacherOrNull()), isNull);
      expect(await database.select(database.enrollments).get(), hasLength(2));
      expect(
        (await database.select(database.teachers).getSingle()).isLocal,
        isFalse,
      );
    },
  );

  test(
    'QR repository rejects IDs that are not in the scanned invitation',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final student = await DriftStudentRepository(database)
          .registerStudent(name: 'Asnor Sumdad', studentNumber: 'S-002');
      const invitation = SubjectInvitation(
        teacherId: 'teacher-inviter',
        teacherName: 'Ana Reyes',
        offerings: [
          SubjectInvitationOffering(
            id: 'offering-cpe1',
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
      await expectLater(
        DriftEnrollmentRepository(database).addFromInvitation(
          studentId: student.id,
          invitation: invitation,
          selectedOfferingIds: {'forged-offering-id'},
        ),
        throwsA(isA<FormatException>()),
      );
      expect(await database.select(database.enrollments).get(), isEmpty);
    },
  );
}
