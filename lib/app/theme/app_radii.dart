import 'package:flutter/widgets.dart';

/// Corner radii, kept small and consistent across the app.
abstract final class AppRadii {
  /// Product cards, promo banners, category tiles and settings cards.
  static const card = BorderRadius.all(Radius.circular(10));

  /// Images inside cards and tiles.
  static const image = BorderRadius.all(Radius.circular(8));

  /// Search bars and other text fields.
  static const field = BorderRadius.all(Radius.circular(10));

  /// Icon buttons, the add-to-cart button and the quantity stepper.
  static const button = BorderRadius.all(Radius.circular(10));

  /// Small labels on images, e.g. "NUOVO".
  static const badge = BorderRadius.all(Radius.circular(4));

  /// Bottom corners of the Home header.
  static const header = BorderRadius.vertical(bottom: Radius.circular(10));
}
