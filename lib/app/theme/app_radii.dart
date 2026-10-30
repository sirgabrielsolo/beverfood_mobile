import 'package:flutter/widgets.dart';

/// Corner radii, kept small and consistent across the app.
abstract final class AppRadii {
  /// Promo banners and settings cards.
  static const card = BorderRadius.all(Radius.circular(10));

  /// Product images.
  static const image = BorderRadius.all(Radius.circular(8));

  /// Search bars and other text fields.
  static const field = BorderRadius.all(Radius.circular(10));
}
