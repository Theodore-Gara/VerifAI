import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';
import 'app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => themeFor(AppPalette.light);

  static ThemeData get darkTheme => themeFor(AppPalette.dark);

  /// One definition for both modes: every colour comes from the palette, so a
  /// token added here works in light and dark without a second copy.
  static ThemeData themeFor(AppPalette p) {
    final base = p == AppPalette.dark
        ? ThemeData.dark(useMaterial3: true)
        : ThemeData.light(useMaterial3: true);
    final textTheme = AppTypography.textTheme.apply(
      bodyColor: p.textPrimary,
      displayColor: p.textPrimary,
    );

    return base.copyWith(
      brightness: p == AppPalette.dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme(
        brightness: p == AppPalette.dark ? Brightness.dark : Brightness.light,
        primary: p.accentGreen,
        onPrimary: p.surface,
        secondary: p.accentGreen,
        onSecondary: p.surface,
        tertiary: p.accentCyan,
        onTertiary: p.primaryDark,
        surface: p.surface,
        onSurface: p.textPrimary,
        error: p.error,
        onError: p.surface,
        outline: p.border,
        outlineVariant: p.border,
        shadow: p.shadow,
      ),
      scaffoldBackgroundColor: p.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.background,
        foregroundColor: p.textPrimary,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.headlineMedium?.copyWith(
          color: p.textPrimary,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.primaryNavy,
          foregroundColor: p == AppPalette.dark ? p.primaryDark : p.surface,
          elevation: 0,
          shadowColor: p.shadow,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primaryNavy,
          side: BorderSide(color: p.border, width: 1.5),
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.accentGreen,
          minimumSize: const Size(0, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: p.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: p.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: p.accentGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: p.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(color: p.error, width: 2),
        ),
        labelStyle: textTheme.bodySmall?.copyWith(color: p.textSecondary),
        hintStyle: textTheme.bodyMedium
            ?.copyWith(color: p.textSecondary.withValues(alpha: 0.6)),
        errorStyle: textTheme.bodySmall?.copyWith(color: p.error),
        floatingLabelStyle:
            textTheme.bodySmall?.copyWith(color: p.accentGreen),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        shadowColor: p.shadow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: p.border, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: p.border,
        thickness: 1,
        space: AppSpacing.md,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.background,
        selectedColor: p.accentLight,
        labelStyle: textTheme.labelMedium?.copyWith(color: p.textPrimary),
        secondaryLabelStyle:
            textTheme.labelMedium?.copyWith(color: p.accentGreen),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.badge),
          side: BorderSide(color: p.border),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.accentGreen,
        linearTrackColor: p.accentLight,
        circularTrackColor: p.accentLight,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.accentGreen,
        unselectedItemColor: p.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
      ),
    );
  }
}
