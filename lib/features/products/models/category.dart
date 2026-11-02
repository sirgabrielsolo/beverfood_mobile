import 'package:beverfood_mobile/core/formatting/category_name.dart';

/// A product category from the database (Acqua, Birre, Gin…), or one of the
/// two the web app adds: Novità (the products flagged new) and Promozioni.
class Category {
  const Category({required this.id, required this.name, required this.count});

  /// One entry of `categories` in `GET /api/v1/catalog`.
  factory Category.fromApi(Map<String, Object?> json) {
    final id = json['id'] as int;
    return Category(
      id: id,
      name: id == promoId
          ? 'Promozioni'
          : categoryLabel(json['name'] as String),
      count: json['count'] as int,
    );
  }

  /// beverfood_web's virtual NOVITÀ category: no product has it as its own.
  static const newId = 9090;

  /// The PROMO category, whose products are the promos (`/promos`).
  static const promoId = 99;

  final int id;

  /// For display: "Vini e spumanti", "Caffè".
  final String name;

  /// Active products (or promos) in it, never zero: the API leaves out empty
  /// categories.
  final int count;

  bool get isNew => id == newId;
  bool get isPromo => id == promoId;

  /// The photo bundled with the app (`beverfood_ops/scripts/category_images`).
  String get imageAsset => 'assets/images/categories/$id.webp';
}
