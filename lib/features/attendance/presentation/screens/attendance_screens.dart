import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../domain/models.dart';
import '../../../reports/models/report_models.dart';
import '../../../reports/presentation/providers/report_export_provider.dart';
import '../../../reports/presentation/widgets/export_report_sheet.dart';
import '../../../student/presentation/providers/student_provider.dart';
import '../providers/attendance_provider.dart';
import '../providers/attendance_controller.dart';

/// Full-screen BLE scan flow, outside either bottom navigation shell.
class BleScannerScreen extends ConsumerStatefulWidget {
  const BleScannerScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<BleScannerScreen> createState() => _BleScannerScreenState();
}

class _BleScannerScreenState extends ConsumerState<BleScannerScreen> {
  Future<void> _stopAndReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End attendance?'),
        content: const Text(
          'Students that have not been detected will remain unconfirmed until you review attendance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue scanning'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End attendance'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await ref.read(attendanceControllerProvider.notifier).stopForReview();
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to stop this scan. Try again.'),
            ),
          );
        }
      }
    }
  }

  Future<void> _cancelAttendance() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel attendance?'),
        content: const Text(
          'This scan will not create finalized attendance records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continue scanning'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel attendance'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(attendanceControllerProvider.notifier)
          .cancel(widget.sessionId);
      if (mounted) context.goNamed(AppRoutes.teacherClasses);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to cancel this attendance session.'),
          ),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendanceControllerProvider.notifier).start(widget.sessionId);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(attendanceControllerProvider, (previous, next) {
      if (previous?.isComplete != true && next.isComplete && mounted) {
        context.goNamed(
          AppRoutes.attendanceResults,
          pathParameters: {'sessionId': widget.sessionId},
        );
      }
    });
    final scan = ref.watch(attendanceControllerProvider);
    final rosterAsync = ref.watch(attendanceRosterProvider(widget.sessionId));
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _stopAndReview();
      },
      child: PageScaffold(
        title: 'BLE scanner',
        showBack: true,
        onBack: _stopAndReview,
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
                  : 'End the scan when you are ready to review attendance.',
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
                    label: 'Other devices',
                    value: '${scan.unknownDeviceCount}',
                    icon: Icons.devices_other_outlined,
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
                  if (roster.isEmpty) {
                    return Center(
                      child: Text(
                        'No students are enrolled in this class yet.',
                        style: Theme.of(context).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.muted),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: roster.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final student = roster[index];
                      return PersonListTile(
                        name: student.name,
                        subtitle: student.studentNumber,
                        status: detectedIds.contains(student.id)
                            ? AttendanceStatus.detected
                            : AttendanceStatus.pending,
                        trailing: StatusPill(
                          status: detectedIds.contains(student.id)
                              ? AttendanceStatus.detected
                              : AttendanceStatus.pending,
                          label: detectedIds.contains(student.id)
                              ? 'Detected'
                              : 'Not detected',
                        ),
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
            if (scan.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: SectionCard(child: Text(scan.error!)),
              ),
            PrimaryActionButton(
              label: scan.error != null
                  ? 'Try again'
                  : scan.isScanning
                  ? 'End scan and review'
                  : 'End scan and review',
              icon: scan.error != null
                  ? Icons.refresh
                  : Icons.stop_circle_outlined,
              onPressed: scan.isComplete
                  ? null
                  : scan.error != null
                  ? () => ref
                        .read(attendanceControllerProvider.notifier)
                        .start(widget.sessionId)
                  : _stopAndReview,
            ),
            TextButton.icon(
              onPressed: scan.isComplete ? null : _cancelAttendance,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel attendance'),
            ),
            const SizedBox(height: Spacing.sm),
          ],
        ),
      ),
    );
  }
}

