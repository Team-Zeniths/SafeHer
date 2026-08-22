import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Builds the app's [TextTheme] on top of Material 3's type scale using
/// the 'Poppins' family for headings/titles and 'Inter' for body copy —
/// a common professional pairing (display font + readable body font).
class AppTextStyles {
  AppTextStyles._();

  static TextTheme textTheme(Color onSurface) {
    final base = GoogleFonts.interTextTheme();
    final display = GoogleFonts.poppinsTextTheme();

    return base
        .copyWith(
          displayLarge: display.displayLarge?.copyWith(fontWeight: FontWeight.w600),
          displayMedium: display.displayMedium?.copyWith(fontWeight: FontWeight.w600),
          displaySmall: display.displaySmall?.copyWith(fontWeight: FontWeight.w600),
          headlineLarge: display.headlineLarge?.copyWith(fontWeight: FontWeight.w600),
          headlineMedium: display.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
          headlineSmall: display.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          titleLarge: display.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          titleMedium: display.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          titleSmall: display.titleSmall?.copyWith(fontWeight: FontWeight.w500),
          bodyLarge: base.bodyLarge?.copyWith(fontWeight: FontWeight.w400, height: 1.4),
          bodyMedium: base.bodyMedium?.copyWith(fontWeight: FontWeight.w400, height: 1.4),
          bodySmall: base.bodySmall?.copyWith(fontWeight: FontWeight.w400, height: 1.3),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(
          bodyColor: onSurface,
          displayColor: onSurface,
        );
  }
}
