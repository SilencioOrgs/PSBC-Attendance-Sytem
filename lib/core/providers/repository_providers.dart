import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/attendance/data/drift_attendance_repository.dart';
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

final teacherPinServiceProvider = Provider<TeacherPinService>(
  (ref) => SecureTeacherPinService(const FlutterSecureStorage()),
);

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
  (ref) => DriftClassRepository(ref.watch(appDatabaseProvider)),
);

final studentRepositoryProvider = Provider<StudentRepository>(
  (ref) => DriftStudentRepository(ref.watch(appDatabaseProvider)),
);

final enrollmentRepositoryProvider = Provider<EnrollmentRepository>(
  (ref) => DriftEnrollmentRepository(ref.watch(appDatabaseProvider)),
);

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => DriftAttendanceRepository(ref.watch(appDatabaseProvider)),
);

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DriftDeviceRepository(ref.watch(appDatabaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(ref.watch(appDatabaseProvider)),
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
