import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/iterable_extensions.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../domain/repositories.dart';
import '../../../student/presentation/providers/student_provider.dart';
import '../providers/device_provider.dart';

/// Student Device tab for registering and checking their BLE peripheral.
class DeviceRegistrationScreen extends ConsumerStatefulWidget {
  const DeviceRegistrationScreen({super.key});

  @override
  ConsumerState<DeviceRegistrationScreen> createState() =>
      _DeviceRegistrationScreenState();
}

class _DeviceRegistrationScreenState
    extends ConsumerState<DeviceRegistrationScreen> {
  final _deviceNameController = TextEditingController(
    text: 'ClassAttend Companion',
  );
  final _bleUuidController = TextEditingController();
  String? _deviceError;
  bool _isRegistering = false;

  @override
  void dispose() {
    _deviceNameController.dispose();
    _bleUuidController.dispose();
    super.dispose();
  }

  Future<void> _register(String studentId) async {
    setState(() => _isRegistering = true);
    try {
      await ref
          .read(deviceRegistrationControllerProvider.notifier)
          .register(
            studentId,
            _deviceNameController.text.trim().isEmpty
                ? 'ClassAttend Companion'
                : _deviceNameController.text.trim(),
            bleUuid: _bleUuidController.text.trim().isEmpty
                ? null
                : _bleUuidController.text.trim(),
          );
    } on RepositoryException catch (error) {
      setState(() => _deviceError = error.message);
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentAsync = ref.watch(currentStudentProvider);
    final deviceAsync = ref.watch(myDeviceProvider);
    return PageScaffold(
      title: 'Device',
      body: studentAsync.when(
        data: (student) => deviceAsync.when(
          data: (device) => SingleChildScrollView(
            padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionCard(
                  child: Column(
                    children: [
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bluetooth,
                          color: AppColors.primary,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: Spacing.md),
                      Text(
                        device == null
                            ? 'No device registered'
                            : 'Device is registered',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: Spacing.xs),
                      Text(
                        device == null
                            ? 'Register this device to be detected during classroom attendance.'
                            : 'This device is linked to ${student?.name ?? 'your profile'}.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: Spacing.md),
                      StatusPill(
                        status: device == null
                            ? AttendanceStatus.pending
                            : AttendanceStatus.registered,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.lg),
                if (device == null) ...[
                  Text(
                    'Device details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: Spacing.sm),
                  TextField(
                    controller: _deviceNameController,
                    decoration: const InputDecoration(
                      labelText: 'Device name',
                      prefixIcon: Icon(Icons.devices_outlined),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  TextField(
                    controller: _bleUuidController,
                    decoration: InputDecoration(
                      labelText: 'BLE UUID (optional)',
                      helperText: 'Leave blank to assign a local device ID.',
                      errorText: _deviceError,
                      prefixIcon: const Icon(Icons.fingerprint_outlined),
                    ),
                    onChanged: (_) {
                      if (_deviceError != null) {
                        setState(() => _deviceError = null);
                      }
                    },
                  ),
                  const SizedBox(height: Spacing.md),
                  PrimaryActionButton(
                    label: _isRegistering
                        ? 'Registering device...'
                        : 'Register this device',
                    icon: Icons.bluetooth_connected,
                    onPressed: student == null || _isRegistering
                        ? null
                        : () => _register(student.id),
                  ),
                ] else ...[
                  SectionCard(
                    child: Column(
                      children: [
                        _DeviceLine(label: 'Device', value: device.name),
                        const Divider(height: Spacing.lg),
                        _DeviceLine(label: 'Address', value: device.address),
                        const Divider(height: Spacing.lg),
                        _DeviceLine(
                          label: 'Last seen',
                          value: device.lastSeenAt == null
                              ? 'Not available'
                              : 'Today, ${_formatTime(device.lastSeenAt!)}',
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: Spacing.lg),
                SectionCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          'Keep Bluetooth enabled and carry this device during class. Attendance is stored on the teacher’s device.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const _DeviceError(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const _DeviceError(),
      ),
    );
  }
}

/// Teacher Device Status route with registered devices and connectivity.
class DeviceStatusScreen extends ConsumerWidget {
  const DeviceStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(deviceListProvider);
    final studentsAsync = ref.watch(allStudentsProvider);
    return PageScaffold(
      title: 'Device status',
      showBack: true,
      body: devicesAsync.when(
        data: (devices) => studentsAsync.when(
          data: (students) {
            final connected = devices
                .where((device) => device.isConnected)
                .length;
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: Spacing.sm,
                    bottom: Spacing.md,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: MetricStatCard(
                          label: 'Registered',
                          value: '${devices.length}',
                          icon: Icons.devices_outlined,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: MetricStatCard(
                          label: 'Connected',
                          value: '$connected',
                          icon: Icons.bluetooth_connected,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: Spacing.lg),
                    itemCount: devices.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      final owner = students
                          .where(
                            (student) => student.id == device.ownerStudentId,
                          )
                          .firstOrNull;
                      return PersonListTile(
                        name: owner?.name ?? device.name,
                        subtitle: '${device.name} · ${device.address}',
                        status: device.isConnected
                            ? AttendanceStatus.detected
                            : AttendanceStatus.pending,
                        trailing: StatusPill(
                          status: device.isConnected
                              ? AttendanceStatus.detected
                              : AttendanceStatus.pending,
                          label: device.isConnected ? 'Connected' : 'Inactive',
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const _DeviceError(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const _DeviceError(),
      ),
    );
  }
}

class _DeviceLine extends StatelessWidget {
  const _DeviceLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.muted),
        ),
      ),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.end,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    ],
  );
}

class _DeviceError extends StatelessWidget {
  const _DeviceError();

  @override
  Widget build(BuildContext context) => const Center(
    child: SectionCard(child: Text('Device information is unavailable.')),
  );
}

String _formatTime(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  return '$hour:$minute ${dateTime.hour >= 12 ? 'PM' : 'AM'}';
}
