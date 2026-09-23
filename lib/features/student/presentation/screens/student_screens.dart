import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/utils/iterable_extensions.dart';
import '../../../../core/utils/section_code.dart';
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
  final _sectionCodeController = TextEditingController();
  String? _sectionError;
  String? _studentNumberError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final student = await ref.read(currentStudentProvider.future);
        if (student != null && mounted) context.goNamed(AppRoutes.studentHome);
      } catch (_) {
        // No saved student profile yet.
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _numberController.dispose();
    _sectionCodeController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState?.validate() != true) return;
    final normalizedSection = normalizeSectionCode(_sectionCodeController.text);
    _sectionCodeController.value = TextEditingValue(
      text: normalizedSection,
      selection: TextSelection.collapsed(offset: normalizedSection.length),
    );
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(studentRegistrationControllerProvider.notifier)
          .register(
            name: _nameController.text.trim(),
            studentNumber: _numberController.text.trim(),
            sectionCode: _sectionCodeController.text,
          );
      if (mounted) context.goNamed(AppRoutes.studentDevice);
    } on RepositoryException catch (error) {
      setState(() {
        if (error is DuplicateStudentNumberException) {
          _studentNumberError = error.message;
        } else {
          _sectionError = error.message;
        }
      });
      _formKey.currentState?.validate();
    } catch (_) {
      if (mounted) {
        setState(
          () => _sectionError =
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
                  const SizedBox(height: Spacing.md),
                  TextFormField(
                    controller: _sectionCodeController,
                    textCapitalization: TextCapitalization.characters,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    inputFormatters: const [UppercaseSingleSpaceFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Grade & Section',
                      hintText: 'GRADE12-STEM A',
                      helperText: 'Use the format GRADE12-STEM A.',
                      prefixIcon: Icon(Icons.class_outlined),
                    ),
                    validator: (value) {
                      if (parseSectionCode(value ?? '') == null) {
                        return 'Enter a valid code, such as GRADE12-STEM A.';
                      }
                      return _sectionError;
                    },
                    onChanged: (_) {
                      if (_sectionError != null) {
                        setState(() => _sectionError = null);
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
          if (kDebugMode) ...[
            const SizedBox(height: Spacing.lg),
            Center(
              child: TextButton.icon(
                onPressed: () => context.goNamed(AppRoutes.debugRoles),
                icon: const Icon(Icons.developer_mode),
                label: const Text('Open role previews'),
              ),
            ),
          ],
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
    final classListAsync = ref.watch(currentStudentClassProvider);
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
                  final today = records
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
                                      AttendanceRecordStatus.unverified
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
                    'Today’s classes',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            classListAsync.when(
              data: (section) => section == null
                  ? const HelpfulEmptyState(
                      title: 'No classes yet',
                      message: 'Your enrolled classes will appear here.',
                    )
                  : SectionCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            color: AppColors.primary,
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(
                                  section.subject == 'Awaiting teacher details'
                                      ? 'Section saved locally'
                                      : section.subject,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.muted),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: Spacing.sm),
                          Flexible(
                            child: Text(
                              section.subject == 'Awaiting teacher details'
                                  ? 'Teacher details pending'
                                  : section.schedule,
                              textAlign: TextAlign.end,
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                              : Icons.bluetooth_connected,
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
                                device?.address ??
                                    'Register your device for BLE attendance.',
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
              SectionCard(
                child: Column(
                  children: [
                    _ProfileLine(
                      icon: Icons.school_outlined,
                      label: 'Grade level',
                      value: student?.gradeLevel ?? 'Not set',
                    ),
                    const Divider(height: Spacing.lg),
                    _ProfileLine(
                      icon: Icons.class_outlined,
                      label: 'Class section',
                      value:
                          ref.watch(currentStudentClassProvider).value?.name ??
                          'Not set',
                    ),
                  ],
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: Spacing.md),
                OutlinedButton.icon(
                  onPressed: () => context.goNamed(AppRoutes.debugRoles),
                  icon: const Icon(Icons.developer_mode),
                  label: const Text('Switch role preview'),
                ),
              ],
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const _StudentError(),
        ),
  );
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: AppColors.muted),
      const SizedBox(width: Spacing.md),
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
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    ],
  );
}

class _StudentError extends StatelessWidget {
  const _StudentError();

  @override
  Widget build(BuildContext context) => const Center(
    child: SectionCard(child: Text('Student information is unavailable.')),
  );
}
