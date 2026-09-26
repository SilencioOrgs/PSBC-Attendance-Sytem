import 'dart:io';

import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'v6 to v7 adds automatic report defaults and run history tables',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'classattend-v7-migration-',
      );
      final file = File(
        '${directory.path}${Platform.pathSeparator}classattend.sqlite',
      );
      var database = AppDatabase(NativeDatabase(file));
      final updatedAt = DateTime(2026, 9, 25, 9);
      await database.settingsDao.save(
        AppSettingsRowsCompanion.insert(
          id: 'settings-singleton',
          updatedAt: updatedAt,
          syncStatus: SyncStatus.synced,
          scanDurationSeconds: 12,
          rssiThreshold: -70,
          soundEnabled: true,
          vibrationEnabled: false,
        ),
      );
      await database.close();

      database = AppDatabase(
        NativeDatabase(
          file,
          setup: (sqlite) {
            sqlite.execute('DROP TABLE auto_report_executions');
            sqlite.execute('DROP TABLE auto_report_runs');
            sqlite.execute(
              'ALTER TABLE app_settings DROP COLUMN automatic_report_mode',
            );
            sqlite.execute(
              'ALTER TABLE app_settings DROP COLUMN automatic_report_hour',
            );
            sqlite.execute(
              'ALTER TABLE app_settings DROP COLUMN automatic_report_minute',
            );
            sqlite.execute(
              'ALTER TABLE app_settings DROP COLUMN automatic_report_weekday',
            );
            sqlite.execute('PRAGMA user_version = 6');
          },
        ),
      );
      addTearDown(() async {
        await database.close();
        if (await directory.exists()) await directory.delete(recursive: true);
      });

      final restored = await database.settingsDao.getSettings();
      expect(database.schemaVersion, 7);
      expect(restored?.soundEnabled, isTrue);
      expect(restored?.vibrationEnabled, isFalse);
      expect(restored?.automaticReportMode, AutomaticReportMode.off);
      expect(restored?.automaticReportHour, 17);
      expect(restored?.automaticReportMinute, 0);
      expect(restored?.automaticReportWeekday, Weekday.friday);
      expect(await database.autoReportDao.getLatestRun(), isNull);
    },
  );
}
