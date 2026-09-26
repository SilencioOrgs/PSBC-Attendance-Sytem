import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';

import '../../domain/models.dart';
import '../../services/storage/app_database.dart';
import 'auto_attendance_report_runner.dart';

const _autoReportTaskName = 'classattend.automatic_attendance_reports';
const _autoReportTaskTag = 'classattend.automatic_attendance_reports';
const _modeInputKey = 'mode';
const _occurrenceInputKey = 'occurrenceAt';

/// Calculates local wall-clock occurrences independently from WorkManager.
class AutomaticReportSchedule {
  const AutomaticReportSchedule._();

  static DateTime nextOccurrence({
    required AutomaticReportMode mode,
    required DateTime now,
    required int hour,
    required int minute,
    required Weekday weekday,
  }) {
    if (mode == AutomaticReportMode.off) {
      throw ArgumentError.value(mode, 'mode', 'A schedule must be enabled.');
    }
    final today = DateTime(now.year, now.month, now.day, hour, minute);
    if (mode == AutomaticReportMode.daily) {
      return today.isAfter(now) ? today : today.add(const Duration(days: 1));
    }

    final daysUntilWeekday = (weekday.index - (now.weekday - 1) + 7) % 7;
    final next = today.add(Duration(days: daysUntilWeekday));
    return next.isAfter(now) ? next : next.add(const Duration(days: 7));
  }

  static ({DateTime start, DateTime end}) windowFor({
    required AutomaticReportMode mode,
    required DateTime occurrenceAt,
  }) {
    final end = occurrenceAt;
    final start = mode == AutomaticReportMode.daily
        ? DateTime(end.year, end.month, end.day)
        : DateTime(end.year, end.month, end.day - 7, end.hour, end.minute);
    return (start: start, end: end);
  }
}

/// Owns the durable OS schedule and local completion notifications.
class AutomaticReportScheduler {
  AutomaticReportScheduler({Workmanager? workmanager})
    : _workmanager = workmanager ?? Workmanager();

  final Workmanager _workmanager;

  bool get isSupported => !kIsWeb && Platform.isAndroid;

  Future<void> initialize() async {
    if (isSupported) {
      await _workmanager.initialize(automaticReportCallbackDispatcher);
    }
  }

  Future<void> sync(AppSettings settings, {DateTime? now}) async {
    if (!isSupported) return;
    await _workmanager.cancelByTag(_autoReportTaskTag);
    if (settings.automaticReportMode == AutomaticReportMode.off) return;
    await _scheduleNext(settings, now: now ?? DateTime.now());
  }

  Future<void> scheduleNextFromSettings(
    AppDatabase database, {
    DateTime? now,
  }) async {
    if (!isSupported) return;
    final settings = await database.settingsDao.getSettings();
    if (settings == null ||
        settings.automaticReportMode == AutomaticReportMode.off) {
      return;
    }
    await _scheduleNext(settings, now: now ?? DateTime.now());
  }

  Future<void> _scheduleNext(
    AppSettings settings, {
    required DateTime now,
  }) async {
    final occurrenceAt = AutomaticReportSchedule.nextOccurrence(
      mode: settings.automaticReportMode,
      now: now,
      hour: settings.automaticReportHour,
      minute: settings.automaticReportMinute,
      weekday: settings.automaticReportWeekday,
    );
    final delay = occurrenceAt.difference(now);
    await _workmanager.registerOneOffTask(
      '$_autoReportTaskName-${settings.automaticReportMode.name}-${occurrenceAt.millisecondsSinceEpoch}',
      _autoReportTaskName,
      inputData: {
        _modeInputKey: settings.automaticReportMode.name,
        _occurrenceInputKey: occurrenceAt.millisecondsSinceEpoch,
      },
      initialDelay: delay.isNegative ? Duration.zero : delay,
      tag: _autoReportTaskTag,
      existingWorkPolicy: ExistingWorkPolicy.replace,
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 15),
    );
  }
}

final FlutterLocalNotificationsPlugin automaticReportNotifications =
    FlutterLocalNotificationsPlugin();

Future<void> initializeAutomaticReportNotifications({
  void Function()? onNotificationTap,
}) async {
  const settings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  );
  await automaticReportNotifications.initialize(
    settings: settings,
    onDidReceiveNotificationResponse: (_) => onNotificationTap?.call(),
  );
}

Future<void> requestAutomaticReportNotificationPermission() async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    await automaticReportNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  } catch (_) {
    // Report generation and saving continue if notifications are unavailable.
  }
}

Future<void> showAutomaticReportNotification({
  required bool succeeded,
  required int generatedCount,
}) async {
  try {
    await initializeAutomaticReportNotifications();
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'automatic_attendance_reports',
        'Attendance reports',
        channelDescription: 'Scheduled attendance report results',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(),
    );
    await automaticReportNotifications.show(
      id: 8042,
      title: succeeded
          ? 'Attendance reports ready'
          : 'Attendance report needs attention',
      body: succeeded
          ? '$generatedCount PDF${generatedCount == 1 ? '' : 's'} saved to Downloads/ClassAttend/Attendance Reports.'
          : 'ClassAttend could not create all scheduled reports. Open Settings to retry.',
      notificationDetails: details,
      payload: 'attendance_reports',
    );
  } catch (_) {
    // Notification permission is optional and never blocks saved files.
  }
}

@pragma('vm:entry-point')
void automaticReportCallbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    if (taskName != _autoReportTaskName || inputData == null) return true;
    final modeName = inputData[_modeInputKey] as String?;
    final timestamp = inputData[_occurrenceInputKey] as int?;
    final mode = AutomaticReportMode.values
        .where((value) => value.name == modeName)
        .firstOrNull;
    if (mode == null || mode == AutomaticReportMode.off || timestamp == null) {
      return true;
    }

    final occurrenceAt = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final database = AppDatabase();
    try {
      final succeeded = await AutoAttendanceReportRunner(database)
          .run(mode: mode, occurrenceAt: occurrenceAt);
      if (succeeded) {
        await AutomaticReportScheduler().scheduleNextFromSettings(database);
      }
      return succeeded;
    } finally {
      await database.close();
    }
  });
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
