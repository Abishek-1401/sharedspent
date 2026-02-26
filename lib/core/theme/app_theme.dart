import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Cohabit's playful Neo‑Bento theme.
class AppTheme {
  // DIMENSIONS
  static const double cornerRadiusLarge = 32.0;
  static const double cornerRadiusMedium = 24.0;

  // TEXT THEME
  static TextTheme _buildTextTheme(Color textColor, Color mutedColor) {
    return TextTheme(
      displayLarge: GoogleFonts.unbounded(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.2,
        color: textColor,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.unbounded(
        fontSize: 36,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
        color: textColor,
        height: 1.1,
      ),
      displaySmall: GoogleFonts.unbounded(
        fontSize: 24,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.5,
        color: textColor,
      ),
      titleLarge: GoogleFonts.unbounded(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: 0.2,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        height: 1.4,
        color: mutedColor,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: textColor,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: mutedColor,
      ),
    );
  }

  static OutlinedBorder get squishyShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadiusLarge),
      );

  // LIGHT THEME
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      surface: AppColors.surfaceLight,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: _buildTextTheme(
        AppColors.textMainLight,
        AppColors.textMutedLight,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.outlineSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.outlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  // DARK THEME
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.dark,
      primary: AppColors.primary,
      surface: AppColors.surfaceDark,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: _buildTextTheme(
        AppColors.textMainDark,
        AppColors.textMutedDark,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}