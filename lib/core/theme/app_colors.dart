import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (From your image)
  static const Color primary = Color(0xFF134686);      // Deep Blue
  static const Color accentRed = Color(0xFFED3F27);    // Alert / Error / Delete
  static const Color accentYellow = Color(0xFFFEB21A); // Warning / Highlight
  
  // Neutral Colors (Light Mode)
  static const Color backgroundLight = Color(0xFFFDF4E3); // Cream
  static const Color surfaceLight = Color(0xFFFFFFFF);    // White Cards
  static const Color textMainLight = Color(0xFF134686);   // Using Primary for text is stylish
  static const Color textBodyLight = Color(0xFF1A1A1A);   // Standard black-ish
  static const Color grey = Color(0xFFC4BEB3);
  
  // Neutral Colors (Dark Mode - Derived)
  // Since you didn't provide Dark Mode colors, I generated these to match your vibe
  static const Color backgroundDark = Color(0xFF0F172A);  // Deep Navy/Black
  static const Color surfaceDark = Color(0xFF1E293B);     // Lighter Navy
  static const Color textMainDark = Color(0xFFFDF4E3);    // Using Cream for text in dark mode
}