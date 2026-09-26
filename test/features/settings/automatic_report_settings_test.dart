import 'package:attendance_system_paete/domain/models.dart';
import 'package:attendance_system_paete/features/settings/data/drift_settings_repository.dart';
import 'package:attendance_system_paete/services/storage/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('automatic report settings persist across repository reads', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = DriftSettingsRepository(
      database,
      canManage: () async => true,
    );

    final fallback = await repository.getSettings();
    expect(fallback.automaticReportMode, AutomaticReportMode.off);

    final settings = AppSettings(
      id: fallback.id,
      updatedAt: DateTime(2026, 9, 25, 10),
      syncStatus: SyncStatus.pendingUpdate,
      soundEnabled: fallback.soundEnabled,
      vibrationEnabled: fallback.vibrationEnabled,
      scanDurationSeconds: fallback.scanDurationSeconds,
      rssiThreshold: fallback.rssiThreshold,
      automaticReportMode: AutomaticReportMode.weekly,
      automaticReportHour: 19,
      automaticReportMinute: 45,
      automaticReportWeekday: Weekday.wednesday,
    );

    await repository.saveSettings(settings);
    final restored = await repository.getSettings();

    expect(restored.automaticReportMode, AutomaticReportMode.weekly);
    expect(restored.automaticReportHour, 19);
    expect(restored.automaticReportMinute, 45);
    expect(restored.automaticReportWeekday, Weekday.wednesday);
  });
}
