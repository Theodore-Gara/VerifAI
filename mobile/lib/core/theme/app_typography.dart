import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0E1B2A),
          letterSpacing: -1.0,
          height: 1.15,
        ),
        displayMedium: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0E1B2A),
          letterSpacing: -0.8,
          height: 1.2,
        ),
        displaySmall: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0E1B2A),
          letterSpacing: -0.6,
          height: 1.25,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0E1B2A),
          letterSpacing: -0.5,
          height: 1.3,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF0E1B2A),
          letterSpacing: -0.4,
          height: 1.35,
        ),
        headlineSmall: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0E1B2A),
          letterSpacing: -0.3,
          height: 1.4,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
          letterSpacing: -0.2,
          height: 1.4,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
          letterSpacing: -0.1,
          height: 1.4,
        ),
        titleSmall: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
          letterSpacing: 0.0,
          height: 1.4,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF111827),
          letterSpacing: -0.1,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF111827),
          letterSpacing: 0.0,
          height: 1.5,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF475569),
          letterSpacing: 0.0,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF111827),
          letterSpacing: 0.1,
          height: 1.4,
        ),
        labelMedium: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF475569),
          letterSpacing: 0.3,
          height: 1.4,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF64748B),
          letterSpacing: 0.6,
          height: 1.3,
        ),
      );
}