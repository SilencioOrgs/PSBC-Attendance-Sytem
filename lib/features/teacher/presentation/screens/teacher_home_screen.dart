import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/utils/iterable_extensions.dart';
import '../../../../domain/models.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../attendance/presentation/providers/attendance_access_provider.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../classes/presentation/providers/class_provider.dart';
import '../../../classes/presentation/screens/class_screens.dart';
import '../providers/teacher_provider.dart';

class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacher = ref.watch(teacherProvider);
    final classes = ref.watch(classListProvider);
    final sessions = ref.watch(attendanceHistoryProvider);
    final hasAttendanceAccess =
        ref.watch(attendanceAccessAvailableProvider).value ?? false;
    return PageScaffold(
      title: 'Home',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            teacher.when(
              data: (profile) => Text(
                'Good morning, ${profile.name.split(' ').first}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text(
                'Welcome',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Manage your classes and attendance.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: Spacing.md),
            SecondaryActionButton(
              label: 'Share Attendance Access',
              icon: Icons.qr_code_2,
              onPressed: () => context.push('/teacher/share-attendance'),
            ),
            const SizedBox(height: Spacing.sm),
            SecondaryActionButton(
              label: 'Add Student',
              icon: Icons.person_add_alt_1_outlined,
              onPressed: () => context.push('/teacher/students/add'),
            ),
            if (hasAttendanceAccess)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () async {
                    await ref
                        .read(applicationSessionProvider)
                        .selectAttendanceOfficer();
                    if (context.mounted) context.go('/attendance-officer');
                  },
                  icon: const Icon(Icons.fact_check_outlined),
                  label: const Text('Open Attendance Officer'),
                ),
              ),
            const SizedBox(height: Spacing.lg),
            sessions.when(
              data: (list) {
                if (list.isEmpty) return const SizedBox.shrink();
                final completed = list
                    .where(
                      (session) =>
                          session.status == AttendanceSessionStatus.completed,
                    )
                    .toList();
                if (completed.isEmpty) return const SizedBox.shrink();
                final session = completed.first;
                return ref
                    .watch(attendanceRecordsProvider(session.id))
                    .when(
                      data: (records) {
                        final present = records
                            .where((record) => record.isPresent)
                            .length;
                        return Row(
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
                                label: 'Other statuses',
                                value: '${records.length - present}',
                                icon: Icons.fact_check_outlined,
                                color: AppColors.warning,
                              ),
                            ),
                            const SizedBox(width: Spacing.sm),
                            Expanded(
                              child: MetricStatCard(
                                label: 'Sessions',
                                value: '${completed.length}',
                                icon: Icons.event_available_outlined,
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => const LinearProgressIndicator(),
                      error: (error, stack) => const _InlineError(
                        message: 'Attendance summary is unavailable.',
                      ),
                    );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => const _InlineError(
                message: 'Attendance history is unavailable.',
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Classes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton(
                  onPressed: () => context.goNamed(AppRoutes.teacherClasses),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            classes.when(
              data: (list) => list.isEmpty
                  ? HelpfulEmptyState(
                      title: 'No class yet',
                      message: "You haven't created a class yet. Create one to begin taking attendance.",
                      actionLabel: 'Create Class',
                      onAction: () =>
                          context.pushNamed(AppRoutes.teacherClassCreate),
                    )
                  : Column(
                      children: list
                          .map(
                            (section) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: Spacing.sm,
                              ),
                              child: ClassSectionCard(
                                section: section,
                                onTap: () => context.pushNamed(
                                  AppRoutes.teacherClassDetails,
                                  pathParameters: {'classId': section.id},
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  const _InlineError(message: 'Class list is unavailable.'),
            ),
            const SizedBox(height: Spacing.md),
            classes.when(
              data: (list) {
                final active = sessions.value
                    ?.where(
                      (session) =>
                          session.status == AttendanceSessionStatus.scanning ||
                          session.status == AttendanceSessionStatus.review,
                    )
                    .firstOrNull;
                final needsReview =
                    active?.status == AttendanceSessionStatus.review;
                final label = active != null
                    ? needsReview
                          ? 'Review Attendance'
                          : 'Continue Attendance'
                    : list.isEmpty
                    ? 'Create Class'
                    : 'Start Attendance';
                return SectionCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bluetooth_searching,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              active != null
                                  ? needsReview
                                        ? 'Attendance needs review'
                                        : 'Attendance is in progress'
                                  : list.isEmpty
                                  ? 'Create a class to begin'
                                  : 'Ready to take attendance?',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              active?.title ??
                                  (list.isEmpty
                                      ? 'Your class list is empty.'
                                      : 'Choose a class to start a local BLE scan.'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: label,
                        onPressed: () {
                          if (active != null) {
                            context.pushNamed(
                              needsReview
                                  ? AppRoutes.attendanceResults
                                  : AppRoutes.bleScanner,
                              pathParameters: {'sessionId': active.id},
                            );
                          } else if (list.isEmpty) {
                            context.pushNamed(AppRoutes.teacherClassCreate);
                          } else {
                            context.goNamed(AppRoutes.teacherClasses);
                          }
                        },
                        icon: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => SectionCard(
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: AppColors.warning),
        const SizedBox(width: Spacing.sm),
        Expanded(child: Text(message)),
      ],
    ),
  );
}
