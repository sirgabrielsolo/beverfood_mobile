import 'package:flutter_test/flutter_test.dart';

import 'package:beverfood_mobile/features/cart/data/cart_controller.dart';
import 'package:beverfood_mobile/features/cart/data/cart_storage.dart';
import 'package:beverfood_mobile/features/products/models/catalog.dart';
import 'package:beverfood_mobile/features/promotions/models/promo.dart';
import 'package:beverfood_mobile/features/promotions/models/promo_selection.dart';

Map<String, Object?> _json(int id, String name, double price, double iva) => {
  'id': id,
  'name': name,
  'price': price,
  'iva': iva,
  'image_url': '',
  'category': 'BIRRE',
  'category_id': 38,
};

Catalog _catalog(List<Map<String, Object?>> products) => Catalog.fromApi({
  'categories': const [],
  'products': products,
  'popular': const [],
  'new': const [],
});

final _becks = _json(6121, "BECK'S BT 330 ML 24 PZ", 18.42, 22);
final _pasta = _json(7001, 'PASTA DI GRAGNANO 500 GR', 2, 4);

const _naturale = PromoProduct(
  id: 5031,
  name: 'LILIA NATURALE 500 ML 24 PZ',
  price: 4.3,
  iva: 22,
  imageUrl: '',
);
const _gas = PromoProduct(
  id: 5032,
  name: 'LILIA GAS 500 ML 24 PZ',
  price: 4.3,
  iva: 22,
  imageUrl: '',
);

Promo _lilia({int paid = 10, double price = 43}) => Promo(
  id: 92,
  name: 'PROMO ACQUA LILIA 10 + 3',
  price: price,
  iva: 22,
  imageUrl: '',
  title: 'Acqua Lilia',
  highlight: '10+3',
  subtitle: '',
  groups: [
    PromoGroup(
      role: PromoRole.paid,
      mode: PromoMode.total,
      quantity: paid,
      products: const [_naturale, _gas],
    ),
    const PromoGroup(
      role: PromoRole.free,
      mode: PromoMode.total,
      quantity: 3,
      products: [_naturale, _gas],
    ),
  ],
);

PromoSelection _mix(Promo promo) => PromoSelection(
  promo,
).withCount(0, 5031, 6).withCount(0, 5032, 4).withCount(1, 5031, 3);

