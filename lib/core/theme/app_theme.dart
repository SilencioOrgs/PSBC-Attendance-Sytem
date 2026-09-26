import 'package:flutter/material.dart';

/// Central palette for ClassAttend.
abstract final class AppColors {
  static const primary = Color(0xFFC45A1A);
  static const primarySoft = Color(0xFFFBE8DC);
  static const ink = Color(0xFF1A2433);
  static const muted = Color(0xFF667085);
  static const canvas = Color(0xFFFFF9F5);
  static const surface = Color(0xFFFFFFFF);
  static const border = Color(0xFFEBDDD3);
  static const success = Color(0xFF15825D);
  static const successSoft = Color(0xFFE1F4EC);
  static const warning = Color(0xFFAA6B08);
  static const warningSoft = Color(0xFFFFF2D9);
  static const danger = Color(0xFFB83C47);
  static const dangerSoft = Color(0xFFFCE9EB);
  static const teal = Color(0xFF8B471F);
  static const tealSoft = Color(0xFFF6E7DC);
}

/// Named layout spacing tokens.
abstract final class Spacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 40.0;
}

/// Named corner radius tokens.
abstract final class Radii {
  static const control = 14.0;
  static const card = 20.0;
  static const pill = 100.0;
}

/// Material 3 theme with Space Grotesk headlines and Inter body text.
abstract final class AppTheme {
  static ThemeData get light {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: AppColors.surface,
          primaryContainer: AppColors.primarySoft,
          onPrimaryContainer: AppColors.ink,
          secondary: AppColors.teal,
          onSecondary: AppColors.surface,
          secondaryContainer: AppColors.tealSoft,
          onSecondaryContainer: AppColors.ink,
          surface: AppColors.surface,
          onSurface: AppColors.ink,
          surfaceContainerLowest: AppColors.surface,
          error: AppColors.danger,
          onError: AppColors.surface,
        );
    final baseText = ThemeData(colorScheme: scheme).textTheme;
    final textTheme = baseText.copyWith(
      displayLarge: const TextStyle(
        fontFamily: 'Space Grotesk',
        fontWeight: FontWeight.w700,
      ),
      displayMedium: const TextStyle(
        fontFamily: 'Space Grotesk',
        fontWeight: FontWeight.w700,
      ),
      displaySmall: const TextStyle(
        fontFamily: 'Space Grotesk',
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: const TextStyle(
        fontFamily: 'Space Grotesk',
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: const TextStyle(
        fontFamily: 'Space Grotesk',
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: const TextStyle(
        fontFamily: 'Space Grotesk',
        fontWeight: FontWeight.w600,
      ),
      titleLarge: const TextStyle(
        fontFamily: 'Space Grotesk',
        fontWeight: FontWeight.w600,
      ),
      titleMedium: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
      titleSmall: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: const TextStyle(fontFamily: 'Inter'),
      bodyMedium: const TextStyle(fontFamily: 'Inter'),
      bodySmall: const TextStyle(fontFamily: 'Inter'),
      labelLarge: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
      labelMedium: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
      labelSmall: const TextStyle(
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
      ),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.canvas,
      textTheme: textTheme,
      dividerColor: AppColors.border,
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Radii.control),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primarySoft,
        labelTextStyle: WidgetStatePropertyAll(textTheme.labelSmall),
        height: 72,
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          for (final platform in TargetPlatform.values)
            platform: const _FadePageTransitionsBuilder(),
        },
      ),
    );
  }
}

class _FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.of(context).disableAnimations) return child;
    return FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      child: child,
    );
  }
}
