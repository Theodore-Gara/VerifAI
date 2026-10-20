import 'package:flutter/material.dart';

/// The two palettes the app can render. Values are semantic, not literal: a
/// screen asks for `AppColors.surface` and gets the right colour for the theme
/// that is active, which is what makes dark mode possible without touching every
/// widget.
class AppPalette {
  final Color primaryNavy;
  final Color primaryDark;
  final Color accentGreen;
  final Color accentCyan;
  final Color accentLight;
  final Color background;
  final Color surface;
  final Color textPrimary;
  final Color textSecondary;
  final Color graphite;
  final Color electricMint;
  final Color error;
  final Color warning;
  final Color info;
  final Color border;
  final Color borderFocus;
  final Color gold;
  final Color goldLight;
  final Color goldDark;
  final Color silver;
  final Color silverLight;
  final Color bronze;
  final Color bronzeLight;
  final Color xpPurple;
  final Color xpPurpleLight;
  final Color shadow;
  final Color shadowStrong;
  final Color buttonDepthNavy;
  final Color buttonDepthGreen;
  final Color buttonDepthWhite;
  final Color glassSurface;
  final Color glassSurfaceDark;
  final Color glassBorder;
  final Color glassBorderDark;
  final Color ambientGreen;
  final Color ambientCyan;
  final Color ambientGold;

  const AppPalette({
    required this.primaryNavy,
    required this.primaryDark,
    required this.accentGreen,
    required this.accentCyan,
    required this.accentLight,
    required this.background,
    required this.surface,
    required this.textPrimary,
    required this.textSecondary,
    required this.graphite,
    required this.electricMint,
    required this.error,
    required this.warning,
    required this.info,
    required this.border,
    required this.borderFocus,
    required this.gold,
    required this.goldLight,
    required this.goldDark,
    required this.silver,
    required this.silverLight,
    required this.bronze,
    required this.bronzeLight,
    required this.xpPurple,
    required this.xpPurpleLight,
    required this.shadow,
    required this.shadowStrong,
    required this.buttonDepthNavy,
    required this.buttonDepthGreen,
    required this.buttonDepthWhite,
    required this.glassSurface,
    required this.glassSurfaceDark,
    required this.glassBorder,
    required this.glassBorderDark,
    required this.ambientGreen,
    required this.ambientCyan,
    required this.ambientGold,
  });

