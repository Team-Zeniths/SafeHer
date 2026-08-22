/// Consistent spacing, radius and sizing tokens used across the app.
///
/// Using a single source of truth keeps paddings, gaps and corner
/// radii visually consistent on every screen.
class AppSizes {
  AppSizes._();

  // Spacing scale (4pt grid)
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  // Corner radius
  static const double radiusSm = 8;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusPill = 100;

  // Component sizing
  static const double buttonHeight = 54;
  static const double inputHeight = 56;
  static const double iconSm = 18;
  static const double iconMd = 24;
  static const double iconLg = 32;
  static const double avatarSm = 36;
  static const double avatarMd = 56;
  static const double avatarLg = 96;

  // Max content width for responsive/web layouts
  static const double maxContentWidth = 480;
}

/// Standard animation durations for consistent motion feel.
class AppDurations {
  AppDurations._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration splash = Duration(milliseconds: 2200);
}
