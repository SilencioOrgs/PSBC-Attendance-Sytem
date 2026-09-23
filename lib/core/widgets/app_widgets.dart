import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AttendanceStatus {
  present,
  absent,
  detected,
  pending,
  registered,
  unverified,
}

/// Standard page title row with optional back navigation and offline status.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.trailing,
    this.onBack,
  });

  final String title;
  final bool showBack;
  final Widget? trailing;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      Spacing.md,
      Spacing.sm,
      Spacing.md,
      Spacing.sm,
    ),
    child: Row(
      children: [
        if (showBack) ...[
          IconButton(
            tooltip: 'Go back',
            onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
          const SizedBox(width: Spacing.xs),
        ],
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontSize: 21),
          ),
        ),
        trailing ?? const OfflineStatusChip(),
      ],
    ),
  );
}

/// Offline indicator used in top bars.
class OfflineStatusChip extends StatelessWidget {
  const OfflineStatusChip({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.successSoft,
      borderRadius: BorderRadius.circular(Radii.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 14,
          color: AppColors.success,
        ),
        const SizedBox(width: Spacing.xs),
        Text(
          'Offline',
          style: Theme.of(context).textTheme.labelSmall
              ?.copyWith(color: AppColors.success),
        ),
      ],
    ),
  );
}

/// Compact status indicator with shared color and icon mapping.
class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.label});

  final AttendanceStatus status;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (color, background, icon, defaultLabel) = switch (status) {
      AttendanceStatus.present => (
        AppColors.success,
        AppColors.successSoft,
        Icons.check_circle_outline,
        'Present',
      ),
      AttendanceStatus.absent => (
        AppColors.danger,
        AppColors.dangerSoft,
        Icons.cancel_outlined,
        'Absent',
      ),
      AttendanceStatus.detected => (
        AppColors.primary,
        AppColors.primarySoft,
        Icons.bluetooth_connected,
        'Detected',
      ),
      AttendanceStatus.pending => (
        AppColors.warning,
        AppColors.warningSoft,
        Icons.schedule,
        'Pending',
      ),
      AttendanceStatus.registered => (
        AppColors.teal,
        AppColors.tealSoft,
        Icons.verified_outlined,
        'Registered',
      ),
      AttendanceStatus.unverified => (
        AppColors.muted,
        AppColors.border,
        Icons.help_outline,
        'Unverified',
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Radii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: Spacing.xs),
          Text(
            label ?? defaultLabel,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Bordered surface card used for grouped content.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(Spacing.md),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(Radii.card),
    ),
    child: child,
  );
}

/// Student row with initials, secondary details, and a shared status pill.
class PersonListTile extends StatelessWidget {
  const PersonListTile({
    super.key,
    required this.name,
    required this.subtitle,
    required this.status,
    this.onTap,
    this.trailing,
  });

  final String name;
  final String subtitle;
  final AttendanceStatus status;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.substring(0, 1))
        .join()
        .toUpperCase();
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: AppColors.primarySoft,
        foregroundColor: AppColors.primary,
        child: Text(initials, style: Theme.of(context).textTheme.labelMedium),
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: trailing ?? StatusPill(status: status),
    );
  }
}

/// Compact metric card used in dashboard and attendance summaries.
class MetricStatCard extends StatelessWidget {
  const MetricStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.trend,
    this.color = AppColors.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? trend;
  final Color color;

  @override
  Widget build(BuildContext context) => SectionCard(
    padding: const EdgeInsets.all(Spacing.md),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: Spacing.sm),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(color: AppColors.ink),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall
              ?.copyWith(color: AppColors.muted),
        ),
        if (trend != null) ...[
          const SizedBox(height: Spacing.xs),
          Text(
            trend ?? '',
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color),
          ),
        ],
      ],
    ),
  );
}

/// Radar-style BLE scanning animation with reduced-size idle presentation.
class BleRadarIndicator extends StatefulWidget {
  const BleRadarIndicator({
    super.key,
    required this.isScanning,
    this.progress = 0,
  });

  final bool isScanning;
  final double progress;

  @override
  State<BleRadarIndicator> createState() => _BleRadarIndicatorState();
}

class _BleRadarIndicatorState extends State<BleRadarIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 224),
    child: AspectRatio(
      aspectRatio: 1,
      child: LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final pulse = widget.isScanning ? _controller.value : 0.45;
            final diameter = constraints.maxWidth;
            return Stack(
              alignment: Alignment.center,
              children: [
                for (var ring = 2; ring >= 0; ring--)
                  Container(
                    width:
                        diameter * (0.36 + (2 - ring) * 0.20) +
                        pulse * diameter * 0.04,
                    height:
                        diameter * (0.36 + (2 - ring) * 0.20) +
                        pulse * diameter * 0.04,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(
                          alpha: 0.12 + (2 - ring) * 0.06,
                        ),
                        width: 1.5,
                      ),
                    ),
                  ),
                Container(
                  width: diameter * 0.38,
                  height: diameter * 0.38,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bluetooth_searching,
                    size: 34,
                    color: AppColors.primary,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: CircularProgressIndicator(
                      value: widget.isScanning ? widget.progress : 0,
                      strokeWidth: 3,
                      backgroundColor: AppColors.border,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// Standard full-width primary action.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: icon == null
        ? FilledButton(onPressed: onPressed, child: Text(label))
        : FilledButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          ),
  );
}

/// Standard full-width secondary action.
class SecondaryActionButton extends StatelessWidget {
  const SecondaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 52,
    child: icon == null
        ? OutlinedButton(onPressed: onPressed, child: Text(label))
        : OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label),
          ),
  );
}

/// Centers content and caps its width on tablets while preserving phone width.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 720,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        child: child,
      ),
    ),
  );
}

/// Safe-area page shell shared by feature screens.
class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.showBack = false,
    this.trailing,
    this.onBack,
    this.bottomNavigationBar,
  });

  final String title;
  final Widget body;
  final bool showBack;
  final Widget? trailing;
  final VoidCallback? onBack;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          ResponsiveContent(
            child: AppTopBar(
              title: title,
              showBack: showBack,
              trailing: trailing,
              onBack: onBack,
            ),
          ),
          Expanded(child: ResponsiveContent(child: body)),
        ],
      ),
    ),
    bottomNavigationBar: bottomNavigationBar,
  );
}
