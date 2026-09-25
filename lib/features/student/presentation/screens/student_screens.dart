import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../domain/models.dart';
import '../../../../domain/repositories.dart';
import '../../../attendance/presentation/providers/attendance_provider.dart';
import '../../../device/presentation/providers/device_provider.dart';
import '../providers/student_provider.dart';

/// First-run student registration form.
class StudentSetupScreen extends ConsumerStatefulWidget {
  const StudentSetupScreen({super.key});

  @override
  ConsumerState<StudentSetupScreen> createState() => _StudentSetupScreenState();
}

class _StudentSetupScreenState extends ConsumerState<StudentSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _numberController = TextEditingController();
  String? _studentNumberError;
  bool _isSubmitting = false;
  bool _registrationSubmitted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final student = await ref.read(currentStudentProvider.future);
        if (student != null && mounted && !_registrationSubmitted) {
          context.goNamed(AppRoutes.studentHome);
        }
      } catch (_) {
        // No saved student profile yet.
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() != true) return;
    _registrationSubmitted = true;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(studentRegistrationControllerProvider.notifier)
          .register(
            name: _nameController.text.trim(),
            studentNumber: _numberController.text.trim(),
          );
      if (mounted) context.goNamed(AppRoutes.studentDevice);
    } on RepositoryException catch (error) {
      setState(() {
        if (error is DuplicateStudentNumberException) {
          _studentNumberError = error.message;
        }
      });
      _formKey.currentState?.validate();
    } catch (_) {
      if (mounted) {
        setState(
          () => _studentNumberError =
              'Unable to register your profile. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: 'Student registration',
    body: SingleChildScrollView(
      padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            child: const Icon(
              Icons.badge_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Join your class',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Add your student details to connect attendance to this device.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: Spacing.lg),
          SectionCard(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your name.'
                        : null,
                  ),
                  const SizedBox(height: Spacing.md),
                  TextFormField(
                    controller: _numberController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Student number',
                      prefixIcon: Icon(Icons.numbers_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter your student number.'
                        : _studentNumberError,
                    onChanged: (_) {
                      if (_studentNumberError != null) {
                        setState(() => _studentNumberError = null);
                      }
                    },
                  ),
                  const SizedBox(height: Spacing.lg),
                  PrimaryActionButton(
                    label: _isSubmitting
                        ? 'Registering...'
                        : 'Complete registration',
                    icon: Icons.arrow_forward,
                    onPressed: _isSubmitting ? null : _register,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Center(
            child: TextButton(
              onPressed: () => context.goNamed(AppRoutes.teacherSetup),
              child: const Text('Set up a teacher profile'),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Student dashboard with their next class and attendance status.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentAsync = ref.watch(currentStudentProvider);
    final classListAsync = ref.watch(currentStudentOfferingsProvider);
    final sessionAsync = ref.watch(todaySessionProvider);
    final recordsAsync = ref.watch(myAttendanceProvider);
    return PageScaffold(
      title: 'Home',
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            studentAsync.when(
              data: (student) => Text(
                'Hello, ${student?.name.split(' ').first ?? 'Student'}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text(
                'Welcome to ClassAttend',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Your school day at a glance.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: Spacing.lg),
            sessionAsync.when(
              data: (session) => recordsAsync.when(
                data: (records) {
                  final today = session == null
                      ? null
                      : records
                            .where((record) => record.sessionId == session.id)
                            .firstOrNull;
                  return SectionCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(Spacing.md),
                          decoration: BoxDecoration(
                            color: AppColors.successSoft,
                            borderRadius: BorderRadius.circular(Radii.control),
                          ),
                          child: Icon(
                            today?.isPresent == true
                                ? Icons.check_circle_outline
                                : Icons.event_available_outlined,
                            color: AppColors.success,
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Today’s attendance',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: Spacing.xs),
                              Text(
                                today?.isPresent == true
                                    ? 'You are marked present.'
                                    : 'Attendance has not been finalized yet.',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        if (today != null)
                          StatusPill(
                            status: today.isPresent
                                ? AttendanceStatus.present
                                : today.recordStatus ==
                                      AttendanceRecordStatus.notDetected
                                ? AttendanceStatus.pending
                                : AttendanceStatus.absent,
                          ),
                      ],
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, stack) => const _StudentError(),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => const SectionCard(
                child: Text('Attendance has not been recorded yet.'),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My subjects',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.pushNamed(AppRoutes.addSubject),
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            classListAsync.when(
              data: (sections) {
                if (sections.isEmpty) {
                  return const HelpfulEmptyState(
                    title: 'No subjects yet',
                    message: 'Your enrolled subjects will appear here.',
                  );
                }
                return Column(
                  children: sections
                      .map(
                        (section) => Padding(
                          padding: const EdgeInsets.only(bottom: Spacing.sm),
                          child: SectionCard(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.menu_book_outlined,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: Spacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        section.subject,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      Text(
                                        '${section.sectionCode} • ${section.schedule}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => const _StudentError(),
            ),
            const SizedBox(height: Spacing.md),
            ref
                .watch(myDeviceProvider)
                .when(
                  data: (device) => SectionCard(
                    child: Row(
                      children: [
                        Icon(
                          device == null
                              ? Icons.bluetooth_disabled
                              : Icons.bluetooth,
                          color: device == null
                              ? AppColors.warning
                              : AppColors.success,
                        ),
                        const SizedBox(width: Spacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                device?.name ?? 'Device not registered',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                device == null
                                    ? 'Register your device for BLE attendance.'
                                    : 'Registered for BLE attendance',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stack) => const _StudentError(),
                ),
          ],
        ),
      ),
    );
  }
}

/// Student Profile tab with registration and settings details.
class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => PageScaffold(
    title: 'Profile',
    body: ref
        .watch(currentStudentProvider)
        .when(
          data: (student) => ListView(
            padding: const EdgeInsets.only(top: Spacing.md, bottom: Spacing.xl),
            children: [
              SectionCard(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 38,
                      backgroundColor: AppColors.primarySoft,
                      foregroundColor: AppColors.primary,
                      child: Text(
                        student?.name
                                .split(' ')
                                .map((part) => part.substring(0, 1))
                                .take(2)
                                .join()
                                .toUpperCase() ??
                            'S',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      student?.name ?? 'Student profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      student?.studentNumber ?? 'No student number',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                    const SizedBox(height: Spacing.sm),
                    const StatusPill(
                      status: AttendanceStatus.registered,
                      label: 'Registered locally',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),
              PrimaryActionButton(
                label: 'Add subject',
                icon: Icons.qr_code_scanner,
                onPressed: () => context.pushNamed(AppRoutes.addSubject),
              ),
              const SizedBox(height: Spacing.sm),
              SecondaryActionButton(
                label: 'Switch role',
                icon: Icons.swap_horiz,
                onPressed: () => context.go('/roles'),
              ),
              const SizedBox(height: Spacing.md),
              SectionCard(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'My subjects',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    ref
                        .watch(currentStudentOfferingsProvider)
                        .when(
                          data: (offerings) => offerings.isEmpty
                              ? const Text('No subjects added yet.')
                              : Column(
                                  children: offerings
                                      .map(
                                        (offering) => ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: const Icon(
                                            Icons.menu_book_outlined,
                                          ),
                                          title: Text(offering.subject),
                                          subtitle: Text(
                                            '${offering.sectionCode} • ${offering.schedule}',
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                          loading: () => const LinearProgressIndicator(),
                          error: (error, stack) =>
                              const Text('Subjects are unavailable.'),
                        ),
                  ],
                ),
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const _StudentError(),
        ),
  );
}

class _StudentError extends StatelessWidget {
  const _StudentError();

  @override
  Widget build(BuildContext context) => const Center(
    child: SectionCard(child: Text('Student information is unavailable.')),
  );
}

class DeclaredSectionCard extends StatelessWidget {
  const DeclaredSectionCard({super.key, required this.sectionCode});

  final String sectionCode;

  @override
  Widget build(BuildContext context) => SectionCard(
    child: Row(
      children: [
        const Icon(Icons.menu_book_outlined, color: AppColors.primary),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(sectionCode, style: Theme.of(context).textTheme.titleMedium),
              Text(
                'Class details are stored on the teacher’s device.',
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
