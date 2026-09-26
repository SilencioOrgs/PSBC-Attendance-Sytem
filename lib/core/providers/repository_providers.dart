import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/attendance/data/drift_attendance_repository.dart';
import '../../features/attendance/data/drift_attendance_access_repository.dart';
import '../../features/classes/data/drift_class_repository.dart';
import '../../features/device/data/drift_device_repository.dart';
import '../../features/settings/data/drift_settings_repository.dart';
import '../../features/student/data/drift_student_repository.dart';
import '../../features/student/data/drift_enrollment_repository.dart';
import '../../features/teacher/data/drift_teacher_repository.dart';
import '../../domain/models.dart';
import '../../domain/repositories.dart';
import '../../core/auth/teacher_session.dart';
import '../../core/auth/application_session.dart';
import '../../features/authentication/application/teacher_auth_service.dart';
import '../../services/auth/teacher_pin_service.dart';
import '../../services/ble/ble_service.dart';
import '../../services/ble/background_attendance_service.dart';
import '../../services/storage/app_database.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final teacherPinServiceProvider = Provider<TeacherPinService>((ref) {
  final pins = SecureTeacherPinService(const FlutterSecureStorage());
  return RoleGuardedTeacherPinService(
    pins,
    canManage: () =>
        ref.read(applicationSessionProvider).entry ==
            ApplicationEntry.teacherSetup ||
        ref.read(applicationSessionProvider).entry == ApplicationEntry.teacher,
    canVerify: () =>
        ref.read(applicationSessionProvider).entry ==
            ApplicationEntry.teacherLocked ||
        ref.read(applicationSessionProvider).entry == ApplicationEntry.teacher,
  );
});

final teacherSessionProvider = Provider<TeacherSession>(
  (ref) => TeacherSession(state: TeacherSessionState.setupRequired),
);

final applicationSessionProvider = Provider<ApplicationSession>((ref) {
  final session = ApplicationSession(
    database: ref.watch(appDatabaseProvider),
    teacherSession: ref.watch(teacherSessionProvider),
  );
  ref.onDispose(session.dispose);
  return session;
});

/// The app entry point overrides these contracts with the selected data sources.
final teacherRepositoryProvider = Provider<TeacherRepository>(
  (ref) => DriftTeacherRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(teacherPinServiceProvider),
  ),
);

final classRepositoryProvider = Provider<ClassRepository>(
  (ref) => DriftClassRepository(
    ref.watch(appDatabaseProvider),
    canManage: (classId) async {
      if (ref.read(applicationSessionProvider).entry !=
              ApplicationEntry.teacher ||
          ref.read(teacherSessionProvider).state !=
              TeacherSessionState.authenticated) {
        return false;
      }
      final teacher = await ref
          .read(appDatabaseProvider)
          .teacherDao
          .getTeacherOrNull();
      if (teacher == null) return false;
      if (classId == null) return true;
      return (await ref.read(appDatabaseProvider).classDao.getClass(classId))
              ?.teacherId ==
          teacher.id;
    },
  ),
);

final studentRepositoryProvider = Provider<StudentRepository>(
  (ref) => DriftStudentRepository(
    ref.watch(appDatabaseProvider),
    canRegisterProfile: () async {
      final entry = ref.read(applicationSessionProvider).entry;
      return entry == ApplicationEntry.welcome ||
          entry == ApplicationEntry.student ||
          entry == ApplicationEntry.teacherSetup;
    },
    canManage: (classId, studentId) async {
      if (ref.read(applicationSessionProvider).entry !=
              ApplicationEntry.teacher ||
          ref.read(teacherSessionProvider).state !=
              TeacherSessionState.authenticated) {
        return false;
      }
      final teacher = await ref
          .read(appDatabaseProvider)
          .teacherDao
          .getTeacherOrNull();
      if (teacher == null) return false;
      if (classId != null &&
          (await ref.read(appDatabaseProvider).classDao.getClass(classId))
                  ?.teacherId !=
              teacher.id) {
        return false;
      }
      if (studentId != null) {
        final offerings = await ref
            .read(appDatabaseProvider)
            .classDao
            .getStudentOfferings(studentId);
        if (!offerings.any((offering) => offering.teacherId == teacher.id)) {
          return false;
        }
      }
      return true;
    },
  ),
);

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>(
  (ref) => DriftEnrollmentRepository(
    ref.watch(appDatabaseProvider),
    canEnroll: (studentId) async {
      final session = ref.read(applicationSessionProvider);
      return session.entry == ApplicationEntry.student &&
          session.currentStudentId == studentId;
    },
  ),
);

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => DriftAttendanceRepository(
    ref.watch(appDatabaseProvider),
    canAccessOffering: (offeringId) async {
      final session = ref.read(applicationSessionProvider);
      final entry = session.entry;
      if (entry == ApplicationEntry.teacher &&
          ref.read(teacherSessionProvider).state ==
              TeacherSessionState.authenticated) {
        final offering = await ref
            .read(classRepositoryProvider)
            .getClass(offeringId);
        return offering != null &&
            (await ref.read(appDatabaseProvider).teacherDao.getTeacherOrNull())
                    ?.id ==
                offering.teacherId;
      }
      if (entry == ApplicationEntry.attendanceOfficer) {
        return await ref
                .read(attendanceAccessRepositoryProvider)
                .findForOffering(offeringId) !=
            null;
      }
      return false;
    },
  ),
);

final attendanceAccessRepositoryProvider = Provider<AttendanceAccessRepository>(
  (ref) => DriftAttendanceAccessRepository(ref.watch(appDatabaseProvider)),
);

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return DriftDeviceRepository(
    database,
    canManage: (studentId, {required ownerRegistration}) async {
      final session = ref.read(applicationSessionProvider);
      if (session.entry == ApplicationEntry.student &&
          ownerRegistration &&
          session.currentStudentId == studentId) {
        return true;
      }
      if (session.entry != ApplicationEntry.teacher ||
          ref.read(teacherSessionProvider).state !=
              TeacherSessionState.authenticated) {
        return false;
      }
      final teacher = await database.teacherDao.getTeacherOrNull();
      final offerings = await database.classDao.getStudentOfferings(studentId);
      return teacher != null &&
          offerings.any((offering) => offering.teacherId == teacher.id);
    },
  );
});

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(
    ref.watch(appDatabaseProvider),
    canManage: () async =>
        ref.read(applicationSessionProvider).entry ==
            ApplicationEntry.teacher &&
        ref.read(teacherSessionProvider).state ==
            TeacherSessionState.authenticated,
  ),
);

final teacherAuthServiceProvider = Provider<TeacherAuthService>(
  (ref) => TeacherAuthService(
    ref.watch(teacherSessionProvider),
    ref.watch(teacherRepositoryProvider),
    ref.watch(teacherPinServiceProvider),
    ref.watch(bleServiceProvider),
    ref.watch(attendanceRepositoryProvider),
    applicationSession: ref.watch(applicationSessionProvider),
  ),
);

final bleServiceProvider = Provider<BleService>(
  (ref) => throw UnimplementedError('BleService was not configured.'),
);

final backgroundAttendanceServiceProvider =
    Provider<BackgroundAttendanceService>(
      (ref) => BackgroundAttendanceService(),
    );

final bleAdapterStateProvider = StreamProvider<BleAvailability>(
  (ref) => ref.watch(bleServiceProvider).watchAdapterState(),
);