  static const light = AppPalette(
    primaryNavy: Color(0xFF102A23),
    primaryDark: Color(0xFF071A14),
    accentGreen: Color(0xFF176B4D),
    accentCyan: Color(0xFFD8BD7A),
    accentLight: Color(0xFFE5EDE5),
    background: Color(0xFFF7F5EF),
    surface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF18231E),
    textSecondary: Color(0xFF64716A),
    graphite: Color(0xFF18231E),
    electricMint: Color(0xFF3C8968),
    error: Color(0xFFEF4444),
    warning: Color(0xFFB77936),
    info: Color(0xFF3B82F6),
    border: Color(0xFFE5E8DF),
    borderFocus: Color(0xFF102A23),
    gold: Color(0xFFD6B76E),
    goldLight: Color(0xFFF4EAD3),
    goldDark: Color(0xFF8D6C2E),
    silver: Color(0xFF94A3B8),
    silverLight: Color(0xFFF1F5F9),
    bronze: Color(0xFFB45309),
    bronzeLight: Color(0xFFFFEDD5),
    xpPurple: Color(0xFF8B5CF6),
    xpPurpleLight: Color(0xFFEDE9FE),
    shadow: Color(0x1A102A23),
    shadowStrong: Color(0x33102A23),
    buttonDepthNavy: Color(0xFF071A14),
    buttonDepthGreen: Color(0xFF1C553F),
    buttonDepthWhite: Color(0xFFCBD5E1),
    glassSurface: Color(0xF2FFFFFF),
    glassSurfaceDark: Color(0xE6102A23),
    glassBorder: Color(0x40FFFFFF),
    glassBorderDark: Color(0x333D544A),
    ambientGreen: Color(0x18276B52),
    ambientCyan: Color(0x18D5B779),
    ambientGold: Color(0x20C8A45D),
  );

  /// Deep-forest dark theme. Text and accents stay legible on the darker
  /// surfaces instead of inverting the whole identity.
  static const dark = AppPalette(
    primaryNavy: Color(0xFFE8F1EA),
    primaryDark: Color(0xFF0A1F18),
    accentGreen: Color(0xFF5CBB92),
    accentCyan: Color(0xFFE2C98E),
    accentLight: Color(0xFF1D3A2F),
    background: Color(0xFF0C1714),
    surface: Color(0xFF14231E),
    textPrimary: Color(0xFFEAF2EC),
    textSecondary: Color(0xFF9DB0A6),
    graphite: Color(0xFFEAF2EC),
    electricMint: Color(0xFF74D0A5),
    error: Color(0xFFFF7B72),
    warning: Color(0xFFE0B063),
    info: Color(0xFF7FB0FF),
    border: Color(0xFF26382F),
    borderFocus: Color(0xFFE8F1EA),
    gold: Color(0xFFE0C282),
    goldLight: Color(0xFF3A3122),
    goldDark: Color(0xFFE7CE97),
    silver: Color(0xFF9AA9B6),
    silverLight: Color(0xFF222C33),
    bronze: Color(0xFFE0A071),
    bronzeLight: Color(0xFF3A2A1E),
    xpPurple: Color(0xFFB49CFF),
    xpPurpleLight: Color(0xFF2B2340),
    shadow: Color(0x66000000),
    shadowStrong: Color(0x99000000),
    buttonDepthNavy: Color(0xFF050F0B),
    buttonDepthGreen: Color(0xFF173A2C),
    buttonDepthWhite: Color(0xFF4A5A52),
    glassSurface: Color(0xF21A2A24),
    glassSurfaceDark: Color(0xE60A1613),
    glassBorder: Color(0x2AFFFFFF),
    glassBorderDark: Color(0x403D544A),
    ambientGreen: Color(0x22276B52),
    ambientCyan: Color(0x1FD5B779),
    ambientGold: Color(0x26C8A45D),
  );
}

/// Active palette. `AppTheme` flips this together with the MaterialApp theme so
/// every existing `AppColors.x` reference follows the selected mode.
class AppColors {
  AppColors._();

  static AppPalette palette = AppPalette.light;

  static Color get primaryNavy => palette.primaryNavy;
  static Color get primaryDark => palette.primaryDark;
  static Color get accentGreen => palette.accentGreen;
  static Color get accentCyan => palette.accentCyan;
  static Color get accentLight => palette.accentLight;
  static Color get background => palette.background;
  static Color get surface => palette.surface;
  static Color get textPrimary => palette.textPrimary;
  static Color get textSecondary => palette.textSecondary;
  static Color get graphite => palette.graphite;
  static Color get electricMint => palette.electricMint;
  static Color get error => palette.error;
  static Color get warning => palette.warning;
  static Color get info => palette.info;
  static Color get border => palette.border;
  static Color get borderFocus => palette.borderFocus;
  static Color get gold => palette.gold;
  static Color get goldLight => palette.goldLight;
  static Color get goldDark => palette.goldDark;
  static Color get silver => palette.silver;
  static Color get silverLight => palette.silverLight;
  static Color get bronze => palette.bronze;
  static Color get bronzeLight => palette.bronzeLight;
  static Color get xpPurple => palette.xpPurple;
  static Color get xpPurpleLight => palette.xpPurpleLight;
  static Color get shadow => palette.shadow;
  static Color get shadowStrong => palette.shadowStrong;
  static Color get buttonDepthNavy => palette.buttonDepthNavy;
  static Color get buttonDepthGreen => palette.buttonDepthGreen;
  static Color get buttonDepthWhite => palette.buttonDepthWhite;
  static Color get glassSurface => palette.glassSurface;
  static Color get glassSurfaceDark => palette.glassSurfaceDark;
  static Color get glassBorder => palette.glassBorder;
  static Color get glassBorderDark => palette.glassBorderDark;
  static Color get ambientGreen => palette.ambientGreen;
  static Color get ambientCyan => palette.ambientCyan;
  static Color get ambientGold => palette.ambientGold;
}
