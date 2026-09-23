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
    body: ref
        .watch(classListProvider)
        .when(
          data: (classes) => ListView.separated(
            padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xl),
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
    final session = sessionsAsync.value
        ?.where((item) => item.classId == classId)
        .firstOrNull;
    return PageScaffold(
      title: 'Class details',
      showBack: true,
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
                                        label: 'Absent',
                                        value:
                                            '${records.length - presentCount}',
                                        icon: Icons.person_off_outlined,
                                        color: AppColors.danger,
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
                      label: 'Start attendance scan',
                      icon: Icons.bluetooth_searching,
                      onPressed: session == null
                          ? null
                          : () {
                              context.pushNamed(
                                AppRoutes.bleScanner,
                                pathParameters: {'sessionId': session.id},
                              );
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
class StudentListScreen extends ConsumerWidget {
  const StudentListScreen({super.key, required this.classId});

  final String classId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PageScaffold(
    title: 'Student list',
    showBack: true,
    body: ref
        .watch(classRosterProvider(classId))
        .when(
          data: (students) => Column(
            children: [
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
                child: ListView.separated(
                  padding: const EdgeInsets.only(bottom: Spacing.xl),
                  itemCount: students.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return PersonListTile(
                      name: student.name,
                      subtitle: student.studentNumber,
                      status: student.deviceRegistered
                          ? AttendanceStatus.registered
                          : AttendanceStatus.unverified,
                    );
                  },
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const _ClassError(),
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
