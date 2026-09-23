import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'route_names.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) => PageScaffold(
    title: 'ClassAttend',
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(Radii.card),
              ),
              child: const Icon(
                Icons.fact_check_outlined,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Text(
              'Attendance made simple',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              'Choose how you use ClassAttend on this device.',
              style: Theme.of(context).textTheme.bodyLarge
                  ?.copyWith(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),
            PrimaryActionButton(
              label: 'Continue as teacher',
              icon: Icons.school_outlined,
              onPressed: () => context.goNamed(AppRoutes.teacherSetup),
            ),
            const SizedBox(height: Spacing.sm),
            SecondaryActionButton(
              label: 'Continue as student',
              icon: Icons.person_outline,
              onPressed: () => context.goNamed(AppRoutes.studentSetup),
            ),
          ],
        ),
      ),
    ),
  );
}
