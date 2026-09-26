import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/ble_identity.dart';
import '../../../../core/utils/iterable_extensions.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../attendance/presentation/providers/attendance_controller.dart';
import '../../../device/presentation/providers/device_provider.dart';
import '../providers/class_provider.dart';
import '../../../../domain/models.dart';
import '../../../../domain/attendance_window_policy.dart';
import '../../../../domain/repositories.dart';
import '../../../reports/models/report_models.dart';
import '../../../reports/presentation/providers/report_export_provider.dart';
import '../../../reports/presentation/widgets/export_report_sheet.dart';

/// Reusable summary card for one class section.
class ClassSectionCard extends StatelessWidget {
  const ClassSectionCard({
    super.key,
    required this.section,
    required this.onTap,
  });

  final ClassSection section;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(Radii.card),
    child: SectionCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(Radii.control),
            ),
            child: const Icon(
              Icons.menu_book_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  section.subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.md,
                  runSpacing: Spacing.xs,
                  children: [
                    _CardDetail(
                      icon: Icons.groups_outlined,
                      label: '${section.studentCount} students',
                    ),
                    _CardDetail(
                      icon: Icons.schedule,
                      label: section.schedule.split(', ').last,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          const Icon(Icons.chevron_right, color: AppColors.muted),
        ],
      ),
    ),
  );
}

class _CardDetail extends StatelessWidget {
  const _CardDetail({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 14, color: AppColors.muted),
      const SizedBox(width: Spacing.xs),
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: AppColors.muted),
      ),
    ],
  );
}

