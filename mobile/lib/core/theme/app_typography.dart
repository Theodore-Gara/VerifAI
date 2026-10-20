import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Built once and reused. Every access used to call GoogleFonts.interTextTheme()
  // again, which re-resolves (and, when a font is missing, re-requests) each
  // family on every style lookup — an allocation storm on hot widgets.
  static TextTheme? _cached;

  static TextTheme get textTheme => _cached ??= GoogleFonts.interTextTheme().copyWith(
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
    Color color = AppColors.primaryNavy,
  ]) {
    return GoogleFonts.manrope(
      fontSize: size,
      fontWeight: weight,
      color: color,
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
    return GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      color: color,
      letterSpacing: spacing,
      height: height,
    );
  }
}
