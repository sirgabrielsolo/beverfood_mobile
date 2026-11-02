import 'package:beverfood_mobile/core/formatting/product_name.dart';
import 'package:beverfood_mobile/core/formatting/search_text.dart';
import 'package:beverfood_mobile/core/network/cloudinary.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageUrl,
    this.categoryId,
    this.categoryName = '',
    this.format = '',
    this.isNew = false,
    this.isCutout = false,
    this.searchKey = '',
  });

  /// A product from beverfood_web's API (`_product_json` in `api.py`). The
  /// agent-style name ("GIN NORDES 3 LT") is shown through
  /// [splitProductName]: "Gin Nordes 3 l".
  factory Product.fromApi(Map<String, Object?> json) {
    final raw = json['name'] as String;
    final split = splitProductName(raw);
    final name = split.pack.isEmpty
        ? split.name
        : '${split.name} ${split.pack}';
    final category = json['category'] as String? ?? '';
    return Product(
      id: 'db-${json['id']}',
      name: name,
      price: (json['price'] as num).toDouble(),
      imageUrl: cloudinaryThumbnail(json['image_url'] as String? ?? ''),
      categoryId: json['category_id'] as int?,
      categoryName: category,
      format: split.pack,
      isNew: json['is_new'] as bool? ?? false,
      isCutout: true,
      // The ERP name too, so "lat" or "bt" still find the product.
      searchKey: searchText('$name $raw $category'),
    );
  }

  /// `db-<database id>`.
  final String id;
  final String name;

  /// The database category (`id_category`), as in `Category.id`.
  final int? categoryId;

  /// The category as the database writes it ("BIRRE").
  final String categoryName;

  /// Price net of IVA.
  final double price;
  final String imageUrl;

  /// Package size, e.g. `75 cl` or `500 ml · 24 pz`.
  final String format;

  final bool isNew;

  /// A transparent cut-out (the database's Cloudinary PNGs): drawn whole on
  /// a light backdrop rather than cropped.
  final bool isCutout;

  /// Name, ERP name and category, lower case without accents, for search.
  final String searchKey;
}