/// Review each student and explicitly save the teacher-approved state.
class AttendanceResultsScreen extends ConsumerStatefulWidget {
  const AttendanceResultsScreen({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<AttendanceResultsScreen> createState() =>
      _AttendanceResultsScreenState();
}

class _AttendanceResultsScreenState
    extends ConsumerState<AttendanceResultsScreen> {
  bool _saving = false;

  Future<void> _save() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save attendance?'),
        content: const Text(
          'Students still marked Not Detected will be recorded as absent.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Review'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save attendance'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(attendanceControllerProvider.notifier)
          .finalize(widget.sessionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Attendance saved.')));
      context.goNamed(AppRoutes.teacherHome);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to save attendance. Your local data is still safe.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cancelReview() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel attendance?'),
        content: const Text(
          'This session will be kept as cancelled and will not update attendance history.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep reviewing'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel attendance'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref
          .read(attendanceControllerProvider.notifier)
          .cancel(widget.sessionId);
      if (mounted) context.goNamed(AppRoutes.teacherAttendance);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to cancel attendance.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflow = ref.watch(attendanceControllerProvider);
    final session = ref
        .watch(attendanceSessionByIdProvider(widget.sessionId))
        .asData
        ?.value;
    final canReview = session?.status == AttendanceSessionStatus.review;
    final recordsAsync = ref.watch(attendanceRecordsProvider(widget.sessionId));
    final studentsAsync = ref.watch(
      attendanceRecordStudentsProvider(widget.sessionId),
    );
    return PageScaffold(
      title:
          session?.status == AttendanceSessionStatus.completed ||
              session?.status == AttendanceSessionStatus.cancelled
          ? 'Session details'
          : 'Attendance results',
      showBack: true,
      trailing: IconButton(
        tooltip: session?.status == AttendanceSessionStatus.cancelled
            ? 'Cancelled sessions cannot be exported'
            : 'Export report',
        onPressed: session?.status == AttendanceSessionStatus.cancelled
            ? null
            : () => exportReportFlow(
                context: context,
                export: (format, action) => ref
                    .read(reportExportControllerProvider.notifier)
                    .export(
                      request: AttendanceSessionRequest(widget.sessionId),
                      format: format,
                      action: action,
                    ),
              ),
        icon: const Icon(Icons.ios_share_outlined),
      ),
      body: recordsAsync.when(
        data: (records) => studentsAsync.when(
          data: (students) {
            final present = records
                .where(
                  (record) =>
                      record.recordStatus == AttendanceRecordStatus.present,
                )
                .length;
            final manualPresent = records
                .where(
                  (record) =>
                      record.recordStatus ==
                      AttendanceRecordStatus.manualPresent,
                )
                .length;
            final manualAbsent = records
                .where(
                  (record) =>
                      record.recordStatus ==
                      AttendanceRecordStatus.manualAbsent,
                )
                .length;
            final notDetected = records
                .where(
                  (record) =>
                      record.recordStatus == AttendanceRecordStatus.notDetected,
                )
                .length;
            final absent = records
                .where(
                  (record) =>
                      record.recordStatus == AttendanceRecordStatus.absent,
                )
                .length;
            final studentById = {
              for (final student in students) student.id: student,
            };
            final studentRows = <Widget>[];
            for (final record in records) {
              final student = studentById[record.studentId];
              if (student == null) continue;
              final status = record.isPresent
                  ? AttendanceStatus.present
                  : record.recordStatus == AttendanceRecordStatus.notDetected
                  ? AttendanceStatus.pending
                  : AttendanceStatus.absent;
              final statusLabel = switch (record.recordStatus) {
                AttendanceRecordStatus.manualPresent => 'Manual Present',
                AttendanceRecordStatus.manualAbsent => 'Manual Absent',
                AttendanceRecordStatus.present => 'Present',
                AttendanceRecordStatus.notDetected => 'Not detected',
                AttendanceRecordStatus.absent => 'Absent',
                null => 'Not detected',
              };
              studentRows.add(
                PersonListTile(
                  name: student.name,
                  subtitle: student.studentNumber,
                  status: status,
                  trailing: StatusPill(status: status, label: statusLabel),
                  onTap: canReview
                      ? () => ref
                            .read(
                              attendanceRecordsProvider(widget.sessionId)
                                  .notifier,
                            )
                            .toggleStudent(student.id)
                      : null,
                ),
              );
              studentRows.add(const Divider(height: 1));
            }
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(
                      top: Spacing.sm,
                      bottom: Spacing.md,
                    ),
                    children: [
                      if (canReview &&
                          workflow.sessionId == widget.sessionId &&
                          workflow.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: SectionCard(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning_amber_outlined,
                                  color: AppColors.warning,
                                ),
                                const SizedBox(width: Spacing.sm),
                                Expanded(child: Text(workflow.error!)),
                              ],
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.md),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            const gap = Spacing.sm;
                            final cardWidth =
                                (constraints.maxWidth - gap * 2) / 3;
                            final cards = [
                              MetricStatCard(
                                label: 'Present',
                                value: '$present',
                                icon: Icons.check_circle_outline,
                                color: AppColors.success,
                              ),
                              MetricStatCard(
                                label: 'Not detected',
                                value: '$notDetected',
                                icon: Icons.help_outline,
                                color: AppColors.warning,
                              ),
                              MetricStatCard(
                                label: 'Absent',
                                value: '$absent',
                                icon: Icons.person_off_outlined,
                                color: AppColors.danger,
                              ),
                              MetricStatCard(
                                label: 'Manual present',
                                value: '$manualPresent',
                                icon: Icons.person_add_alt_1_outlined,
                              ),
                              MetricStatCard(
                                label: 'Manual absent',
                                value: '$manualAbsent',
                                icon: Icons.person_remove_outlined,
                              ),
                            ];
                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                for (final card in cards)
                                  SizedBox(width: cardWidth, child: card),
                              ],
                            );
                          },
                        ),
                      ),
                      SectionCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.sm,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: Text(
                                'Tap a student to mark them present or absent. Manual changes are labeled.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (present + manualPresent == 0 && canReview)
                        Padding(
                          padding: const EdgeInsets.only(top: Spacing.sm),
                          child: SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'No student devices detected',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                const SizedBox(height: Spacing.xs),
                                const Text(
                                  'Make sure student devices are nearby, registered, and Bluetooth is enabled.',
                                ),
                                const SizedBox(height: Spacing.sm),
                                OutlinedButton.icon(
                                  onPressed: () => context.pushNamed(
                                    AppRoutes.bleScanner,
                                    pathParameters: {
                                      'sessionId': widget.sessionId,
                                    },
                                  ),
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Scan Again'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: Spacing.sm),
                      ...studentRows,
                    ],
                  ),
                ),
                if (canReview) ...[
                  TextButton.icon(
                    onPressed: _saving ? null : _cancelReview,
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancel attendance'),
                  ),
                  PrimaryActionButton(
                    label: _saving ? 'Saving...' : 'Save attendance',
                    icon: Icons.check,
                    onPressed: _saving ? null : _save,
                  ),
                ],
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
          data: (sessions) => sessions.isEmpty
              ? const HelpfulEmptyState(
                  title: 'No attendance records yet',
                  message:
                      'Attendance sessions for your classes will appear here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(
                    top: Spacing.md,
                    bottom: Spacing.xl,
                  ),
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
          final absent = records
              .where(
                (record) =>
                    record.recordStatus == AttendanceRecordStatus.absent ||
                    record.recordStatus == AttendanceRecordStatus.manualAbsent,
              )
              .length;
          final pending = records
              .where(
                (record) =>
                    record.recordStatus == AttendanceRecordStatus.notDetected,
              )
              .length;
          return SectionCard(
            child: InkWell(
              borderRadius: BorderRadius.circular(Radii.card),
              onTap: () => context.pushNamed(
                session.status == AttendanceSessionStatus.scanning
                    ? AppRoutes.bleScanner
                    : AppRoutes.attendanceResults,
                pathParameters: {'sessionId': session.id},
              ),
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
                      StatusPill(
                        status:
                            session.status == AttendanceSessionStatus.completed
                            ? AttendanceStatus.registered
                            : AttendanceStatus.pending,
                        label: switch (session.status) {
                          AttendanceSessionStatus.completed => 'Saved',
                          AttendanceSessionStatus.cancelled => 'Cancelled',
                          AttendanceSessionStatus.review => 'Needs review',
                          AttendanceSessionStatus.scanning => 'In progress',
                        },
                      ),
                      IconButton(
                        tooltip:
                            session.status ==
                                    AttendanceSessionStatus.scanning ||
                                session.status ==
                                    AttendanceSessionStatus.cancelled
                            ? 'Export unavailable for this session'
                            : 'Export report',
                        onPressed:
                            session.status ==
                                    AttendanceSessionStatus.scanning ||
                                session.status ==
                                    AttendanceSessionStatus.cancelled
                            ? null
                            : () => exportReportFlow(
                                context: context,
                                export: (format, action) => ref
                                    .read(
                                      reportExportControllerProvider.notifier,
                                    )
                                    .export(
                                      request: AttendanceSessionRequest(
                                        session.id,
                                      ),
                                      format: format,
                                      action: action,
                                    ),
                              ),
                        icon: const Icon(Icons.ios_share_outlined),
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
                          value: '$absent',
                          color: AppColors.danger,
                        ),
                      ),
                      Expanded(
                        child: _HistoryMetric(
                          label: 'Not detected',
                          value: '$pending',
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
                    ? const HelpfulEmptyState(
                        title: 'No attendance records yet',
                        message: 'Your attendance sessions will appear here after your teacher records attendance.',
                      )
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
                                : record.recordStatus ==
                                      AttendanceRecordStatus.notDetected
                                ? AttendanceStatus.pending
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
