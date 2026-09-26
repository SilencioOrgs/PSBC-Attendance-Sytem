import 'package:drift/drift.dart';

import '../../../domain/models.dart';
import '../../../domain/repositories.dart';
import '../../../services/storage/app_database.dart';

class DriftSettingsRepository implements SettingsRepository {
  DriftSettingsRepository(this._db, {Future<bool> Function()? canManage})
    : _canManage = canManage ?? _allowManagement;
  final AppDatabase _db;
  final Future<bool> Function() _canManage;

  static Future<bool> _allowManagement() async => true;
  AppSettings _fallback() => AppSettings(
    id: '00000000-0000-4000-8000-000000000001',
    updatedAt: DateTime.now(),
    syncStatus: SyncStatus.synced,
    soundEnabled: true,
    vibrationEnabled: true,
    scanDurationSeconds: 15,
    rssiThreshold: -75,
  );
  @override
  Future<AppSettings> getSettings() async =>
      await _db.settingsDao.getSettings() ?? _fallback();
  @override
  Stream<AppSettings> watchSettings() => _db.settingsDao.watchSettings().map(
    (settings) => settings ?? _fallback(),
  );
  @override
  Future<AppSettings> saveSettings(AppSettings settings) async {
    if (!await _canManage()) throw const PermissionDeniedException();
    final now = DateTime.now();
    await _db.settingsDao.save(
      AppSettingsRowsCompanion.insert(
        id: settings.id,
        updatedAt: now,
        syncStatus: settings.syncStatus == SyncStatus.synced
            ? SyncStatus.pendingUpdate
            : settings.syncStatus,
        singletonKey: const Value('settings'),
        scanDurationSeconds: settings.scanDurationSeconds,
        rssiThreshold: settings.rssiThreshold,
        soundEnabled: settings.soundEnabled,
        vibrationEnabled: settings.vibrationEnabled,
        automaticReportMode: Value(settings.automaticReportMode),
        automaticReportHour: Value(settings.automaticReportHour),
        automaticReportMinute: Value(settings.automaticReportMinute),
        automaticReportWeekday: Value(settings.automaticReportWeekday.index),
      ),
    );
    return AppSettings(
      id: settings.id,
      updatedAt: now,
      syncStatus: SyncStatus.pendingUpdate,
      soundEnabled: settings.soundEnabled,
      vibrationEnabled: settings.vibrationEnabled,
      scanDurationSeconds: settings.scanDurationSeconds,
      rssiThreshold: settings.rssiThreshold,
      automaticReportMode: settings.automaticReportMode,
      automaticReportHour: settings.automaticReportHour,
      automaticReportMinute: settings.automaticReportMinute,
      automaticReportWeekday: settings.automaticReportWeekday,
    );
  }
}
