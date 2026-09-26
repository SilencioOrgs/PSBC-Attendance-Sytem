import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../domain/models.dart';
import '../../../../services/reports/auto_attendance_report_runner.dart';
import '../../../../services/reports/automatic_report_scheduler.dart';

final appSettingsProvider = StreamProvider<AppSettings>(
  (ref) => ref.watch(settingsRepositoryProvider).watchSettings(),
);

final latestAutomaticReportRunProvider = StreamProvider<AutoReportRun?>(
  (ref) => ref.watch(appDatabaseProvider).autoReportDao.watchLatestRun(),
);

final automaticReportSchedulerProvider = Provider<AutomaticReportScheduler>(
  (ref) => AutomaticReportScheduler(),
);

final settingsControllerProvider = NotifierProvider<SettingsController, bool>(
  SettingsController.new,
);

class SettingsController extends Notifier<bool> {
  @override
  bool build() => false;

  Future<void> save(AppSettings settings) async {
    state = true;
    try {
      final repository = ref.read(settingsRepositoryProvider);
      final previous = await repository.getSettings();
      await repository.saveSettings(settings);
      if (previous.automaticReportMode == AutomaticReportMode.off &&
          settings.automaticReportMode != AutomaticReportMode.off) {
        await requestAutomaticReportNotificationPermission();
      }
      await ref.read(automaticReportSchedulerProvider).sync(settings);
      ref.invalidate(appSettingsProvider);
    } finally {
      state = false;
    }
  }

  Future<bool> retryFailedAutomaticReport() async {
    state = true;
    try {
      final database = ref.read(appDatabaseProvider);
      final run = await database.autoReportDao.getLatestFailedRun();
      if (run == null) return false;
      final succeeded = await AutoAttendanceReportRunner(database)
          .run(mode: run.mode, occurrenceAt: run.occurrenceAt);
      if (succeeded) {
        await ref
            .read(automaticReportSchedulerProvider)
            .scheduleNextFromSettings(database);
      }
      return succeeded;
    } finally {
      state = false;
    }
  }

  Future<void> changePin({
    required String currentPin,
    required String newPin,
  }) async {
    state = true;
    try {
      await ref
          .read(teacherAuthServiceProvider)
          .changePin(currentPin: currentPin, newPin: newPin);
    } finally {
      state = false;
    }
  }

  Future<void> logout() async {
    state = true;
    try {
      await ref.read(teacherAuthServiceProvider).logout();
    } finally {
      state = false;
    }
  }
}
