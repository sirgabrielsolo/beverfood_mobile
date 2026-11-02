import 'package:beverfood_mobile/core/formatting/search_text.dart';
import 'package:beverfood_mobile/features/products/models/category.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/models/product_sort.dart';

/// The whole catalogue (`GET /api/v1/catalog`): ~1200 products, small enough
/// to search, filter and sort on the phone.
class Catalog {
  Catalog({
    required this.categories,
    required this.products,
    required List<String> popularIds,
    required List<String> newIds,
  }) : _popularRank = {for (final (i, id) in popularIds.indexed) id: i},
       _newIds = newIds;

  factory Catalog.fromApi(Map<String, Object?> json) {
    String productId(Object? id) => 'db-$id';
    return Catalog(
      categories: [
        for (final c in json['categories'] as List)
          Category.fromApi(c as Map<String, Object?>),
      ],
      products: [
        for (final p in json['products'] as List)
          Product.fromApi(p as Map<String, Object?>),
      ],
      popularIds: [for (final id in json['popular'] as List) productId(id)],
      newIds: [for (final id in json['new'] as List) productId(id)],
    );
  }

  /// Novità and Promozioni first (when they have products), then by name.
  final List<Category> categories;

  /// Every product but the promos, by name.
  final List<Product> products;

  final Map<String, int> _popularRank;
  final List<String> _newIds;

  late final Map<String, Product> _byId = {for (final p in products) p.id: p};

  Category? categoryById(int id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  /// The products flagged new, newest first.
  late final List<Product> newArrivals = [
    for (final id in _newIds)
      if (_byId[id] case final product?) product,
  ];

  /// The [limit] most ordered products, most ordered first.
  List<Product> popular({int limit = 20}) => _sorted(
    products.where((p) => _popularRank.containsKey(p.id)),
    ProductSort.popular,
  ).take(limit).toList();

  /// The products of [categoryId] (all when null; Novità's when
  /// [Category.newId]) whose name or category contain every word of
  /// [query], accents ignored, sorted by [sort].
  List<Product> search({
    String query = '',
    int? categoryId,
    ProductSort sort = ProductSort.popular,
  }) {
    final words = searchText(
      query,
    ).split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final isNew = categoryId == Category.newId;
    final found = products.where(
      (p) =>
          (categoryId == null ||
              (isNew ? p.isNew : p.categoryId == categoryId)) &&
          words.every(p.searchKey.contains),
    );
    return _sorted(found, sort);
  }

  /// Names without accents, for sorting by name.
  late final Map<String, String> _nameKey = {
    for (final p in products) p.id: searchText(p.name),
  };

  List<Product> _sorted(Iterable<Product> products, ProductSort sort) {
    int rank(Product p) => _popularRank[p.id] ?? _popularRank.length;
    int byName(Product a, Product b) =>
        _nameKey[a.id]!.compareTo(_nameKey[b.id]!);
    // List.sort isn't stable: ties fall back to the name explicitly.
    int then(int result, Product a, Product b) =>
        result != 0 ? result : byName(a, b);

    return products.toList()..sort(
      (a, b) => switch (sort) {
        ProductSort.popular => then(rank(a).compareTo(rank(b)), a, b),
        ProductSort.priceAscending => then(a.price.compareTo(b.price), a, b),
        ProductSort.priceDescending => then(b.price.compareTo(a.price), a, b),
        ProductSort.name => byName(a, b),
      },
    );
  }
}
