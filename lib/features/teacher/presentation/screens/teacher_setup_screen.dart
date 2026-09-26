import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/teacher_pin.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../providers/teacher_provider.dart';
import '../widgets/pin_keypad.dart';

/// First-run teacher PIN setup screen.
class TeacherSetupScreen extends ConsumerStatefulWidget {
  const TeacherSetupScreen({super.key});

  @override
  ConsumerState<TeacherSetupScreen> createState() => _TeacherSetupScreenState();
}

class _TeacherSetupScreenState extends ConsumerState<TeacherSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _pinBuffer = '';
  String _firstPin = '';
  int _pinStep = 0;
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
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (_formKey.currentState?.validate() != true) return;
    if (!isValidTeacherPin(_firstPin) || _firstPin != _pinBuffer) {
      setState(() {
        _pinBuffer = '';
        _error = 'PINs do not match. Confirm the same PIN to continue.';
      });
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      await ref
          .read(teacherSetupControllerProvider.notifier)
          .complete(
            name: _nameController.text.trim(),
            pin: normalizeTeacherPin(_firstPin),
          );
      if (mounted) {
        AppFeedback.success(context, 'PIN saved.');
        context.goNamed(AppRoutes.teacherHome);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to save setup. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _advancePinStep() async {
    if (!isValidTeacherPin(_pinBuffer)) {
      setState(() => _error = 'Use 4 to 6 digits.');
      return;
    }
    if (_pinStep == 0) {
      setState(() {
        _firstPin = _pinBuffer;
        _pinBuffer = '';
        _pinStep = 1;
        _error = null;
      });
      return;
    }
    if (_firstPin != _pinBuffer) {
      setState(() {
        _pinBuffer = '';
        _error = 'PINs do not match. Enter your PIN again.';
      });
      return;
    }
    await _completeSetup();
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
                  PinKeypad(
                    pin: _pinBuffer,
                    title: _pinStep == 0 ? 'Create PIN' : 'Confirm PIN',
                    helperText: _error ?? 'Use 4 to 6 digits.',
                    onDigit: (digit) => setState(() {
                      _pinBuffer += digit;
                      _error = null;
                    }),
                    onDelete: () => setState(() {
                      _pinBuffer = _pinBuffer.substring(
                        0,
                        _pinBuffer.length - 1,
                      );
                      _error = null;
                    }),
                  ),
                  if (_error != null) ...[const SizedBox(height: Spacing.xs)],
                  const SizedBox(height: Spacing.sm),
                  PrimaryActionButton(
                    label: _isSubmitting
                        ? 'Saving setup...'
                        : _pinStep == 0
                        ? 'Continue to confirm PIN'
                        : 'Save PIN and continue',
                    icon: Icons.arrow_forward,
                    onPressed: _isSubmitting || !isValidTeacherPin(_pinBuffer)
                        ? null
                        : _advancePinStep,
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
