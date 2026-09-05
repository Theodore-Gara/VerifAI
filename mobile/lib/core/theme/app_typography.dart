import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => GoogleFonts.manropeTextTheme().copyWith(
        displayLarge: GoogleFonts.manrope(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0E1B2A),
          height: 1.2,
        ),
        displayMedium: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0E1B2A),
          height: 1.3,
        ),
        displaySmall: GoogleFonts.manrope(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0E1B2A),
          height: 1.3,
        ),
        headlineLarge: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0E1B2A),
          height: 1.4,
        ),
        headlineMedium: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0E1B2A),
          height: 1.4,
        ),
        headlineSmall: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF0E1B2A),
          height: 1.5,
        ),
        titleLarge: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
          height: 1.5,
        ),
        titleMedium: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
          height: 1.5,
        ),
        titleSmall: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF475569),
          height: 1.5,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF111827),
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF111827),
          height: 1.6,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: const Color(0xFF475569),
          height: 1.6,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF111827),
          height: 1.5,
        ),
        labelMedium: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF475569),
          height: 1.5,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: const Color(0xFF64748B),
          height: 1.5,
        ),
      );
}