/// Teacher Classes tab.
class TeacherClassesScreen extends ConsumerWidget {
  const TeacherClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => PageScaffold(
    title: 'Classes',
    trailing: IconButton(
      tooltip: 'Create class',
      onPressed: () => context.pushNamed(AppRoutes.teacherClassCreate),
      icon: const Icon(Icons.add),
    ),
    body: ref
        .watch(classListProvider)
        .when(
          data: (classes) => classes.isEmpty
              ? HelpfulEmptyState(
                  title: 'No classes yet',
                  message: 'Create your first class to start managing students and attendance.',
                  actionLabel: 'Create Class',
                  onAction: () =>
                      context.pushNamed(AppRoutes.teacherClassCreate),
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(
                    top: Spacing.md,
                    bottom: Spacing.xl,
                  ),
                  itemCount: classes.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: Spacing.sm),
                  itemBuilder: (context, index) {
                    final section = classes[index];
                    return ClassSectionCard(
                      section: section,
                      onTap: () => context.pushNamed(
                        AppRoutes.teacherClassDetails,
                        pathParameters: {'classId': section.id},
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const _ClassError(),
        ),
  );
}

/// Detail page for a class section.
class ClassDetailsScreen extends ConsumerWidget {
  const ClassDetailsScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(attendanceHistoryProvider);
    final hasCompletedSessions =
        sessionsAsync.asData?.value.any(
          (item) =>
              item.classOfferingId == classId &&
              item.status == AttendanceSessionStatus.completed,
        ) ==
        true;
    return PageScaffold(
      title: 'Class details',
      showBack: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Export class attendance',
            onPressed: hasCompletedSessions
                ? () => exportReportFlow(
                    context: context,
                    export: (format, action) => ref
                        .read(reportExportControllerProvider.notifier)
                        .export(
                          request: ClassAttendanceRequest(classId),
                          format: format,
                          action: action,
                        ),
                  )
                : null,
            icon: const Icon(Icons.ios_share_outlined),
          ),
          IconButton(
            tooltip: 'Edit class',
            onPressed: () => context.pushNamed(
              AppRoutes.teacherClassEdit,
              pathParameters: {'classId': classId},
            ),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Delete class',
            onPressed: () async {
              final accepted = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete class?'),
                  content: const Text(
                    'Deleting this class removes its enrollments and all of its attendance sessions and records from this device. This cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
              if (accepted != true) return;
              try {
                await ref
                    .read(classRemovalControllerProvider.notifier)
                    .remove(classId);
                if (context.mounted) context.goNamed(AppRoutes.teacherClasses);
              } catch (_) {
                if (context.mounted) {
                  AppFeedback.error(context, 'Unable to delete this class.');
                }
              }
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: ref
          .watch(classByIdProvider(classId))
          .when(
            data: (section) {
              if (section == null) {
                return const _ClassError(
                  message: 'This class could not be found.',
                );
              }
              return SingleChildScrollView(
                padding: const EdgeInsets.only(
                  top: Spacing.md,
                  bottom: Spacing.xl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            section.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            section.subject,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.muted),
                          ),
                          const SizedBox(height: Spacing.lg),
                          _DetailLine(
                            icon: Icons.schedule,
                            value: section.schedule,
                          ),
                          const SizedBox(height: Spacing.sm),
                          _DetailLine(
                            icon: Icons.location_on_outlined,
                            value: section.room,
                          ),
                          const SizedBox(height: Spacing.sm),
                          _DetailLine(
                            icon: Icons.groups_outlined,
                            value: '${section.studentCount} enrolled students',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    Text(
                      'Attendance overview',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: Spacing.sm),
                    sessionsAsync.when(
                      data: (sessions) {
                        final classSession = sessions
                            .where(
                              (item) =>
                                  item.classOfferingId == classId &&
                                  item.status ==
                                      AttendanceSessionStatus.completed,
                            )
                            .firstOrNull;
                        if (classSession == null) {
                          return const HelpfulEmptyState(
                            title: 'No attendance data',
                            message: 'There are no completed attendance sessions for this class yet.',
                          );
                        }
                        return ref
                            .watch(attendanceRecordsProvider(classSession.id))
                            .when(
                              data: (records) {
                                final presentCount = records
                                    .where((record) => record.isPresent)
                                    .length;
                                final absentCount = records
                                    .where(
                                      (record) =>
                                          record.recordStatus ==
                                              AttendanceRecordStatus.absent ||
                                          record.recordStatus ==
                                              AttendanceRecordStatus
                                                  .manualAbsent,
                                    )
                                    .length;
                                final pendingCount = records
                                    .where(
                                      (record) =>
                                          record.recordStatus ==
                                          AttendanceRecordStatus.notDetected,
                                    )
                                    .length;
                                return Row(
                                  children: [
                                    Expanded(
                                      child: MetricStatCard(
                                        label: 'Present',
                                        value: '$presentCount',
                                        icon: Icons.check_circle_outline,
                                        color: AppColors.success,
                                      ),
                                    ),
                                    const SizedBox(width: Spacing.sm),
                                    Expanded(
                                      child: MetricStatCard(
                                        label:
                                            classSession.status ==
                                                AttendanceSessionStatus
                                                    .completed
                                            ? 'Absent'
                                            : 'Not confirmed',
                                        value:
                                            classSession.status ==
                                                AttendanceSessionStatus
                                                    .completed
                                            ? '$absentCount'
                                            : '$pendingCount',
                                        icon:
                                            classSession.status ==
                                                AttendanceSessionStatus
                                                    .completed
                                            ? Icons.person_off_outlined
                                            : Icons.help_outline,
                                        color:
                                            classSession.status ==
                                                AttendanceSessionStatus
                                                    .completed
                                            ? AppColors.danger
                                            : AppColors.warning,
                                      ),
                                    ),
                                  ],
                                );
                              },
                              loading: () => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              error: (error, stack) => const _ClassError(
                                message: 'Attendance could not be loaded.',
                              ),
                            );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (error, stack) => const _ClassError(
                        message: 'Attendance session could not be loaded.',
                      ),
                    ),
                    const SizedBox(height: Spacing.lg),
                    PrimaryActionButton(
                      label: 'Start attendance',
                      icon: Icons.bluetooth_searching,
                      onPressed: section.studentCount == 0
                          ? null
                          : () async {
                              final window = const AttendanceWindowPolicy()
                                  .evaluate(section, DateTime.now());
                              final override = !window.isScheduled;
                              final accepted = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(
                                    override
                                        ? 'Attendance is outside the schedule.'
                                        : 'Start attendance?',
                                  ),
                                  content: Text(
                                    override
                                        ? '${section.subject} is scheduled ${section.schedule} on ${section.scheduleDays.map((day) => day.name).join(', ')}.${window.nextAvailableAt == null ? '' : '\nNext available: ${TimeOfDay.fromDateTime(window.nextAvailableAt!).format(context)}'}\n\nStarting anyway will be recorded as a teacher override.'
                                        : '${section.subject}\n${section.studentCount} students\n\nMake sure student devices are nearby and Bluetooth is enabled.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text(
                                        override
                                            ? 'Start Anyway'
                                            : 'Start scan',
                                      ),
                                    ),
                                  ],
                                ),
                              );
                              if (accepted != true) return;
                              try {
                                final created = await ref
                                    .read(attendanceControllerProvider.notifier)
                                    .prepareSession(
                                      classId,
                                      manualOverride: override,
                                    );
                                if (context.mounted) {
                                  AppFeedback.success(
                                    context,
                                    'Attendance session started.',
                                  );
                                  context.pushNamed(
                                    AppRoutes.bleScanner,
                                    pathParameters: {'sessionId': created.id},
                                  );
                                }
                              } catch (error) {
                                if (context.mounted) {
                                  AppFeedback.error(
                                    context,
                                    error is RepositoryException
                                        ? error.message
                                        : 'Unable to start attendance.',
                                  );
                                }
                              }
                            },
                    ),
                    const SizedBox(height: Spacing.sm),
                    SectionCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.groups_outlined),
                            title: const Text('Students'),
                            subtitle: Text('${section.studentCount} enrolled'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.pushNamed(
                              AppRoutes.teacherStudentList,
                              pathParameters: {'classId': classId},
                            ),
                          ),
                          const Divider(
                            height: 1,
                            indent: Spacing.md,
                            endIndent: Spacing.md,
                          ),
                          ListTile(
                            leading: const Icon(Icons.qr_code_2),
                            title: const Text('Share attendance access'),
                            subtitle: const Text('Choose one or more subjects'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.pushNamed(
                              AppRoutes.teacherAttendanceAccessQr,
                              pathParameters: {'classId': classId},
                            ),
                          ),
                          const Divider(
                            height: 1,
                            indent: Spacing.md,
                            endIndent: Spacing.md,
                          ),
                          ListTile(
                            leading: const Icon(Icons.history),
                            title: const Text('Attendance history'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () =>
                                context.goNamed(AppRoutes.teacherAttendance),
                          ),
                        ],
                      ),
                    ),
                    if (section.studentCount == 0) ...[
                      const SizedBox(height: Spacing.sm),
                      const Text(
                        'Add students to this class before starting attendance.',
                      ),
                    ],
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const _ClassError(),
          ),
    );
  }
}

/// Teacher view of a student's attendance history and summary.
class StudentDetailsScreen extends ConsumerWidget {
  const StudentDetailsScreen({
    super.key,
    required this.classId,
    required this.studentId,
  });

