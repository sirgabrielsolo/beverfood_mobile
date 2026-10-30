import 'package:flutter/material.dart';

/// Brand colors, shared by the light and dark themes. Colors that change with
/// the theme live in [AppPalette].
abstract final class AppColors {
  /// Bordeaux, the brand color.
  static const primary = Color(0xFF7B1E3A);

  /// Lighter bordeaux, readable on the dark theme's near-black surfaces.
  static const primaryOnDark = Color(0xFFC94471);

  /// Amber used for promo highlights and the selected filter chip.
  static const accent = Color(0xFFF5B83D);
  static const onAccent = Color(0xFF1F1F24);
}
