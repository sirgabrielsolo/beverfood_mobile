import 'package:beverfood_mobile/core/network/unsplash.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/promotions/models/promo.dart';

/// In-memory promotions. Swap for an API-backed implementation once the
/// backend is available.
class PromoRepository {
  const PromoRepository();

  List<Promo> getActivePromos() => _promos;
}

final _promos = [
  Promo(
    id: 'wine-week',
    highlight: 'Fino al -30%',
    title: 'Settimana del vino',
    subtitle: 'Rossi, bianchi e bollicine selezionati',
    imageUrl: unsplashImage('1510812431401-41d2bd2722f3', width: 1000),
    category: ProductCategory.wine,
  ),
  Promo(
    id: 'craft-beer',
    highlight: '-20%',
    title: 'Birre artigianali',
    subtitle: 'Solo per questo weekend',
    imageUrl: unsplashImage('1584225064785-c62a8b43d148', width: 1000),
    category: ProductCategory.beer,
  ),
  Promo(
    id: 'aperitivo',
    highlight: '3x2',
    title: 'Aperitivo in casa',
    subtitle: 'Sui kit cocktail pronti',
    imageUrl: unsplashImage('1551024709-8f23befc6f87', width: 1000),
    category: ProductCategory.cocktail,
  ),
  Promo(
    id: 'coffee-break',
    highlight: '-15%',
    title: 'Pausa caffè',
    subtitle: 'Miscele, grani e tè',
    imageUrl: unsplashImage('1495474472287-4d71bcdd2085', width: 1000),
    category: ProductCategory.coffee,
  ),
];