  final String classId;
  final String studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(
      studentAttendanceReportProvider((classId: classId, studentId: studentId)),
    );
    final report = reportAsync.asData?.value;
    return PageScaffold(
      title: 'Student details',
      showBack: true,
      trailing: IconButton(
        tooltip: report?.rows.isNotEmpty == true
            ? 'Export student attendance'
            : 'No attendance records to export',
        onPressed: report?.rows.isNotEmpty == true
            ? () => exportReportFlow(
                context: context,
                export: (format, action) => ref
                    .read(reportExportControllerProvider.notifier)
                    .export(
                      request: StudentAttendanceRequest(
                        classId: classId,
                        studentId: studentId,
                      ),
                      format: format,
                      action: action,
                    ),
              )
            : null,
        icon: const Icon(Icons.ios_share_outlined),
      ),
      body: reportAsync.when(
        data: (value) => Column(
          children: [
            const SizedBox(height: Spacing.sm),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.student.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(value.student.studentNumber),
                  Text(
                    '${value.section.name} · ${value.section.subject}',
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Spacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = Spacing.sm;
                final width = (constraints.maxWidth - gap) / 2;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: width,
                      child: MetricStatCard(
                        label: 'Total sessions',
                        value: '${value.totalSessions}',
                        icon: Icons.event_note_outlined,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: MetricStatCard(
                        label: 'Attendance',
                        value: '${value.attendancePercent.toStringAsFixed(1)}%',
                        icon: Icons.percent,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: MetricStatCard(
                        label: 'Present',
                        value: '${value.present}',
                        icon: Icons.check_circle_outline,
                        color: AppColors.success,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: MetricStatCard(
                        label: 'Absent',
                        value: '${value.absent}',
                        icon: Icons.person_off_outlined,
                        color: AppColors.danger,
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: MetricStatCard(
                        label: 'Not detected',
                        value: '${value.notDetected}',
                        icon: Icons.help_outline,
                        color: AppColors.warning,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: Spacing.lg),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Attendance history',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Expanded(
              child: value.rows.isEmpty
                  ? const HelpfulEmptyState(
                      title: 'No attendance records',
                      message: 'This student has no completed attendance records for this class.',
                    )
                  : ListView.separated(
                      itemCount: value.rows.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final row = value.rows[index];
                        final attendance = row.session?.startedAt;
                        final status = switch (row.status) {
                          AttendanceRecordStatus.present ||
                          AttendanceRecordStatus.manualPresent =>
                            AttendanceStatus.present,
                          AttendanceRecordStatus.absent ||
                          AttendanceRecordStatus.manualAbsent =>
                            AttendanceStatus.absent,
                          AttendanceRecordStatus.notDetected =>
                            AttendanceStatus.pending,
                        };
                        return PersonListTile(
                          name: value.section.name,
                          subtitle: attendance == null
                              ? 'Session date unavailable'
                              : '${attendance.day}/${attendance.month}/${attendance.year}',
                          status: status,
                          trailing: StatusPill(
                            status: status,
                            label: row.statusLabel,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const _ClassError(
          message: 'Student attendance could not be loaded.',
        ),
      ),
    );
  }
}

/// Class roster with registration status for each student.
class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key, required this.classId});

  final String classId;

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen> {
  String _query = '';

  Future<void> _edit(Student? student) async {
    final classes = await ref.read(classRepositoryProvider).getClasses();
    final ownedIds = classes.map((offering) => offering.id).toSet();
    final memberships = student == null
        ? const <ClassSection>[]
        : await ref
              .read(classRepositoryProvider)
              .getStudentOfferings(student.id);
    final selectedOfferingIds = student == null
        ? {widget.classId}
        : memberships
              .map((offering) => offering.id)
              .where(ownedIds.contains)
              .toSet();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StudentEditorForm(
        classId: widget.classId,
        student: student,
        initialOfferingIds: selectedOfferingIds,
      ),
    );
  }

  Future<void> _actions(Student student) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit student'),
              onTap: () => Navigator.pop(context, 'edit'),
            ),
            ListTile(
              leading: Icon(
                student.deviceRegistered
                    ? Icons.phonelink_setup_outlined
                    : Icons.bluetooth_outlined,
              ),
              title: Text(
                student.deviceRegistered ? 'Replace device' : 'Register device',
              ),
              onTap: () => Navigator.pop(context, 'device'),
            ),
            if (student.deviceRegistered)
              ListTile(
                leading: const Icon(Icons.bluetooth_disabled),
                title: const Text('Remove device'),
                onTap: () => Navigator.pop(context, 'remove-device'),
              ),
            ListTile(
              leading: const Icon(Icons.person_remove_outlined),
              title: const Text('Remove from class'),
              onTap: () => Navigator.pop(context, 'remove'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'edit') {
      await _edit(student);
    }
    if (!mounted) return;
    if (action == 'device') {
      await _registerDevice(student);
      return;
    }
    if (action == 'remove-device') {
      await _removeDevice(student);
      return;
    }
    if (action == 'remove') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Remove student?'),
          content: const Text(
            'This student will no longer appear in this class.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      try {
        await ref
            .read(studentManagementControllerProvider.notifier)
            .remove(widget.classId, student.id);
      } catch (_) {
        if (mounted) {
          AppFeedback.error(context, 'Unable to remove this student.');
        }
      }
    }
  }

  Future<void> _registerDevice(Student student) async {
    if (student.deviceRegistered) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace registered device?'),
          content: const Text(
            'The old device will no longer be accepted for attendance.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }

    final code = TextEditingController();
    final name = TextEditingController(text: 'Student phone');
    String? error;
    try {
      final values = await showDialog<List<String>>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              student.deviceRegistered
                  ? 'Register replacement device'
                  : 'Register student device',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: code,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'BLE Service UUID',
                    helperText: 'Enter the UUID shown on the student device.',
                    errorText: error,
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Device name'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (normalizeBleIdentity(code.text) == null) {
                    setDialogState(
                      () => error = 'Enter a valid BLE Service UUID.',
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, [code.text, name.text]);
                },
                child: const Text('Save device'),
              ),
            ],
          ),
        ),
      );
      if (values == null || !mounted) return;
      final controller = ref.read(studentManagementControllerProvider.notifier);
      if (student.deviceRegistered) {
        await controller.replaceDevice(
          widget.classId,
          student.id,
          deviceName: values[1],
          bleUuid: values[0],
        );
      } else {
        await controller.registerDevice(
          widget.classId,
          student.id,
          deviceName: values[1],
          bleUuid: values[0],
        );
      }
      if (mounted) {
        AppFeedback.success(
          context,
          student.deviceRegistered
              ? 'Student device replaced.'
              : 'Student device registered.',
        );
      }
    } on RepositoryException catch (exception) {
      if (mounted) {
        AppFeedback.error(context, exception.message);
      }
    } catch (_) {
      if (mounted) {
        AppFeedback.error(context, 'Unable to register this device.');
      }
    } finally {
      code.dispose();
      name.dispose();
    }
  }

