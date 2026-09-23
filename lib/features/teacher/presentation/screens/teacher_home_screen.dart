import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../classes/presentation/providers/class_provider.dart';
import '../../../classes/presentation/screens/class_screens.dart';
import '../providers/teacher_provider.dart';

/// Teacher dashboard with today's class and attendance summary.
class TeacherHomeScreen extends ConsumerWidget {
  const TeacherHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherAsync = ref.watch(teacherProvider);
    final classesAsync = ref.watch(classListProvider);
    final sessionAsync = ref.watch(todaySessionProvider);
    final historyAsync = ref.watch(attendanceHistoryProvider);
    return PageScaffold(
      title: 'Home',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: Spacing.md),
            teacherAsync.when(
              data: (teacher) => Text(
                'Good morning, ${teacher.name.split(' ').first}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text(
                'Welcome back',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Here is what is happening in your classes today.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: Spacing.lg),
            sessionAsync.when(
              data: (session) => ref
                  .watch(attendanceRecordsProvider(session.id))
                  .when(
                    data: (records) {
                      final present = records
                          .where((record) => record.isPresent)
                          .length;
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final columns = constraints.maxWidth < 420 ? 2 : 3;
                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: Spacing.sm,
                            mainAxisSpacing: Spacing.sm,
                            childAspectRatio: columns == 2 ? 1.25 : 1.08,
                            children: [
                              MetricStatCard(
                                label: 'Present today',
                                value: '$present',
                                icon: Icons.check_circle_outline,
                                color: AppColors.success,
                              ),
                              MetricStatCard(
                                label: 'Absent today',
                                value: '${records.length - present}',
                                icon: Icons.person_off_outlined,
                                color: AppColors.danger,
                              ),
                              MetricStatCard(
                                label: 'Sessions',
                                value:
                                    historyAsync.value?.length.toString() ??
                                    '—',
                                icon: Icons.event_available_outlined,
                                color: AppColors.primary,
                              ),
                            ],
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => const _InlineError(
                      message: 'Attendance summary is unavailable.',
                    ),
                  ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => const _InlineError(
                message: 'Today’s session is unavailable.',
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Today’s classes',
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
            classesAsync.when(
              data: (classes) => Column(
                children: classes
                    .map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(bottom: Spacing.sm),
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
            SectionCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.bluetooth_connected,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ready to take attendance?',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          'Start a BLE scan for Grade 12 - STEM A.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Start scan',
                    onPressed: () => sessionAsync.whenData(
                      (session) => context.pushNamed(
                        AppRoutes.bleScanner,
                        pathParameters: {'sessionId': session.id},
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                  ),
                ],
              ),
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
