import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryNavy,
        onPrimary: Colors.white,
        secondary: AppColors.accentGreen,
        onSecondary: Colors.white,
        tertiary: AppColors.accentCyan,
        onTertiary: AppColors.primaryNavy,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.border,
        outlineVariant: AppColors.border,
        shadow: AppColors.shadow,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: AppTypography.textTheme.headlineMedium?.copyWith(
          color: AppColors.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryNavy,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: AppColors.shadow,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.textTheme.labelLarge?.copyWith(
            color: Colors.white,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          side: const BorderSide(color: AppColors.border, width: 1.5),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.textTheme.labelLarge?.copyWith(
            color: AppColors.primaryNavy,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryNavy,
          minimumSize: const Size(0, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.textTheme.labelLarge?.copyWith(
            color: AppColors.primaryNavy,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primaryNavy, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
        ),
        hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
          color: AppColors.textSecondary.withValues(alpha: 0.6),
        ),
        errorStyle: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.error,
        ),
        floatingLabelStyle: AppTypography.textTheme.bodySmall?.copyWith(
          color: AppColors.primaryNavy,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shadowColor: AppColors.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: AppSpacing.md,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.background,
        selectedColor: AppColors.accentLight,
        labelStyle: AppTypography.textTheme.labelMedium?.copyWith(
          color: AppColors.textPrimary,
        ),
        secondaryLabelStyle: AppTypography.textTheme.labelMedium?.copyWith(
          color: AppColors.primaryNavy,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.badge),
          side: const BorderSide(color: AppColors.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accentGreen,
        linearTrackColor: AppColors.accentLight,
        circularTrackColor: AppColors.accentLight,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primaryNavy,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: AppTypography.textTheme.labelSmall,
        unselectedLabelStyle: AppTypography.textTheme.labelSmall,
      ),
    );
  }
}
