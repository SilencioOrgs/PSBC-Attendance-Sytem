import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/utils/teacher_pin.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../providers/teacher_provider.dart';

/// First-run teacher PIN setup screen.
class TeacherSetupScreen extends ConsumerStatefulWidget {
  const TeacherSetupScreen({super.key});

  @override
  ConsumerState<TeacherSetupScreen> createState() => _TeacherSetupScreenState();
}

class _TeacherSetupScreenState extends ConsumerState<TeacherSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await ref.read(teacherProvider.future);
        if (!await ref.read(teacherPinServiceProvider).hasPin()) return;
        if (mounted) context.goNamed(AppRoutes.teacherUnlock);
      } catch (_) {
        // A missing teacher profile is the expected first-run state.
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(teacherSetupControllerProvider.notifier)
          .complete(
            name: _nameController.text.trim(),
            pin: normalizeTeacherPin(_pinController.text),
          );
      if (mounted) context.goNamed(AppRoutes.teacherHome);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to save setup. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: 'Teacher setup',
    body: SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: Spacing.xl),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(Radii.card),
            ),
            child: const Icon(
              Icons.school_outlined,
              color: AppColors.primary,
              size: 30,
            ),
          ),
          const SizedBox(height: Spacing.lg),
          Text(
            'Set up your classroom',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Create a teacher PIN to secure attendance records on this device.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: Spacing.xl),
          SectionCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Teacher details',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: Spacing.md),
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
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 6,
                    inputFormatters: const [DigitsOnlyPinFormatter()],
                    decoration: const InputDecoration(
                      labelText: 'Create a 4 to 6 digit PIN',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) => !isValidTeacherPin(value ?? '')
                        ? 'Use 4 to 6 digits.'
                        : null,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: Spacing.sm),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: Spacing.sm),
                  PrimaryActionButton(
                    label: _isSubmitting
                        ? 'Saving setup...'
                        : 'Continue to dashboard',
                    icon: Icons.arrow_forward,
                    onPressed: _isSubmitting ? null : _completeSetup,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),
          Center(
            child: TextButton(
              onPressed: () => context.goNamed(AppRoutes.studentSetup),
              child: const Text('Set up a student profile'),
            ),
          ),
        ],
      ),
    ),
  );
}
