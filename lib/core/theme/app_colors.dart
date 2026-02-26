import 'package:flutter/material.dart';

/// Centralized color system for Cohabit's
/// playful, neo‑bento aesthetic.
class AppColors {
  // BRAND CORE
  static const Color primary = Color(0xFF7B66FF); 
  static const Color primarySoft = Color(0xFFF0EDFF);

  // PASTEL BENTO PALETTE
  static const Color bentoMint = Color(0xFFB4F2E1);
  static const Color bentoSalmon = Color(0xFFFFB5A7);
  static const Color bentoLilac = Color(0xFFE2D1F9);
  static const Color bentoLemon = Color(0xFFFFF4B5);
  static const Color bentoBlue = Color(0xFFAED9E0);

  // ACCENTS
  static const Color accentPink = Color(0xFFFF6B9E);
  static const Color accentYellow = Color(0xFFFFD95A);
  static const Color accentMint = Color(0xFF63E6BE);
  static const Color accentBlue = Color(0xFF4FC3F7);
  static const Color accentRed = Color(0xFFFF4D4D);

  // LIGHT MODE NEUTRALS
  static const Color backgroundLight = Color(0xFFFEF9FF); 
  static const Color surfaceLight = Color(0xFFFFFFFF); 
  static const Color textMainLight = Color(0xFF1A122E); 
  static const Color textMutedLight = Color(0xFF8A7DA6);
  static const Color outlineSoft = Color(0xFFEEE9FF);

  // DARK MODE NEUTRALS
  static const Color backgroundDark = Color(0xFF0B0B1E);
  static const Color surfaceDark = Color(0xFF16162F);
  static const Color surfaceDarkElevated = Color(0xFF232244);
  static const Color textMainDark = Color(0xFFF8F4FF);
  static const Color textMutedDark = Color(0xFFA59CCF);

  // UTILITIES
  static const Color success = Color(0xFF4CD97B);
  static const Color warning = accentYellow;
  static const Color error = accentRed;
}