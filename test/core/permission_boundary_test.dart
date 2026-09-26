import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/domain/subject_invitation.dart';
import 'package:attendance_system_paete/domain/repositories.dart';
import 'package:attendance_system_paete/features/classes/data/drift_class_repository.dart';
import 'package:attendance_system_paete/features/device/data/drift_device_repository.dart';
import 'package:attendance_system_paete/features/settings/data/drift_settings_repository.dart';
import 'package:attendance_system_paete/features/student/data/drift_enrollment_repository.dart';
import 'package:attendance_system_paete/features/student/data/drift_student_repository.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'unauthorized repository operations reject class and roster changes',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      Future<bool> denyClass(String? classId) async => false;
      Future<bool> denyRoster(String? classId, String? studentId) async =>
          false;

      await expectLater(
        DriftClassRepository(database, canManage: denyClass).createClass(
          gradeLevel: 12,
          sectionLabel: 'STEM A',
          subject: 'Mathematics',
          room: 'Room 1',
          scheduleStart: DateTime(2000, 1, 1, 8),
          scheduleEnd: DateTime(2000, 1, 1, 9),
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
      await expectLater(
        DriftStudentRepository(
          database,
          canManage: denyRoster,
        ).addStudentToClass(
          name: 'Test Student',
          studentNumber: 'S-001',
          classId: 'class-id',
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
      await expectLater(
        DriftStudentRepository(
          database,
          canManage: denyRoster,
        ).removeStudentFromClass(studentId: 'student-id', classId: 'class-id'),
        throwsA(isA<PermissionDeniedException>()),
      );
      await expectLater(
        DriftEnrollmentRepository(
          database,
          canEnroll: (_) async => false,
        ).addFromInvitation(
          studentId: 'student-id',
          invitation: const SubjectInvitation(
            teacherId: 'teacher-id',
            teacherName: 'Teacher',
            offerings: [],
          ),
          selectedOfferingIds: const {},
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    },
  );

  test(
    'unauthorized device and teacher-settings mutations are denied',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);

      await expectLater(
        DriftDeviceRepository(
          database,
          canManage: (_, {required ownerRegistration}) async => false,
        ).replaceDevice('student-id', 'Phone', bleUuid: 'invalid'),
        throwsA(isA<PermissionDeniedException>()),
      );
      await expectLater(
        DriftSettingsRepository(
          database,
          canManage: () async => false,
        ).saveSettings(
          AppSettings(
            id: 'settings',
            updatedAt: DateTime(2026),
            syncStatus: SyncStatus.synced,
            soundEnabled: true,
            vibrationEnabled: true,
            scanDurationSeconds: 15,
          ),
        ),
        throwsA(isA<PermissionDeniedException>()),
      );
    },
  );
}
