import 'package:beverfood_mobile/features/products/models/product.dart';

class Promo {
  const Promo({
    required this.id,
    required this.highlight,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.category,
  });

  final String id;

  /// Short eye-catching text shown in the accent color, e.g. `-20%`.
  final String highlight;
  final String title;
  final String subtitle;
  final String imageUrl;

  /// Category the promo links to, if any.
  final ProductCategory? category;
}