  Future<void> _removeDevice(Student student) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove registered device?'),
        content: const Text(
          'This device will no longer be accepted for attendance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove device'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;
    try {
      await ref
          .read(studentManagementControllerProvider.notifier)
          .removeDevice(widget.classId, student.id);
    } catch (_) {
      if (mounted) {
        AppFeedback.error(context, 'Unable to remove this device.');
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: 'Student list',
    showBack: true,
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip:
              ref
                      .watch(classRosterProvider(widget.classId))
                      .asData
                      ?.value
                      .isNotEmpty ==
                  true
              ? 'Export class roster'
              : 'No students enrolled',
          onPressed:
              ref
                      .watch(classRosterProvider(widget.classId))
                      .asData
                      ?.value
                      .isNotEmpty ==
                  true
              ? () => exportReportFlow(
                  context: context,
                  export: (format, action) => ref
                      .read(reportExportControllerProvider.notifier)
                      .export(
                        request: ClassRosterRequest(widget.classId),
                        format: format,
                        action: action,
                      ),
                )
              : null,
          icon: const Icon(Icons.ios_share_outlined),
        ),
        IconButton(
          tooltip: 'Add student',
          onPressed: () => _edit(null),
          icon: const Icon(Icons.person_add_alt_1_outlined),
        ),
      ],
    ),
    body: ref
        .watch(classRosterProvider(widget.classId))
        .when(
          data: (students) {
            final filtered = students
                .where(
                  (student) =>
                      student.name.toLowerCase().contains(
                        _query.toLowerCase(),
                      ) ||
                      student.studentNumber.toLowerCase().contains(
                        _query.toLowerCase(),
                      ),
                )
                .toList();
            if (students.isEmpty) {
              return HelpfulEmptyState(
                title: 'No students yet',
                message:
                    'Add students to this class before starting attendance.',
                actionLabel: 'Add Student',
                onAction: () => _edit(null),
              );
            }
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: Spacing.sm),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search name or student number',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () => setState(() => _query = ''),
                              icon: const Icon(Icons.close),
                            ),
                    ),
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    top: Spacing.sm,
                    bottom: Spacing.sm,
                  ),
                  child: SectionCard(
                    child: Row(
                      children: [
                        const Icon(
                          Icons.groups_outlined,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            '${students.length} enrolled students',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        const StatusPill(
                          status: AttendanceStatus.registered,
                          label: 'Roster',
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const HelpfulEmptyState(
                          title: 'No results found',
                          message: 'Try a different name or student number.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.only(bottom: Spacing.xl),
                          itemCount: filtered.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final student = filtered[index];
                            return PersonListTile(
                              name: student.name,
                              subtitle: student.studentNumber,
                              status: student.deviceRegistered
                                  ? AttendanceStatus.registered
                                  : AttendanceStatus.unverified,
                              onTap: () => context.pushNamed(
                                AppRoutes.teacherStudentDetails,
                                pathParameters: {
                                  'classId': widget.classId,
                                  'studentId': student.id,
                                },
                              ),
                              trailing: IconButton(
                                tooltip: 'Student actions',
                                onPressed: () => _actions(student),
                                icon: const Icon(Icons.more_vert),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const _ClassError(),
        ),
  );
}

class TeacherStudentRegistrationScreen extends StatelessWidget {
  const TeacherStudentRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: 'Add Student',
    showBack: true,
    body: StudentEditorForm(initialOfferingIds: const {}),
  );
}

class StudentEditorForm extends ConsumerStatefulWidget {
  const StudentEditorForm({
    super.key,
    this.classId,
    this.student,
    this.initialOfferingIds = const {},
  });

  final String? classId;
  final Student? student;
  final Set<String> initialOfferingIds;

  @override
  ConsumerState<StudentEditorForm> createState() => _StudentEditorFormState();
}

class _StudentEditorFormState extends ConsumerState<StudentEditorForm> {
  late final _name = TextEditingController(text: widget.student?.name ?? '');
  late final _number = TextEditingController(
    text: widget.student?.studentNumber ?? '',
  );
  final _bleUuid = TextEditingController();
  late final Set<String> _selectedOfferingIds = Set<String>.of(
    widget.initialOfferingIds,
  );
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _bleUuid.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final selectedOfferingIds = Set<String>.of(_selectedOfferingIds);
    if (_name.text.trim().isEmpty || _number.text.trim().isEmpty) {
      setState(() => _error = 'Enter the student name and number.');
      return;
    }
    if (widget.student == null && selectedOfferingIds.isEmpty) {
      setState(() => _error = 'Select at least one subject.');
      return;
    }
    try {
      final controller = ref.read(studentManagementControllerProvider.notifier);
      if (widget.student == null) {
        await controller.add(
          selectedOfferingIds,
          _name.text,
          _number.text,
          bleUuid: _bleUuid.text.trim().isEmpty ? null : _bleUuid.text.trim(),
        );
      } else {
        await controller.update(
          widget.classId,
          widget.student!.id,
          _name.text,
          _number.text,
          selectedOfferingIds,
        );
      }
      if (mounted) {
        AppFeedback.success(
          context,
          widget.student == null ? 'Student saved.' : 'Student updated.',
        );
        Navigator.pop(context);
      }
    } on RepositoryException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Unable to save this student.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(studentManagementControllerProvider);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.classId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: Text(
              widget.student == null ? 'Add student' : 'Edit student',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Full name'),
        ),
        const SizedBox(height: Spacing.md),
        TextField(
          controller: _number,
          decoration: const InputDecoration(labelText: 'Student number'),
        ),
        if (widget.student == null) ...[
          const SizedBox(height: Spacing.md),
          TextField(
            controller: _bleUuid,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(
              labelText: 'BLE Service UUID (optional)',
              helperText:
                  'Enter the registered device UUID once for this student.',
              prefixIcon: Icon(Icons.bluetooth_outlined),
            ),
          ),
        ] else
          Padding(
            padding: const EdgeInsets.only(top: Spacing.md),
            child: ref
                .watch(studentDeviceProvider(widget.student!.id))
                .when(
                  data: (device) => SectionCard(
                    child: Row(
                      children: [
                        Icon(
                          device == null
                              ? Icons.bluetooth_disabled
                              : Icons.bluetooth_connected,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Expanded(
                          child: Text(
                            device == null
                                ? 'No BLE device registered'
                                : 'BLE device registered · ${device.bleUuid}',
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stack) =>
                      const Text('BLE device status unavailable.'),
                ),
          ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'Subjects',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => setState(() {
                      _selectedOfferingIds
                        ..clear()
                        ..addAll(
                          ref
                                  .read(classListProvider)
                                  .asData
                                  ?.value
                                  .map((offering) => offering.id) ??
                              const <String>[],
                        );
                    }),
              child: const Text('Select All'),
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () => setState(_selectedOfferingIds.clear),
              child: const Text('Clear All'),
            ),
          ],
        ),
        ref
            .watch(classListProvider)
            .when(
              data: (offerings) => offerings.isEmpty
                  ? const Text(
                      'Create a class offering before registering a student.',
                    )
                  : SectionCard(
                      child: Column(
                        children: [
                          for (final offering in offerings)
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              value: _selectedOfferingIds.contains(offering.id),
                              title: Text(offering.subject),
                              subtitle: Text(offering.sectionCode),
                              onChanged: busy
                                  ? null
                                  : (selected) => setState(() {
                                      if (selected == true) {
                                        _selectedOfferingIds.add(offering.id);
                                      } else {
                                        _selectedOfferingIds.remove(
                                          offering.id,
                                        );
                                      }
                                    }),
                            ),
                        ],
                      ),
                    ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) =>
                  const Text('Class offerings are unavailable.'),
            ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.sm),
            child: Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: Spacing.md),
        PrimaryActionButton(
          label: busy ? 'Saving...' : 'Save student',
          onPressed: busy ? null : _save,
        ),
      ],
    );

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        MediaQuery.viewInsetsOf(context).bottom + Spacing.lg,
      ),
      child: content,
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppColors.muted),
      const SizedBox(width: Spacing.sm),
      Expanded(
        child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ),
    ],
  );
}

class _ClassError extends StatelessWidget {
  const _ClassError({this.message = 'Class information is unavailable.'});

  final String message;

  @override
  Widget build(BuildContext context) =>
      Center(child: SectionCard(child: Text(message)));
}
