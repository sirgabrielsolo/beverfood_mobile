import 'package:beverfood_mobile/core/formatting/product_name.dart';

enum ProductCategory {
  wine('Vini'),
  beer('Birre'),
  cocktail('Cocktail'),
  coffee('Caffè e tè'),
  softDrink('Analcolici'),
  food('Gastronomia');

  const ProductCategory(this.label);

  final String label;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.category,
    this.format = '',
    this.isNew = false,
    this.isPopular = false,
    this.isCutout = false,
  });

  /// A product from beverfood_web's API (`_product_json` in `api.py`). The
  /// agent-style name ("GIN NORDES 3 LT") is shown through
  /// [splitProductName]: "Gin Nordes 3 l".
  factory Product.fromApi(Map<String, Object?> json) {
    final split = splitProductName(json['name'] as String);
    return Product(
      // Prefixed so it never meets a sample product's id in the cart.
      id: 'db-${json['id']}',
      name: split.pack.isEmpty ? split.name : '${split.name} ${split.pack}',
      price: (json['price'] as num).toDouble(),
      imageUrl: json['image_url'] as String? ?? '',
      format: split.pack,
      isNew: json['is_new'] as bool? ?? false,
      isCutout: true,
    );
  }

  final String id;
  final String name;

  /// One of the sample categories; null for products from the database,
  /// whose categories (ACQUA, BIBITE…) come with the full catalogue.
  final ProductCategory? category;

  /// Price net of IVA.
  final double price;
  final String imageUrl;

  /// Package size, e.g. `75 cl` or `500 ml · 24 pz`.
  final String format;

  final bool isNew;
  final bool isPopular;

  /// A transparent cut-out (the database's Cloudinary PNGs): drawn whole on
  /// a light backdrop rather than cropped like the sample photos.
  final bool isCutout;
}
