import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Both families are bundled in pubspec.yaml, so there is no runtime fetch and
  // no fallback-then-swap reflow on first paint. The theme is built once.
  static const String bodyFamily = 'Inter';
  static const String headingFamily = 'Manrope';

  static AppPalette? _cachedFor;
  static TextTheme? _cached;

  /// Rebuilt when the palette changes (light ↔ dark), cached otherwise.
  static TextTheme get textTheme {
    if (_cached != null && _cachedFor == AppColors.palette) return _cached!;
    _cachedFor = AppColors.palette;
    return _cached = _build();
  }

  static TextTheme _build() => ThemeData.light().textTheme.copyWith(
        displayLarge: _heading(32, FontWeight.w800, -1.0, 1.15),
        displayMedium: _heading(28, FontWeight.w800, -0.8, 1.2),
        displaySmall: _heading(24, FontWeight.w800, -0.6, 1.25),
        headlineLarge: _heading(22, FontWeight.w800, -0.5, 1.3),
        headlineMedium: _heading(18, FontWeight.w800, -0.4, 1.35),
        headlineSmall: _heading(16, FontWeight.w700, -0.3, 1.4),
        titleLarge:
            _heading(16, FontWeight.w700, -0.2, 1.4, AppColors.graphite),
        titleMedium:
            _heading(14, FontWeight.w700, -0.1, 1.4, AppColors.graphite),
        titleSmall:
            _inter(13, FontWeight.w600, 0, 1.4, AppColors.textSecondary),
        bodyLarge: _inter(16, FontWeight.w400, -0.1, 1.5, AppColors.graphite),
        bodyMedium: _inter(14, FontWeight.w400, 0, 1.5, AppColors.graphite),
        bodySmall: _inter(12, FontWeight.w400, 0, 1.5, AppColors.textSecondary),
        labelLarge: _inter(14, FontWeight.w600, 0.1, 1.4, AppColors.graphite),
        labelMedium:
            _inter(12, FontWeight.w600, 0.3, 1.4, AppColors.textSecondary),
        labelSmall:
            _inter(11, FontWeight.w600, 0.5, 1.3, AppColors.textSecondary),
      );

  static TextStyle _heading(
    double size,
    FontWeight weight,
    double spacing,
    double height, [
    Color? color,
  ]) {
    return TextStyle(
      fontFamily: headingFamily,
      fontSize: size,
      fontWeight: weight,
      // Nullable so the default follows the active palette rather than being
      // frozen at the light theme's navy.
      color: color ?? AppColors.primaryNavy,
      letterSpacing: spacing,
      height: height,
    );
  }

  static TextStyle _inter(
    double size,
    FontWeight weight,
    double spacing,
    double height,
    Color color,
  ) {
    return TextStyle(
      fontFamily: bodyFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
    );
  }
}
