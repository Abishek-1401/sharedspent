import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- COLOR PALETTE ---
  static const Color creamBackground = Color(0xFFFDF4E3);
  static const Color deepBlue = Color(0xFF134686);
  static const Color accentRed = Color(0xFFED3F27);
  static const Color accentYellow = Color(0xFFFEB21A);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color neutralGray = Color(0xFFC4BEB3);

  // --- DARK MODE PALETTE ---
  static const Color darkBackground = Color(0xFF1E1E24);
  static const Color darkSurface = Color(0xFF2B2D42);
  static const Color electricBlue = Color(0xFF4A90E2); 

  // --- DIMENSIONS ---
  static const double borderRadius = 18.0; 

  // --- TEXT THEME GENERATOR ---
  static TextTheme _buildTextTheme(Color textColor) {
    return TextTheme(
      // Unbounded: Headlines
      displayLarge: GoogleFonts.unbounded(
          fontSize: 32, fontWeight: FontWeight.w900, color: textColor),
      displayMedium: GoogleFonts.unbounded(
          fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
      
      // Sora: UI Body
      bodyLarge: GoogleFonts.sora(
          fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
      bodyMedium: GoogleFonts.sora(
          fontSize: 14, fontWeight: FontWeight.w400, color: textColor),
      
      // Roboto Mono: Data/Numbers
      labelLarge: GoogleFonts.robotoMono(
          fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
      labelMedium: GoogleFonts.robotoMono(
          fontSize: 12, fontWeight: FontWeight.w500, 
          color: textColor.withValues(alpha: 0.8)), // FIXED: withValues
    );
  }

  // --- LIGHT THEME ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: creamBackground,
      primaryColor: deepBlue,
      colorScheme: const ColorScheme.light(
        primary: deepBlue,
        secondary: accentRed,
        surface: pureWhite,
        error: accentRed,
        tertiary: accentYellow,
      ),
      
      textTheme: _buildTextTheme(deepBlue),

      // FIXED: CardThemeData
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 0, 
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: neutralGray, width: 1),
        ),
        margin: const EdgeInsets.all(8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepBlue,
          foregroundColor: pureWhite,
          elevation: 0, // Flat is cleaner
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: pureWhite,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: neutralGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: neutralGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: deepBlue, width: 2),
        ),
        labelStyle: GoogleFonts.sora(color: deepBlue.withValues(alpha: 0.7)), // FIXED: withValues
      ),
    );
  }

  // --- DARK THEME ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: electricBlue,
      colorScheme: const ColorScheme.dark(
        primary: electricBlue,
        secondary: accentRed, 
        surface: darkSurface,
        tertiary: accentYellow,
      ),

      textTheme: _buildTextTheme(const Color(0xFFEAEAEA)), 

      // FIXED: CardThemeData
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide.none, 
        ),
        margin: const EdgeInsets.all(8),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: electricBlue,
          foregroundColor: darkBackground, 
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          borderSide: const BorderSide(color: electricBlue, width: 2),
        ),
        labelStyle: GoogleFonts.sora(color: Colors.white70),
      ),
    );
  }
}