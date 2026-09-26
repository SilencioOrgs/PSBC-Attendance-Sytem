import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/teacher_pin.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../domain/models.dart';
import '../../../../domain/repositories.dart';
import '../../../authentication/application/teacher_auth_service.dart';
import '../../../device/presentation/providers/device_provider.dart';
import '../../../teacher/presentation/providers/teacher_provider.dart';
import '../../../teacher/presentation/widgets/pin_keypad.dart';
import '../providers/settings_provider.dart';

/// Teacher Settings tab with local attendance preferences.
class TeacherSettingsScreen extends ConsumerWidget {
  const TeacherSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final teacherAsync = ref.watch(teacherProvider);
    return PageScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xl),
        children: [
          Text('Account', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          SectionCard(
            child: teacherAsync.when(
              data: (teacher) => Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primarySoft,
                    foregroundColor: AppColors.primary,
                    child: Text(
                      teacher.name
                          .split(' ')
                          .map((part) => part.substring(0, 1))
                          .take(2)
                          .join()
                          .toUpperCase(),
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          teacher.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Text('Teacher account · stored on this device'),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) =>
                  const Text('Teacher account is unavailable.'),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          SecondaryActionButton(
            label: 'Switch role',
            icon: Icons.swap_horiz,
            onPressed: () => context.go('/roles'),
          ),
          const SizedBox(height: Spacing.lg),
          Text('Security', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.password_outlined),
                  title: const Text('Change PIN'),
                  subtitle: const Text(
                    'Update the PIN used to unlock teacher access',
                  ),
                  onTap: () => _changePin(context, ref),
                ),
                const Divider(
                  height: 1,
                  indent: Spacing.md,
                  endIndent: Spacing.md,
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Log out'),
                  subtitle: const Text(
                    'Lock the teacher dashboard on this device',
                  ),
                  onTap: () => _logout(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text('Attendance', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          SectionCard(
            padding: EdgeInsets.zero,
            child: settingsAsync.when(
              data: (settings) => Column(
                children: [
                  SwitchListTile.adaptive(
                    value: settings.soundEnabled,
                    title: const Text('Sound feedback'),
                    subtitle: const Text(
                      'Play a sound when a device is detected',
                    ),
                    secondary: const Icon(Icons.volume_up_outlined),
                    onChanged: (value) =>
                        _save(ref, settings, soundEnabled: value),
                  ),
                  const Divider(
                    height: 1,
                    indent: Spacing.md,
                    endIndent: Spacing.md,
                  ),
                  SwitchListTile.adaptive(
                    value: settings.vibrationEnabled,
                    title: const Text('Vibration feedback'),
                    subtitle: const Text('Vibrate when a device is detected'),
                    secondary: const Icon(Icons.vibration),
                    onChanged: (value) =>
                        _save(ref, settings, vibrationEnabled: value),
                  ),
                  const Divider(
                    height: 1,
                    indent: Spacing.md,
                    endIndent: Spacing.md,
                  ),
                  ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: const Text('Scan duration'),
                    subtitle: Text('${settings.scanDurationSeconds} seconds'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _chooseDuration(context, ref, settings),
                  ),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(Spacing.md),
                child: LinearProgressIndicator(),
              ),
              error: (error, stack) => const Padding(
                padding: EdgeInsets.all(Spacing.md),
                child: Text('Settings are unavailable.'),
              ),
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text('Bluetooth', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: const Text('Bluetooth status'),
                  subtitle: ref
                      .watch(bleAdapterStateProvider)
                      .when(
                        data: (availability) => Text(switch (availability) {
                          BleAvailability.ready =>
                            'Ready to scan and advertise',
                          BleAvailability.poweredOff =>
                            'Bluetooth is turned off',
                          BleAvailability.permissionDenied =>
                            'Bluetooth permission is required',
                          BleAvailability.unsupported =>
                            'Bluetooth LE is not supported on this device',
                          BleAvailability.unknown =>
                            'Checking Bluetooth status',
                        }),
                        loading: () => const Text('Checking Bluetooth status'),
                        error: (error, stack) => const Text(
                          'Bluetooth status is unavailable. Try scanning to check access.',
                        ),
                      ),
                ),
                const Divider(
                  height: 1,
                  indent: Spacing.md,
                  endIndent: Spacing.md,
                ),
                ListTile(
                  leading: const Icon(Icons.bluetooth_searching),
                  title: const Text('Device status'),
                  subtitle: ref
                      .watch(deviceListProvider)
                      .when(
                        data: (devices) => Text(
                          '${devices.length} student devices registered',
                        ),
                        loading: () => const Text('Loading device list'),
                        error: (error, stack) =>
                            const Text('Device list unavailable'),
                      ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(AppRoutes.teacherDeviceStatus),
                ),
                const Divider(
                  height: 1,
                  indent: Spacing.md,
                  endIndent: Spacing.md,
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text('Data & Reports', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          _automaticReportsCard(context, ref, settingsAsync),
          const SizedBox(height: Spacing.sm),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.qr_code_2),
                  title: const Text('Share subjects QR'),
                  subtitle: const Text('Create an offline subject invitation'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.pushNamed(AppRoutes.shareSubjects),
                ),
                const Divider(
                  height: 1,
                  indent: Spacing.md,
                  endIndent: Spacing.md,
                ),
                ListTile(
                  leading: const Icon(Icons.event_note_outlined),
                  title: const Text('Attendance history and exports'),
                  subtitle: const Text('Review sessions and export reports'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.goNamed(AppRoutes.teacherAttendance),
                ),
                const Divider(
                  height: 1,
                  indent: Spacing.md,
                  endIndent: Spacing.md,
                ),
                const ListTile(
                  leading: Icon(Icons.storage_outlined),
                  title: Text('Local storage'),
                  subtitle: Text('Attendance records are saved on this device'),
                  trailing: StatusPill(
                    status: AttendanceStatus.registered,
                    label: 'Active',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text('About', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          Center(
            child: Text(
              'ClassAttend · Local storage',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _save(
    WidgetRef ref,
    AppSettings settings, {
    bool? soundEnabled,
    bool? vibrationEnabled,
    int? scanDurationSeconds,
    AutomaticReportMode? automaticReportMode,
    int? automaticReportHour,
    int? automaticReportMinute,
    Weekday? automaticReportWeekday,
  }) => ref
      .read(settingsControllerProvider.notifier)
      .save(
        AppSettings(
          id: settings.id,
          updatedAt: DateTime.now(),
          syncStatus: SyncStatus.pendingUpdate,
          soundEnabled: soundEnabled ?? settings.soundEnabled,
          vibrationEnabled: vibrationEnabled ?? settings.vibrationEnabled,
          scanDurationSeconds:
              scanDurationSeconds ?? settings.scanDurationSeconds,
          rssiThreshold: settings.rssiThreshold,
          automaticReportMode:
              automaticReportMode ?? settings.automaticReportMode,
          automaticReportHour:
              automaticReportHour ?? settings.automaticReportHour,
          automaticReportMinute:
              automaticReportMinute ?? settings.automaticReportMinute,
          automaticReportWeekday:
              automaticReportWeekday ?? settings.automaticReportWeekday,
        ),
      );

  static Widget _automaticReportsCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<AppSettings> settingsAsync,
  ) => SectionCard(
    padding: EdgeInsets.zero,
    child: settingsAsync.when(
      data: (settings) => Column(
        children: [
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Automatic attendance PDFs'),
            subtitle: const Text(
              'Save completed attendance sessions in the background',
            ),
            trailing: DropdownButton<AutomaticReportMode>(
              value: settings.automaticReportMode,
              underline: const SizedBox.shrink(),
              onChanged: (mode) {
                if (mode != null) {
                  _save(ref, settings, automaticReportMode: mode);
                }
              },
              items: const [
                DropdownMenuItem(
                  value: AutomaticReportMode.off,
                  child: Text('Off'),
                ),
                DropdownMenuItem(
                  value: AutomaticReportMode.daily,
                  child: Text('Daily'),
                ),
                DropdownMenuItem(
                  value: AutomaticReportMode.weekly,
                  child: Text('Weekly'),
                ),
              ],
            ),
          ),
          if (settings.automaticReportMode != AutomaticReportMode.off) ...[
            const Divider(height: 1, indent: Spacing.md, endIndent: Spacing.md),
            ListTile(
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('Run time'),
              subtitle: Text(
                _formatTime(
                  context,
                  TimeOfDay(
                    hour: settings.automaticReportHour,
                    minute: settings.automaticReportMinute,
                  ),
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _chooseReportTime(context, ref, settings),
            ),
            if (settings.automaticReportMode == AutomaticReportMode.weekly) ...[
              const Divider(
                height: 1,
                indent: Spacing.md,
                endIndent: Spacing.md,
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Run day'),
                subtitle: Text(_weekdayName(settings.automaticReportWeekday)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _chooseReportWeekday(context, ref, settings),
              ),
            ],
          ],
          const Divider(height: 1, indent: Spacing.md, endIndent: Spacing.md),
          ref
              .watch(latestAutomaticReportRunProvider)
              .when(
                data: (run) => ListTile(
                  leading: Icon(
                    run?.status == AutoReportRunStatus.failed
                        ? Icons.error_outline
                        : Icons.folder_outlined,
                    color: run?.status == AutoReportRunStatus.failed
                        ? AppColors.danger
                        : null,
                  ),
                  title: Text(switch (run?.status) {
                    AutoReportRunStatus.failed => 'Last run needs attention',
                    AutoReportRunStatus.running => 'Creating attendance PDFs',
                    AutoReportRunStatus.succeeded => 'Last run completed',
                    null => 'No automatic reports yet',
                  }),
                  subtitle: Text(switch (run?.status) {
                    AutoReportRunStatus.failed =>
                      '${run!.failedCount} report${run.failedCount == 1 ? '' : 's'} could not be saved',
                    AutoReportRunStatus.running =>
                      'The background job is in progress',
                    AutoReportRunStatus.succeeded =>
                      '${run!.generatedCount} PDF${run.generatedCount == 1 ? '' : 's'} saved · ${_formatDate(run.attemptedAt)}',
                    null => 'Saved files go to Downloads/ClassAttend/Attendance Reports',
                  }),
                  trailing: run?.status == AutoReportRunStatus.failed
                      ? TextButton(
                          onPressed: () => _retryAutomaticReports(context, ref),
                          child: const Text('Retry'),
                        )
                      : null,
                ),
                loading: () => const ListTile(
                  leading: Icon(Icons.folder_outlined),
                  title: Text('Checking report status'),
                ),
                error: (error, stack) => const ListTile(
                  leading: Icon(Icons.folder_outlined),
                  title: Text('Report status unavailable'),
                ),
              ),
        ],
      ),
      loading: () => const Padding(
        padding: EdgeInsets.all(Spacing.md),
        child: LinearProgressIndicator(),
      ),
      error: (error, stack) => const Padding(
        padding: EdgeInsets.all(Spacing.md),
        child: Text('Report settings are unavailable.'),
      ),
    ),
  );

  static Future<void> _chooseReportTime(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.automaticReportHour,
        minute: settings.automaticReportMinute,
      ),
    );
    if (selected != null) {
      await _save(
        ref,
        settings,
        automaticReportHour: selected.hour,
        automaticReportMinute: selected.minute,
      );
    }
  }

  static Future<void> _chooseReportWeekday(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final selected = await showModalBottomSheet<Weekday>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final day in Weekday.values)
              ListTile(
                title: Text(_weekdayName(day)),
                trailing: day == settings.automaticReportWeekday
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, day),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await _save(ref, settings, automaticReportWeekday: selected);
    }
  }

  static Future<void> _retryAutomaticReports(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final completed = await ref
          .read(settingsControllerProvider.notifier)
          .retryFailedAutomaticReport();
      if (!context.mounted) return;
      if (completed) {
        AppFeedback.success(context, 'Attendance reports saved to Downloads.');
      } else {
        AppFeedback.error(
          context,
          'Some reports still could not be saved. Try again later.',
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      AppFeedback.error(context, 'Unable to retry attendance reports.');
    }
  }

  static String _weekdayName(Weekday weekday) => switch (weekday) {
    Weekday.monday => 'Monday',
    Weekday.tuesday => 'Tuesday',
    Weekday.wednesday => 'Wednesday',
    Weekday.thursday => 'Thursday',
    Weekday.friday => 'Friday',
    Weekday.saturday => 'Saturday',
    Weekday.sunday => 'Sunday',
  };

  static String _formatTime(BuildContext context, TimeOfDay time) =>
      MaterialLocalizations.of(context).formatTimeOfDay(time);

  static String _formatDate(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';

  static Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          "You'll need your teacher PIN to open the teacher dashboard again. "
          'Your classes and attendance records will remain on this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      await ref.read(settingsControllerProvider.notifier).logout();
    } on ActiveAttendanceSessionException catch (error) {
      if (context.mounted) {
        AppFeedback.error(
          context,
          'Attendance is still active. Review or cancel it before logging out.',
          action: SnackBarAction(
            label: 'Review',
            onPressed: () => context.pushNamed(
              AppRoutes.attendanceResults,
              pathParameters: {'sessionId': error.sessionId},
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        AppFeedback.error(context, 'Unable to log out. Try again.');
      }
    }
  }

  static Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        var stage = 0;
        var currentPin = '';
        var newPin = '';
        var activePin = '';
        String? helperText;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Change teacher PIN'),
            content: SizedBox(
              width: 320,
              child: PinKeypad(
                title: switch (stage) {
                  0 => 'Enter current PIN',
                  1 => 'Choose a new PIN',
                  _ => 'Confirm the new PIN',
                },
                pin: activePin,
                helperText: helperText,
                onDigit: (digit) => setDialogState(() {
                  activePin += digit;
                  helperText = null;
                }),
                onDelete: () => setDialogState(() {
                  if (activePin.isNotEmpty) {
                    activePin = activePin.substring(0, activePin.length - 1);
                  }
                  helperText = null;
                }),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (!isValidTeacherPin(activePin)) {
                    setDialogState(() {
                      helperText = 'Enter 4 to 6 digits.';
                    });
                    return;
                  }
                  if (stage == 0) {
                    currentPin = activePin;
                    stage = 1;
                    activePin = '';
                    helperText = null;
                    setDialogState(() {});
                    return;
                  }
                  if (stage == 1) {
                    newPin = activePin;
                    stage = 2;
                    activePin = '';
                    helperText = null;
                    setDialogState(() {});
                    return;
                  }
                  if (activePin != newPin) {
                    setDialogState(() {
                      helperText = 'The PINs do not match.';
                      activePin = '';
                    });
                    return;
                  }
                  Navigator.pop(dialogContext, [currentPin, newPin]);
                },
                child: Text(stage == 2 ? 'Save PIN' : 'Continue'),
              ),
            ],
          ),
        );
      },
    );
    if (values == null) return;
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .changePin(currentPin: values[0], newPin: values[1]);
      if (context.mounted) {
        AppFeedback.success(context, 'Teacher PIN updated.');
      }
    } on InvalidTeacherPinException {
      if (context.mounted) {
        AppFeedback.error(context, 'The current PIN does not match.');
      }
    } catch (_) {
      if (context.mounted) {
        AppFeedback.error(context, 'Unable to update your PIN. Try again.');
      }
    }
  }

  static Future<void> _chooseDuration(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Text(
                'Scan duration',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final seconds in [6, 8, 10, 12])
              ListTile(
                title: Text('$seconds seconds'),
                trailing: settings.scanDurationSeconds == seconds
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(context, seconds),
              ),
            const SizedBox(height: Spacing.sm),
          ],
        ),
      ),
    );
    if (selected != null) {
      await _save(ref, settings, scanDurationSeconds: selected);
    }
  }
}
