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
        fontSize: 40,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
        color: textColor,
      ),
      displayMedium: GoogleFonts.unbounded(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.7,
        color: textColor,
      ),
      titleLarge: GoogleFonts.unbounded(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
        color: textColor,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.2,
        color: mutedColor,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: mutedColor,
      ),
    );
  }

  static OutlinedBorder get _squishyShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cornerRadiusLarge),
      );

  // LIGHT THEME
  static ThemeData get lightTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accentPink,
      onSecondary: AppColors.textMainLight,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.textMainLight,
      error: AppColors.error,
      onError: Colors.white,
      tertiary: AppColors.accentMint,
      onTertiary: AppColors.textMainLight,
      surfaceTint: AppColors.surfaceTint,
      outline: AppColors.outlineSoft,
      outlineVariant: AppColors.outlineSoft,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _buildTextTheme(
        AppColors.textMainLight,
        AppColors.textMutedLight,
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadiusMedium),
          side: BorderSide(
            color: AppColors.outlineSoft,
            width: 1.2,
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: _squishyShape,
          textStyle: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: _squishyShape,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        prefixIconColor: AppColors.textMutedLight,
        suffixIconColor: AppColors.textMutedLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadiusMedium),
          borderSide: BorderSide(color: AppColors.outlineSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadiusMedium),
          borderSide: BorderSide(color: AppColors.outlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadiusMedium),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textMutedLight,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textMutedLight.withValues(alpha: 0.75),
          fontWeight: FontWeight.w600,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textMainLight,
        ),
        iconTheme: IconThemeData(color: AppColors.textMainLight),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: AppColors.textMutedLight,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
      ),
    );
  }

  // DARK THEME
  static ThemeData get darkTheme {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.primary,
      onPrimary: Colors.white,
      secondary: AppColors.accentMint,
      onSecondary: AppColors.textMainDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.textMainDark,
      error: AppColors.error,
      onError: Colors.white,
      tertiary: AppColors.accentYellow,
      onTertiary: AppColors.textMainDark,
      surfaceTint: AppColors.surfaceDarkElevated,
      outline: Color(0x33FFFFFF),
      outlineVariant: Color(0x1FFFFFFF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: _buildTextTheme(
        AppColors.textMainDark,
        AppColors.textMutedDark,
      ),

      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: 0,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cornerRadiusMedium),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: _squishyShape,
          textStyle: GoogleFonts.sora(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDarkElevated,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        prefixIconColor: AppColors.textMutedDark,
        suffixIconColor: AppColors.textMutedDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadiusMedium),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadiusMedium),
          borderSide: BorderSide(
            color: Colors.white.withValues(alpha: 0.10),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(cornerRadiusMedium),
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textMutedDark,
          fontWeight: FontWeight.w600,
        ),
        floatingLabelStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.primarySoft,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: AppColors.textMutedDark.withValues(alpha: 0.85),
          fontWeight: FontWeight.w600,
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textMainDark,
        ),
        iconTheme: IconThemeData(color: AppColors.textMainDark),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: AppColors.textMutedDark,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: false,
      ),
    );
  }
}