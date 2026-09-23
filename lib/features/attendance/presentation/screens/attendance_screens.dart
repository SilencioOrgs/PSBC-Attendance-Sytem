import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/iterable_extensions.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../domain/models.dart';
import '../../../student/presentation/providers/student_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/ble_scan_provider.dart';

/// Full-screen BLE scan flow, outside either bottom navigation shell.
class BleScannerScreen extends ConsumerStatefulWidget {
  const BleScannerScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<BleScannerScreen> createState() => _BleScannerScreenState();
}

class _BleScannerScreenState extends ConsumerState<BleScannerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bleScanControllerProvider.notifier).start(widget.sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(bleScanControllerProvider, (previous, next) {
      if (previous?.isComplete != true && next.isComplete && mounted) {
        context.goNamed(
          AppRoutes.attendanceResults,
          pathParameters: {'sessionId': widget.sessionId},
        );
      }
    });
    final scan = ref.watch(bleScanControllerProvider);
    final recordsAsync = ref.watch(attendanceRecordsProvider(widget.sessionId));
    final rosterAsync = ref.watch(attendanceRosterProvider(widget.sessionId));
    return PageScaffold(
      title: 'BLE scanner',
      showBack: true,
      body: Column(
        children: [
          const SizedBox(height: Spacing.sm),
          Text(
            'Scanning for student devices',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            scan.isScanning
                ? 'Keep this screen open while devices are detected.'
                : 'Finalize the scan to prepare attendance results.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: Spacing.sm),
          BleRadarIndicator(
            isScanning: scan.isScanning,
            progress: scan.progress,
          ),
          Row(
            children: [
              Expanded(
                child: MetricStatCard(
                  label: 'Devices found',
                  value: '${scan.discoveredDevices.length}',
                  icon: Icons.bluetooth_connected,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: MetricStatCard(
                  label: 'Scan progress',
                  value: '${(scan.progress * 100).round()}%',
                  icon: Icons.radar,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Nearby devices',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Expanded(
            child: rosterAsync.when(
              data: (roster) {
                final detectedIds = scan.discoveredDevices
                    .map((device) => device.ownerStudentId)
                    .whereType<String>()
                    .toSet();
                final detected = roster
                    .where((student) => detectedIds.contains(student.id))
                    .toList();
                if (detected.isEmpty) {
                  return Center(
                    child: Text(
                      'Waiting for nearby devices...',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                  );
                }
                return ListView.separated(
                  itemCount: detected.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = detected[index];
                    final record = recordsAsync.value
                        ?.where((item) => item.studentId == student.id)
                        .firstOrNull;
                    return PersonListTile(
                      name: student.name,
                      subtitle: student.studentNumber,
                      status: record?.isPresent == false
                          ? AttendanceStatus.absent
                          : AttendanceStatus.detected,
                      onTap: () => ref
                          .read(
                            attendanceRecordsProvider(widget.sessionId)
                                .notifier,
                          )
                          .toggleStudent(student.id),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  const Center(child: Text('Student roster is unavailable.')),
            ),
          ),
          const SizedBox(height: Spacing.md),
          PrimaryActionButton(
            label: scan.isScanning
                ? 'Stop scan and view results'
                : 'Finalize attendance',
            icon: scan.isScanning ? Icons.stop_circle_outlined : Icons.check,
            onPressed: scan.isComplete
                ? null
                : () => ref
                      .read(bleScanControllerProvider.notifier)
                      .stopAndFinalize(),
          ),
          const SizedBox(height: Spacing.sm),
        ],
      ),
    );
  }
}

/// Review detected students and toggle a student's attendance status.
class AttendanceResultsScreen extends ConsumerWidget {
  const AttendanceResultsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(attendanceRecordsProvider(sessionId));
    final studentsAsync = ref.watch(attendanceRosterProvider(sessionId));
    return PageScaffold(
      title: 'Attendance results',
      showBack: true,
      body: recordsAsync.when(
        data: (records) => studentsAsync.when(
          data: (students) {
            final present = records.where((record) => record.isPresent).length;
            final absent = records.length - present;
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
                          label: 'Present',
                          value: '$present',
                          icon: Icons.check_circle_outline,
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: MetricStatCard(
                          label: 'Absent',
                          value: '$absent',
                          icon: Icons.person_off_outlined,
                          color: AppColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
                SectionCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: AppColors.primary),
                      const SizedBox(width: Spacing.sm),
                      Expanded(
                        child: Text(
                          'Tap a student to change their attendance status.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    itemCount: records.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      final student = students
                          .where((item) => item.id == record.studentId)
                          .firstOrNull;
                      if (student == null) return const SizedBox.shrink();
                      return PersonListTile(
                        name: student.name,
                        subtitle: student.studentNumber,
                        status: record.isPresent
                            ? AttendanceStatus.present
                            : AttendanceStatus.absent,
                        onTap: () => ref
                            .read(attendanceRecordsProvider(sessionId).notifier)
                            .toggleStudent(student.id),
                      );
                    },
                  ),
                ),
                PrimaryActionButton(
                  label: 'Done',
                  icon: Icons.check,
                  onPressed: () => context.goNamed(AppRoutes.teacherHome),
                ),
                const SizedBox(height: Spacing.sm),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const _AttendanceError(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const _AttendanceError(),
      ),
    );
  }
}

/// Teacher Attendance tab with recent sessions.
class AttendanceHistoryScreen extends ConsumerWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => PageScaffold(
    title: 'Attendance',
    body: ref
        .watch(attendanceHistoryProvider)
        .when(
          data: (sessions) => ListView.separated(
            padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xl),
            itemCount: sessions.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: Spacing.sm),
            itemBuilder: (context, index) =>
                _HistorySessionCard(session: sessions[index]),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const _AttendanceError(),
        ),
  );
}

class _HistorySessionCard extends ConsumerWidget {
  const _HistorySessionCard({required this.session});

  final AttendanceSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(attendanceRecordsProvider(session.id))
      .when(
        data: (records) {
          final present = records.where((record) => record.isPresent).length;
          return SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const StatusPill(
                      status: AttendanceStatus.registered,
                      label: 'Saved',
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  '${session.startedAt.day} ${_monthName(session.startedAt.month)} ${session.startedAt.year} · ${_timeLabel(session.startedAt)}',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: Spacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _HistoryMetric(
                        label: 'Present',
                        value: '$present',
                        color: AppColors.success,
                      ),
                    ),
                    Expanded(
                      child: _HistoryMetric(
                        label: 'Absent',
                        value: '${records.length - present}',
                        color: AppColors.danger,
                      ),
                    ),
                    Expanded(
                      child: _HistoryMetric(
                        label: 'Total',
                        value: '${records.length}',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        loading: () => const SectionCard(child: LinearProgressIndicator()),
        error: (error, stack) => const _AttendanceError(),
      );
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
      ),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: AppColors.muted),
      ),
    ],
  );
}

/// Student Attendance tab showing the current student's recorded sessions.
class MyAttendanceScreen extends ConsumerWidget {
  const MyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(currentStudentProvider);
    final recordsAsync = ref.watch(myAttendanceEntriesProvider);
    return PageScaffold(
      title: 'My attendance',
      body: recordsAsync.when(
        data: (entries) => studentAsync.when(
          data: (student) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: Spacing.md),
              SectionCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: Spacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student?.name ?? 'Student',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            '${entries.where((entry) => entry.record.isPresent).length} of ${entries.length} sessions attended',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Text(
                'Recent sessions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: Spacing.sm),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('No attendance records yet.'))
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: Spacing.lg),
                        itemCount: entries.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          final record = entry.record;
                          return PersonListTile(
                            name: entry.section.name,
                            subtitle:
                                '${entry.session.startedAt.day} ${_monthName(entry.session.startedAt.month)} ${entry.session.startedAt.year} · ${_timeLabel(entry.session.startedAt)}',
                            status: record.isPresent
                                ? AttendanceStatus.present
                                : AttendanceStatus.absent,
                          );
                        },
                      ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const _AttendanceError(),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const _AttendanceError(),
      ),
    );
  }
}

class _AttendanceError extends StatelessWidget {
  const _AttendanceError();

  @override
  Widget build(BuildContext context) => const Center(
    child: SectionCard(child: Text('Attendance information is unavailable.')),
  );
}

String _monthName(int month) => switch (month) {
  1 => 'January',
  2 => 'February',
  3 => 'March',
  4 => 'April',
  5 => 'May',
  6 => 'June',
  7 => 'July',
  8 => 'August',
  9 => 'September',
  10 => 'October',
  11 => 'November',
  _ => 'December',
};

String _timeLabel(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}