void main() {
  test('totals count each product at its own IVA rate', () {
    final cart = CartController(storage: MemoryCartStorage());
    final catalog = _catalog([_becks, _pasta]);
    cart
      ..setQuantity(catalog.productById('db-6121')!, 2)
      ..setQuantity(catalog.productById('db-7001')!, 10)
      ..putPromo(_mix(_lilia()));
    expect(cart.itemCount, 2 + 10 + 1);
    expect(cart.subtotal, closeTo(36.84 + 20 + 43, 1e-9));
    expect(cart.vat, closeTo(36.84 * .22 + 20 * .04 + 43 * .22, 1e-9));
    expect(cart.orderItems, [
      {
        'product_id': 92,
        'quantity': 1,
        'mix': [
          {'group': 0, 'product_id': 5031, 'quantity': 6},
          {'group': 0, 'product_id': 5032, 'quantity': 4},
          {'group': 1, 'product_id': 5031, 'quantity': 3},
        ],
      },
      {'product_id': 6121, 'quantity': 2},
      {'product_id': 7001, 'quantity': 10},
    ]);
  });

  test('a saved cart comes back and follows the catalogue', () async {
    final storage = MemoryCartStorage();
    final first = CartController(storage: storage);
    await first.restore();
    final catalog = _catalog([_becks, _pasta]);
    first
      ..setQuantity(catalog.productById('db-6121')!, 3)
      ..setQuantity(catalog.productById('db-7001')!, 5)
      ..putPromo(_mix(_lilia()))
      ..setNotes('Dopo le 10');
    await Future<void>.delayed(Duration.zero);

    final cart = CartController(storage: storage);
    await cart.restore();
    expect(cart.notes, 'Dopo le 10');
    expect(cart.isUpdating, isTrue);
    expect(cart.itemCount, 0);

    // The pasta is gone and Beck's costs more; the promo's price changed.
    cart.syncCatalog(_catalog([_json(6121, "BECK'S BT 330 ML 24 PZ", 19, 22)]));
    cart.syncPromos([_lilia(price: 45)]);
    expect(cart.isUpdating, isFalse);
    final lines = cart.productLines;
    expect(lines.map((l) => l.status), [
      CartLineStatus.ok,
      CartLineStatus.unavailable,
    ]);
    expect(lines.last.name, 'Pasta di Gragnano 500 g');
    expect(cart.subtotal, closeTo(3 * 19 + 45, 1e-9));
    expect(cart.orderItems.map((i) => i['product_id']), [92, 6121]);
  });

  test('a promo whose rule changed must be chosen again', () async {
    final storage = MemoryCartStorage();
    final first = CartController(storage: storage);
    await first.restore();
    first.putPromo(_mix(_lilia()));
    await Future<void>.delayed(Duration.zero);

    final cart = CartController(storage: storage);
    await cart.restore();
    // Now 12 paid: the saved 10 no longer complete it.
    cart.syncPromos([_lilia(paid: 12)]);
    expect(cart.promoLines.single.status, CartLineStatus.changed);
    expect(cart.promoSelection(92), isNull);
    expect(cart.orderItems, isEmpty);

    cart.syncPromos(const []);
    expect(cart.promoLines.single.status, CartLineStatus.unavailable);
  });

  test('a removed line goes back to its place', () {
    final cart = CartController(storage: MemoryCartStorage());
    final catalog = _catalog([_becks, _pasta, _json(1, 'ACQUA 1 LT', 1, 22)]);
    for (final id in ['db-6121', 'db-7001', 'db-1']) {
      cart.add(catalog.productById(id)!);
    }
    final removal = cart.remove('db-7001')!;
    expect(cart.productLines.map((l) => l.productId), ['db-6121', 'db-1']);
    cart.undoRemove(removal);
    expect(cart.productLines.map((l) => l.productId), [
      'db-6121',
      'db-7001',
      'db-1',
    ]);
  });

  test('quantities stay between 1 and 999; 0 takes the product out', () {
    final cart = CartController(storage: MemoryCartStorage());
    final becks = _catalog([_becks]).productById('db-6121')!;
    cart.setQuantity(becks, 5000);
    expect(cart.quantityOf(becks), CartController.maxQuantity);
    cart.setQuantity(becks, 0);
    expect(cart.isEmpty, isTrue);
  });

  test('a cleared cart is not brought back by a late restore', () async {
    final storage = MemoryCartStorage({
      'lines': [
        ['db-6121', 2, 'Beck'],
      ],
    });
    final cart = CartController(storage: storage);
    final restoring = cart.restore();
    cart.clear();
    await restoring;
    expect(cart.isEmpty, isTrue);
    expect(storage.saved, isNull);
  });

  test('an order mix rebuilds the promo, and contents describe it', () {
    final selection = PromoSelection.restore(
      _lilia(),
      mix: [
        {'group': 0, 'product_id': 5031, 'quantity': 6},
        {'group': 0, 'product_id': 5032, 'quantity': 4},
        {'group': 1, 'product_id': 5032, 'quantity': 3},
        // Not in the rule: ignored.
        {'group': 1, 'product_id': 6121, 'quantity': 3},
      ],
    );
    expect(selection.isComplete, isTrue);
    expect(selection.contents, [
      '6 × Lilia Naturale, 4 × Lilia Gas',
      'Omaggio: 3 × Lilia Gas',
    ]);
    expect(
      PromoSelection.restore(
        _lilia(),
        saved: selection.toJson(),
      ).sameChoicesAs(selection),
      isTrue,
    );
  });
}
