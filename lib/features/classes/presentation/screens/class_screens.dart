import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/iterable_extensions.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../providers/class_provider.dart';
import '../../../../domain/models.dart';
import '../../../../domain/repositories.dart';

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
    return PageScaffold(
      title: 'Class details',
      showBack: true,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                  content: const Text('This action cannot be undone.'),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to delete this class.'),
                    ),
                  );
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
                            .where((item) => item.classId == classId)
                            .firstOrNull;
                        if (classSession == null) {
                          return const _ClassError(
                            message: 'No attendance session has been recorded for this class.',
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
                                          AttendanceRecordStatus.unverified,
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
                                            classSession.status == 'Completed'
                                            ? 'Absent'
                                            : 'Not confirmed',
                                        value:
                                            classSession.status == 'Completed'
                                            ? '$absentCount'
                                            : '$pendingCount',
                                        icon: classSession.status == 'Completed'
                                            ? Icons.person_off_outlined
                                            : Icons.help_outline,
                                        color:
                                            classSession.status == 'Completed'
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
                              final accepted = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Start attendance?'),
                                  content: Text(
                                    '${section.name}\n${section.studentCount} students\n\nMake sure student devices are nearby and Bluetooth is enabled.',
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
                                      child: const Text('Start scan'),
                                    ),
                                  ],
                                ),
                              );
                              if (accepted != true) return;
                              try {
                                final created = await ref
                                    .read(
                                      attendanceActionControllerProvider
                                          .notifier,
                                    )
                                    .start(classId);
                                if (context.mounted) {
                                  context.pushNamed(
                                    AppRoutes.bleScanner,
                                    pathParameters: {'sessionId': created.id},
                                  );
                                }
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        error is RepositoryException
                                            ? error.message
                                            : 'Unable to start attendance.',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                    const SizedBox(height: Spacing.sm),
                    SecondaryActionButton(
                      label: 'View student list',
                      icon: Icons.groups_outlined,
                      onPressed: () => context.pushNamed(
                        AppRoutes.teacherStudentList,
                        pathParameters: {'classId': classId},
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    SecondaryActionButton(
                      label: 'Attendance history',
                      icon: Icons.history,
                      onPressed: () =>
                          context.goNamed(AppRoutes.teacherAttendance),
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          _StudentEditorSheet(classId: widget.classId, student: student),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to remove this student.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: 'Student list',
    showBack: true,
    trailing: IconButton(
      tooltip: 'Add student',
      onPressed: () => _edit(null),
      icon: const Icon(Icons.person_add_alt_1_outlined),
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
                              onTap: () => _actions(student),
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

class _StudentEditorSheet extends ConsumerStatefulWidget {
  const _StudentEditorSheet({required this.classId, this.student});
  final String classId;
  final Student? student;

  @override
  ConsumerState<_StudentEditorSheet> createState() =>
      _StudentEditorSheetState();
}

class _StudentEditorSheetState extends ConsumerState<_StudentEditorSheet> {
  late final _name = TextEditingController(text: widget.student?.name ?? '');
  late final _number = TextEditingController(
    text: widget.student?.studentNumber ?? '',
  );
  final _bleUuid = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _number.dispose();
    _bleUuid.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _number.text.trim().isEmpty) {
      setState(() => _error = 'Enter the student name and number.');
      return;
    }
    try {
      final controller = ref.read(studentManagementControllerProvider.notifier);
      if (widget.student == null) {
        await controller.add(
          widget.classId,
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
        );
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.student == null ? 'Student added.' : 'Student updated.',
            ),
          ),
        );
      }
    } on RepositoryException catch (error) {
      setState(() => _error = error.message);
    } catch (_) {
      setState(() => _error = 'Unable to save this student.');
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      Spacing.md,
      Spacing.lg,
      Spacing.md,
      MediaQuery.viewInsetsOf(context).bottom + Spacing.lg,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.student == null ? 'Add student' : 'Edit student',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: Spacing.md),
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
              labelText: 'Student device sharing code (optional)',
              helperText: 'Enter the code shown on the student’s Device tab.',
              prefixIcon: Icon(Icons.bluetooth_outlined),
            ),
          ),
        ],
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
          label: ref.watch(studentManagementControllerProvider)
              ? 'Saving...'
              : 'Save student',
          onPressed: ref.watch(studentManagementControllerProvider)
              ? null
              : _save,
        ),
      ],
    ),
  );
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
