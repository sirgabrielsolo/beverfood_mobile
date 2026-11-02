import 'package:beverfood_mobile/core/network/unsplash.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/models/product_sort.dart';

/// In-memory catalogue. Swap for an API-backed implementation once the
/// backend is available; the public methods are what the UI relies on.
class ProductRepository {
  const ProductRepository();

  List<Product> getAll() => _products;

  List<Product> getNewArrivals() => _products.where((p) => p.isNew).toList();

  List<Product> getPopular() => _products.where((p) => p.isPopular).toList();

  List<Product> search({
    String query = '',
    ProductCategory? category,
    ProductSort sort = ProductSort.recommended,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final results = _products.where((p) {
      final matchesCategory = category == null || p.category == category;
      final matchesQuery =
          normalizedQuery.isEmpty ||
          p.name.toLowerCase().contains(normalizedQuery) ||
          p.category.label.toLowerCase().contains(normalizedQuery);
      return matchesCategory && matchesQuery;
    }).toList();

    return switch (sort) {
      ProductSort.recommended => results,
      ProductSort.popular => _stableSorted(
        results,
        (a, b) => _rank(b.isPopular) - _rank(a.isPopular),
      ),
      ProductSort.priceAscending => _stableSorted(
        results,
        (a, b) => a.price.compareTo(b.price),
      ),
      ProductSort.priceDescending => _stableSorted(
        results,
        (a, b) => b.price.compareTo(a.price),
      ),
      ProductSort.name => _stableSorted(
        results,
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      ),
    };
  }

  /// Cover image for a category tile.
  String categoryImageUrl(ProductCategory category) {
    return unsplashImage(_categoryPhotoIds[category]!, size: 200);
  }

  static int _rank(bool value) => value ? 1 : 0;

  /// Sorts by [compare], keeping the catalogue order among equal items
  /// (`List.sort` isn't stable).
  static List<Product> _stableSorted(
    List<Product> products,
    int Function(Product a, Product b) compare,
  ) {
    final position = {for (final (i, p) in products.indexed) p.id: i};
    return [...products]..sort((a, b) {
      final result = compare(a, b);
      return result != 0 ? result : position[a.id]! - position[b.id]!;
    });
  }
}

const _categoryPhotoIds = {
  ProductCategory.wine: '1586370434639-0fe43b2d32e6',
  ProductCategory.beer: '1608270586620-248524c67de9',
  ProductCategory.cocktail: '1513558161293-cdaf765ed2fd',
  ProductCategory.coffee: '1559056199-641a0ac8b55e',
  ProductCategory.softDrink: '1600271886742-f049cd451bba',
  ProductCategory.food: '1486297678162-eb2a19b0a32d',
};

final _products = [
  // Novità
  Product(
    id: 'n1',
    name: "Montepulciano d'Abruzzo DOC",
    category: ProductCategory.wine,
    price: 9.90,
    format: '75 cl',
    imageUrl: unsplashImage('1586370434639-0fe43b2d32e6'),
    isNew: true,
  ),
  Product(
    id: 'n2',
    name: 'Caffè in grani Arabica',
    category: ProductCategory.coffee,
    price: 12.50,
    format: '1 kg',
    imageUrl: unsplashImage('1559056199-641a0ac8b55e'),
    isNew: true,
  ),
  Product(
    id: 'n3',
    name: 'Olio extravergine di oliva',
    category: ProductCategory.food,
    price: 14.90,
    format: '1 L',
    imageUrl: unsplashImage('1474979266404-7eaacbcd87c5'),
    isNew: true,
  ),
  Product(
    id: 'n4',
    name: 'Birra artigianale bionda',
    category: ProductCategory.beer,
    price: 3.80,
    format: '50 cl',
    imageUrl: unsplashImage('1608270586620-248524c67de9'),
    isNew: true,
  ),
  Product(
    id: 'n5',
    name: "Succo d'arancia 100%",
    category: ProductCategory.softDrink,
    price: 2.90,
    format: '1 L',
    imageUrl: unsplashImage('1600271886742-f049cd451bba'),
    isNew: true,
  ),
  Product(
    id: 'n6',
    name: 'Miele di acacia',
    category: ProductCategory.food,
    price: 7.50,
    format: '500 g',
    imageUrl: unsplashImage('1558642452-9d2a7deb7f62'),
    isNew: true,
  ),

  // Più popolari
  Product(
    id: 'p1',
    name: 'Rosé Spumante Brut',
    category: ProductCategory.wine,
    price: 13.90,
    format: '75 cl',
    imageUrl: unsplashImage('1547595628-c61a29f496f0'),
    isPopular: true,
  ),
  Product(
    id: 'p2',
    name: 'Chianti Classico DOCG',
    category: ProductCategory.wine,
    price: 16.50,
    format: '75 cl',
    imageUrl: unsplashImage('1474722883778-792e7990302f'),
    isPopular: true,
  ),
  Product(
    id: 'p3',
    name: 'Box degustazione vini',
    category: ProductCategory.wine,
    price: 39.00,
    format: '4 x 37,5 cl',
    imageUrl: unsplashImage('1568213816046-0ee1c42bd559'),
    isPopular: true,
  ),
  Product(
    id: 'p4',
    name: 'Birra Lager chiara',
    category: ProductCategory.beer,
    price: 2.40,
    format: '33 cl',
    imageUrl: unsplashImage('1566633806327-68e152aaf26d'),
    isPopular: true,
  ),
  Product(
    id: 'p5',
    name: 'Fusto IPA',
    category: ProductCategory.beer,
    price: 34.90,
    format: '5 L',
    imageUrl: unsplashImage('1535958636474-b021ee887b13'),
    isPopular: true,
  ),
  Product(
    id: 'p6',
    name: 'Kit Mojito',
    category: ProductCategory.cocktail,
    price: 24.90,
    format: '4 drink',
    imageUrl: unsplashImage('1513558161293-cdaf765ed2fd'),
    isPopular: true,
  ),
  Product(
    id: 'p7',
    name: 'Kit Margarita',
    category: ProductCategory.cocktail,
    price: 26.90,
    format: '4 drink',
    imageUrl: unsplashImage('1544145945-f90425340c7e'),
    isPopular: true,
  ),
  Product(
    id: 'p8',
    name: 'Old Fashioned pronto da bere',
    category: ProductCategory.cocktail,
    price: 8.90,
    format: '20 cl',
    imageUrl: unsplashImage('1514362545857-3bc16c4c7d1b'),
    isPopular: true,
  ),
  Product(
    id: 'p9',
    name: 'Miscela Espresso Bar',
    category: ProductCategory.coffee,
    price: 6.90,
    format: '250 g',
    imageUrl: unsplashImage('1509042239860-f550ce710b93'),
    isPopular: true,
  ),
  Product(
    id: 'p10',
    name: 'Tè verde Sencha',
    category: ProductCategory.coffee,
    price: 5.40,
    format: '100 g',
    imageUrl: unsplashImage('1564890369478-c89ca6d9cde9'),
    isPopular: true,
  ),
  Product(
    id: 'p11',
    name: 'Limonata alla fragola',
    category: ProductCategory.softDrink,
    price: 2.20,
    format: '33 cl',
    imageUrl: unsplashImage('1497534446932-c925b458314e'),
    isPopular: true,
  ),
  Product(
    id: 'p12',
    name: 'Tè freddo al limone',
    category: ProductCategory.softDrink,
    price: 1.90,
    format: '50 cl',
    imageUrl: unsplashImage('1556679343-c7306c1976bc'),
    isPopular: true,
  ),
  Product(
    id: 'p13',
    name: 'Acqua minerale naturale',
    category: ProductCategory.softDrink,
    price: 0.60,
    format: '1,5 L',
    imageUrl: unsplashImage('1523362628745-0c100150b504'),
    isPopular: true,
  ),
  Product(
    id: 'p14',
    name: 'Gorgonzola DOP',
    category: ProductCategory.food,
    price: 6.80,
    format: '250 g',
    imageUrl: unsplashImage('1452195100486-9cc805987862'),
    isPopular: true,
  ),
  Product(
    id: 'p15',
    name: 'Pecorino stagionato',
    category: ProductCategory.food,
    price: 11.20,
    format: '500 g',
    imageUrl: unsplashImage('1486297678162-eb2a19b0a32d'),
    isPopular: true,
  ),
  Product(
    id: 'p16',
    name: 'Cioccolato fondente 70%',
    category: ProductCategory.food,
    price: 3.50,
    format: '100 g',
    imageUrl: unsplashImage('1606312619070-d48b4c652a52'),
    isPopular: true,
  ),
];
