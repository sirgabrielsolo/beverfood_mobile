import 'package:flutter_test/flutter_test.dart';

import 'package:beverfood_mobile/core/formatting/category_name.dart';
import 'package:beverfood_mobile/core/network/cloudinary.dart';
import 'package:beverfood_mobile/features/products/models/catalog.dart';
import 'package:beverfood_mobile/features/products/models/category.dart';
import 'package:beverfood_mobile/features/products/models/product_sort.dart';

Map<String, Object?> _product(int id, String name, double price, int cat) => {
  'id': id,
  'name': name,
  'price': price,
  'iva': 22.0,
  'image_url': 'https://res.cloudinary.com/x/image/upload/v1/$id.png',
  'is_new': id == 5182,
  'category': cat == 37 ? 'BIBITE' : 'BIRRE',
  'category_id': cat,
};

final _catalog = Catalog.fromApi({
  'categories': [
    {'id': 9090, 'name': 'NOVITÀ', 'count': 1},
    {'id': 99, 'name': 'PROMO', 'count': 7},
    {'id': 37, 'name': 'BIBITE', 'count': 3},
    {'id': 38, 'name': 'BIRRE', 'count': 2},
  ],
  'products': [
    _product(6121, "BECK'S BT 330 ML 24 PZ", 18.42, 38),
    _product(6151, 'CERES BT 330 ML 24 PZ', 32.96, 38),
    _product(5121, 'COCA COLA LAT 330 ML 24 PZ', 13.93, 37),
    _product(5181, "ESTATHE' LIMONE LAT 330 ML 24 PZ", 19.44, 37),
    _product(5182, "ESTATHE' PESCA LAT 330ML 24 PZ", 19.44, 37),
  ],
  'popular': [6151, 5121, 6121],
  'new': [5182],
});

List<String> _names(Iterable<Object> products) => [
  for (final p in products) (p as dynamic).name as String,
];

void main() {
  test('category names read like an Italian shop', () {
    expect(categoryLabel('VINI E SPUMANTI'), 'Vini e spumanti');
    expect(categoryLabel("CAFFE'"), 'Caffè');
    expect(categoryLabel("SPECIALITA'"), 'Specialità');
    expect(categoryLabel('NOVITÀ'), 'Novità');
    expect(_catalog.categories.map((c) => c.name), [
      'Novità',
      'Promozioni',
      'Bibite',
      'Birre',
    ]);
    expect(
      _catalog.categories.first.imageAsset,
      'assets/images/categories/9090.webp',
    );
  });

  test('Cloudinary photos are asked for at card size, in WebP', () {
    expect(
      cloudinaryThumbnail(
        'https://res.cloudinary.com/x/image/upload/v1/6121.png',
      ),
      'https://res.cloudinary.com/x/image/upload/w_400,c_limit,f_webp,q_auto/v1/6121.png',
    );
    expect(
      cloudinaryThumbnail('https://example.com/a.png'),
      'https://example.com/a.png',
    );
    expect(_catalog.products.first.imageUrl, contains('/w_400,'));
  });

  test('Più popolari: ranked first, the rest by name', () {
    expect(_names(_catalog.search()), [
      'Ceres bottiglia 330 ml · 24 pz',
      'Coca Cola lattina 330 ml · 24 pz',
      "Beck's bottiglia 330 ml · 24 pz",
      'Estathè Limone lattina 330 ml · 24 pz',
      'Estathè Pesca lattina 330 ml · 24 pz',
    ]);
    expect(_names(_catalog.popular(limit: 2)), [
      'Ceres bottiglia 330 ml · 24 pz',
      'Coca Cola lattina 330 ml · 24 pz',
    ]);
  });

  test('prices sort with ties by name', () {
    expect(_names(_catalog.search(sort: ProductSort.priceDescending)).take(3), [
      'Ceres bottiglia 330 ml · 24 pz',
      'Estathè Limone lattina 330 ml · 24 pz',
      'Estathè Pesca lattina 330 ml · 24 pz',
    ]);
  });

  test('search ignores accents and needs every word', () {
    expect(_names(_catalog.search(query: 'estathe pesca')), [
      'Estathè Pesca lattina 330 ml · 24 pz',
    ]);
    expect(_names(_catalog.search(query: "ESTATHE'")).length, 2);
    // The category name counts too.
    expect(_catalog.search(query: 'birre').length, 2);
  });

  test('a category, and Novità, filter the products', () {
    expect(_catalog.search(categoryId: 38).length, 2);
    expect(_names(_catalog.search(categoryId: Category.newId)), [
      'Estathè Pesca lattina 330 ml · 24 pz',
    ]);
    expect(_names(_catalog.newArrivals), [
      'Estathè Pesca lattina 330 ml · 24 pz',
    ]);
  });
}
