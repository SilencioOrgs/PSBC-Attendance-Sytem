import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/providers/repository_providers.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'mock/drift_demo_data_loader.dart';
import 'mock/mock_ble_service.dart';
import 'services/auth/teacher_pin_service.dart';
import 'services/storage/app_database.dart';

void main() {
  final router = createAppRouter();
  final database = AppDatabase();
  const secureStorage = FlutterSecureStorage();
  final pinService = SecureTeacherPinService(secureStorage);
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        teacherPinServiceProvider.overrideWithValue(pinService),
        bleServiceProvider.overrideWithValue(MockBleService()),
        if (kDebugMode)
          demoDataLoaderProvider.overrideWithValue(
            DriftDemoDataLoader(database, pinService),
          ),
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
