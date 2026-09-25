import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/auth/teacher_session.dart';
import 'core/auth/application_session.dart';
import 'core/providers/repository_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'services/ble/production_ble_service.dart';
import 'services/auth/teacher_pin_service.dart';
import 'services/storage/app_database.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = AppDatabase();
  const secureStorage = FlutterSecureStorage();
  final pinService = SecureTeacherPinService(secureStorage);
  final teacherSession = TeacherSession();
  await teacherSession.initialize(pinService);
  final applicationSession = ApplicationSession(
    database: database,
    teacherSession: teacherSession,
  );
  await applicationSession.initialize(
    teacherPinExists: await pinService.hasPin(),
  );
  final router = createAppRouter(
    session: teacherSession,
    applicationSession: applicationSession,
  );
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        teacherPinServiceProvider.overrideWithValue(pinService),
        teacherSessionProvider.overrideWithValue(teacherSession),
        applicationSessionProvider.overrideWithValue(applicationSession),
        bleServiceProvider.overrideWithValue(ProductionBleService()),
      ],
      child: MyApp(router: router),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.router});

  final RouterConfig<Object>? router;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'ClassAttend',
    theme: AppTheme.light,
    routerConfig: router ?? createAppRouter(),
  );
}
