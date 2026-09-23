import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/attendance/data/drift_attendance_repository.dart';
import '../../features/classes/data/drift_class_repository.dart';
import '../../features/device/data/drift_device_repository.dart';
import '../../features/settings/data/drift_settings_repository.dart';
import '../../features/student/data/drift_student_repository.dart';
import '../../features/teacher/data/drift_teacher_repository.dart';
import '../../domain/repositories.dart';
import '../../services/auth/teacher_pin_service.dart';
import '../../services/ble/ble_service.dart';
import '../../services/storage/app_database.dart';
import '../../services/storage/demo_data_loader.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final teacherPinServiceProvider = Provider<TeacherPinService>(
  (ref) => SecureTeacherPinService(const FlutterSecureStorage()),
);

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

final attendanceRepositoryProvider = Provider<AttendanceRepository>(
  (ref) => DriftAttendanceRepository(ref.watch(appDatabaseProvider)),
);

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => DriftDeviceRepository(ref.watch(appDatabaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => DriftSettingsRepository(ref.watch(appDatabaseProvider)),
);

final demoDataLoaderProvider = Provider<DemoDataLoader>(
  (ref) => throw StateError('Demo data is available only in debug builds.'),
);

final bleServiceProvider = Provider<BleService>(
  (ref) => throw UnimplementedError('BleService was not configured.'),
);
