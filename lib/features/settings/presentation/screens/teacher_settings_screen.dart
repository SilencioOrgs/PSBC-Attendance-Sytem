import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/utils/teacher_pin.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../domain/models.dart';
import '../../../../domain/repositories.dart';
import '../../../authentication/application/teacher_auth_service.dart';
import '../../../device/presentation/providers/device_provider.dart';
import '../../../teacher/presentation/providers/teacher_provider.dart';
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
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
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
        ),
      );

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Attendance is still active. Review or cancel it before logging out.',
            ),
            action: SnackBarAction(
              label: 'Review',
              onPressed: () => context.pushNamed(
                AppRoutes.attendanceResults,
                pathParameters: {'sessionId': error.sessionId},
              ),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to log out. Try again.')),
        );
      }
    }
  }

  static Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final currentPin = TextEditingController();
    final newPin = TextEditingController();
    final confirmPin = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final values = await showDialog<List<String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change teacher PIN'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: const [DigitsOnlyPinFormatter()],
                decoration: const InputDecoration(labelText: 'Current PIN'),
                validator: (value) => !isValidTeacherPin(value ?? '')
                    ? 'Enter your current 4 to 6 digit PIN.'
                    : null,
              ),
              TextFormField(
                controller: newPin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: const [DigitsOnlyPinFormatter()],
                decoration: const InputDecoration(labelText: 'New PIN'),
                validator: (value) => !isValidTeacherPin(value ?? '')
                    ? 'Use 4 to 6 digits.'
                    : null,
              ),
              TextFormField(
                controller: confirmPin,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: const [DigitsOnlyPinFormatter()],
                decoration: const InputDecoration(labelText: 'Confirm new PIN'),
                validator: (value) =>
                    value != newPin.text ? 'The PINs do not match.' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() != true) return;
              Navigator.pop(context, [currentPin.text, newPin.text]);
            },
            child: const Text('Save PIN'),
          ),
        ],
      ),
    );
    if (values == null) {
      currentPin.dispose();
      newPin.dispose();
      confirmPin.dispose();
      return;
    }
    try {
      await ref
          .read(settingsControllerProvider.notifier)
          .changePin(currentPin: values[0], newPin: values[1]);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Teacher PIN updated.')));
      }
    } on InvalidTeacherPinException {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('The current PIN does not match.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to update your PIN. Try again.'),
          ),
        );
      }
    } finally {
      currentPin.dispose();
      newPin.dispose();
      confirmPin.dispose();
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
