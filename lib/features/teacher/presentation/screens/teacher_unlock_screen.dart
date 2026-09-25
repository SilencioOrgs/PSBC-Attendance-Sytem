import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/repository_providers.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/input_formatters.dart';
import '../../../../core/utils/teacher_pin.dart';
import '../../../../core/widgets/app_widgets.dart';
import '../providers/teacher_provider.dart';

class TeacherUnlockScreen extends ConsumerStatefulWidget {
  const TeacherUnlockScreen({super.key});
  @override
  ConsumerState<TeacherUnlockScreen> createState() =>
      _TeacherUnlockScreenState();
}

class _TeacherUnlockScreenState extends ConsumerState<TeacherUnlockScreen> {
  final _pin = TextEditingController();
  String? _error;
  bool _checking = false;

  Future<void> _continueAsStudent() async {
    final session = ref.read(applicationSessionProvider);
    if (session.currentStudentId == null) {
      if (mounted) context.goNamed(AppRoutes.studentSetup);
      return;
    }
    try {
      await session.selectStudent();
      if (mounted) context.goNamed(AppRoutes.studentHome);
    } catch (_) {
      if (mounted) context.goNamed(AppRoutes.studentSetup);
    }
  }

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    if (!isValidTeacherPin(_pin.text)) {
      setState(() => _error = 'Enter your 4 to 6 digit PIN.');
      return;
    }
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final allowed = await ref
          .read(teacherPinUnlockProvider.notifier)
          .unlock(_pin.text);
      if (allowed && mounted) context.goNamed(AppRoutes.teacherHome);
      if (!allowed && mounted) {
        setState(() => _error = 'That PIN does not match. Try again.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to verify your PIN. Try again.');
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: 'Teacher sign in',
    body: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter your PIN',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            'Your PIN protects attendance records stored on this device.',
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: Spacing.lg),
          TextField(
            controller: _pin,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: const [DigitsOnlyPinFormatter()],
            decoration: InputDecoration(
              labelText: 'Teacher PIN',
              prefixIcon: const Icon(Icons.lock_outline),
              errorText: _error,
            ),
            onSubmitted: (_) => _unlock(),
          ),
          const SizedBox(height: Spacing.md),
          PrimaryActionButton(
            label: _checking ? 'Checking...' : 'Continue',
            icon: Icons.lock_open_outlined,
            onPressed: _checking ? null : _unlock,
          ),
          const SizedBox(height: Spacing.md),
          Center(
            child: TextButton(
              onPressed: _continueAsStudent,
              child: const Text('Continue as a student'),
            ),
          ),
        ],
      ),
    ),
  );
}
