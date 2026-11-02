/// A PROMO product from the web app's database (category 99), with how the
/// app presents it. See `/api/v1/promos` in beverfood_web (`api.py`,
/// `promos.py`).
class Promo {
  const Promo({
    required this.id,
    required this.name,
    required this.price,
    required this.iva,
    required this.imageUrl,
    required this.title,
    required this.highlight,
    required this.subtitle,
    this.description,
    this.bannerUrl,
    this.groups = const [],
  });

  factory Promo.fromJson(Map<String, Object?> json) {
    final name = json['name'] as String;
    return Promo(
      id: json['id'] as int,
      name: name,
      price: (json['price'] as num).toDouble(),
      iva: (json['iva'] as num).toDouble(),
      imageUrl: json['image_url'] as String? ?? '',
      // A promo the server has no texts for yet falls back to its name.
      title: json['title'] as String? ?? name,
      highlight: json['highlight'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      description: json['description'] as String?,
      bannerUrl: json['banner_url'] as String?,
      groups: [
        for (final group in json['groups'] as List? ?? const [])
          PromoGroup.fromJson(group as Map<String, Object?>),
      ],
    );
  }

  final int id;

  /// The product name in the database, e.g. `PROMO PEPSI 5 + 1`.
  final String name;

  /// Price net of IVA, and the IVA rate in percent, as in the agents' app.
  final double price;
  final double iva;

  /// The square promo image (also the web catalogue's product image).
  final String imageUrl;

  /// Banner texts, e.g. "Pepsi", "5+1", "Una Pepsi Zero in omaggio". With a
  /// [bannerUrl] they are drawn in the image and serve as its description.
  final String title;
  final String highlight;
  final String subtitle;
  final String? description;

  /// The wide 300×124 banner (900×372 px). Without one the app draws a text
  /// banner from [title], [highlight] and [subtitle].
  final String? bannerUrl;

  /// What the promo covers: the products paid and the ones given free.
  final List<PromoGroup> groups;
}

enum PromoRole { paid, free }

/// How a group's [PromoGroup.quantity] applies to its products.
enum PromoMode {
  /// That many of every product listed (Estathè: one of each flavour).
  each,

  /// That many in all, freely mixed among the products listed (Lilia: ten
  /// among naturale and gas).
  total,
}

class PromoGroup {
  const PromoGroup({
    required this.role,
    required this.mode,
    required this.quantity,
    required this.products,
  });

  factory PromoGroup.fromJson(Map<String, Object?> json) => PromoGroup(
    role: PromoRole.values.byName(json['role'] as String),
    mode: PromoMode.values.byName(json['mode'] as String),
    quantity: json['quantity'] as int,
    products: [
      for (final product in json['products'] as List)
        PromoProduct.fromJson(product as Map<String, Object?>),
    ],
  );

  final PromoRole role;
  final PromoMode mode;
  final int quantity;
  final List<PromoProduct> products;
}

/// A product a promo covers, as the catalogue lists it.
class PromoProduct {
  const PromoProduct({
    required this.id,
    required this.name,
    required this.price,
    required this.iva,
    required this.imageUrl,
  });

  factory PromoProduct.fromJson(Map<String, Object?> json) => PromoProduct(
    id: json['id'] as int,
    name: json['name'] as String,
    price: (json['price'] as num).toDouble(),
    iva: (json['iva'] as num).toDouble(),
    imageUrl: json['image_url'] as String? ?? '',
  );

  final int id;
  final String name;
  final double price;
  final double iva;
  final String imageUrl;
}
