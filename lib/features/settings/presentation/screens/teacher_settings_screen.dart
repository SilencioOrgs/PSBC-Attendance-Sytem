import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../domain/models.dart';
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
          Text(
            'Devices and storage',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: Spacing.sm),
          SectionCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
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
          if (kDebugMode) ...[
            const SizedBox(height: Spacing.lg),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developer tools',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    'Load the Phase 1 classroom fixtures into local storage.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: Spacing.md),
                  OutlinedButton.icon(
                    onPressed: () async {
                      try {
                        await ref.read(demoDataLoaderProvider).load();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Demo data loaded.')),
                          );
                        }
                      } catch (error) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Could not load demo data: $error'),
                            ),
                          );
                        }
                      }
                    },
                    icon: const Icon(Icons.dataset_outlined),
                    label: const Text('Load demo data'),
                  ),
                ],
              ),
            ),
          ],
          if (kDebugMode) ...[
            const SizedBox(height: Spacing.lg),
            OutlinedButton.icon(
              onPressed: () => context.goNamed(AppRoutes.debugRoles),
              icon: const Icon(Icons.developer_mode),
              label: const Text('Switch role preview'),
            ),
          ],
          const SizedBox(height: Spacing.lg),
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
