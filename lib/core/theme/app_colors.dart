import 'package:flutter/material.dart';

/// Centralized color system for Cohabit's
/// playful, neo‑bento aesthetic.
class AppColors {
  // BRAND CORE
  static const Color primary = Color(0xFF6F5BFF); // Squishy lavender
  static const Color primarySoft = Color(0xFFE6E2FF);

  // ACCENTS (inspired by Moimoi bubbles)
  static const Color accentPink = Color(0xFFFF8FB7);
  static const Color accentYellow = Color(0xFFFFE58A);
  static const Color accentMint = Color(0xFF7DEFCB);
  static const Color accentBlue = Color(0xFF74D8FF);
  static const Color accentRed = Color(0xFFFF5C5C);

  // LIGHT MODE NEUTRALS
  static const Color backgroundLight = Color(0xFFFFF7FD); // Soft lilac / cream
  static const Color surfaceLight = Color(0xFFFFFFFF); // High elevation cards
  static const Color surfaceTint = Color(0xFFF7F1FF); // Subtle tinted cards
  static const Color textMainLight = Color(0xFF1F1534); // Deep ink
  static const Color textMutedLight = Color(0xFF7B6E9A);
  static const Color outlineSoft = Color(0xFFE2DAF9);

  // DARK MODE NEUTRALS
  static const Color backgroundDark = Color(0xFF080814);
  static const Color surfaceDark = Color(0xFF141428);
  static const Color surfaceDarkElevated = Color(0xFF201F3A);
  static const Color textMainDark = Color(0xFFF3ECFF);
  static const Color textMutedDark = Color(0xFFB0A7D9);

  // UTILITIES
  static const Color success = Color(0xFF4CD97B);
  static const Color warning = accentYellow;
  static const Color error = accentRed;
}