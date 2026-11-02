import 'package:flutter/material.dart';

/// Brand colors, shared by the light and dark themes. Colors that change with
/// the theme live in [AppPalette].
abstract final class AppColors {
  /// Brand red, used for filled elements (buttons, stepper, badges) and for
  /// the Home header in both themes. For brand-colored text and icons use
  /// `context.palette.brandText`, which is lighter in dark mode.
  static const brand = Color(0xFFC8174A);
  static const onBrand = Colors.white;

  /// Yellow used for the main promo card and the "NUOVO" badge.
  static const accent = Color(0xFFFFC93C);
  static const onAccent = Color(0xFF1A1718);

  /// Text on the dark secondary promo cards.
  static const onPromoAlt = Colors.white;
}
