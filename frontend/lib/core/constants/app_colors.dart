import 'package:flutter/material.dart';

/// Centralized color palette for SafeHer.
///
/// The primary brand color is a warm pink (#E91E63) that conveys
/// confidence, energy and warmth — fitting for a women's safety app.
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFE91E63);
  static const Color primaryDark = Color(0xFFAD1457);
  static const Color primaryLight = Color(0xFFF8BBD0);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF0288D1);

  // SOS / emergency accent
  static const Color sosRed = Color(0xFFD32F2F);
  static const Color sosRedDark = Color(0xFF8E0000);

  // Light theme neutrals
  static const Color lightBackground = Color(0xFFFDF7F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightOnSurface = Color(0xFF1C1B1F);
  static const Color lightOutline = Color(0xFFE0E0E0);

  // Dark theme neutrals
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkOnSurface = Color(0xFFF2F2F2);
  static const Color darkOutline = Color(0xFF3A3A3A);

  // Text helpers
  static const Color textMutedLight = Color(0xFF6F6F6F);
  static const Color textMutedDark = Color(0xFFA8A8A8);
}
