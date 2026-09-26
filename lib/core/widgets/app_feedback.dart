import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppFeedbackKind { success, error, info, loading }

/// Consistent floating feedback for short, user-visible outcomes.
abstract final class AppFeedback {
  static void success(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) => _show(context, message, AppFeedbackKind.success, action: action);

  static void error(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) => _show(context, message, AppFeedbackKind.error, action: action);

  static void info(
    BuildContext context,
    String message, {
    SnackBarAction? action,
  }) => _show(context, message, AppFeedbackKind.info, action: action);

  static void loading(BuildContext context, String message) => _show(
    context,
    message,
    AppFeedbackKind.loading,
    duration: const Duration(days: 1),
  );

  static void hideLoading(BuildContext context) =>
      ScaffoldMessenger.maybeOf(context)?.clearSnackBars();

  static void _show(
    BuildContext context,
    String message,
    AppFeedbackKind kind, {
    SnackBarAction? action,
    Duration? duration,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final (color, icon) = switch (kind) {
      AppFeedbackKind.success => (
        AppColors.success,
        Icons.check_circle_outline,
      ),
      AppFeedbackKind.error => (AppColors.danger, Icons.error_outline),
      AppFeedbackKind.info => (AppColors.ink, Icons.info_outline),
      AppFeedbackKind.loading => (AppColors.ink, null),
    };
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.control),
          ),
          duration: duration ?? const Duration(seconds: 3),
          action: action,
          content: Semantics(
            liveRegion: true,
            child: Row(
              children: [
                if (kind == AppFeedbackKind.loading) ...[
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                ],
                Expanded(child: Text(message)),
              ],
            ),
          ),
        ),
      );
  }
}
