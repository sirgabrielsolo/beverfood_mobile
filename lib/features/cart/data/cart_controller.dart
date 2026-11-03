import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:beverfood_mobile/features/cart/data/cart_storage.dart';
import 'package:beverfood_mobile/features/products/models/catalog.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/promotions/models/promo.dart';
import 'package:beverfood_mobile/features/promotions/models/promo_selection.dart';

/// Where a cart line stands against the catalogue.
enum CartLineStatus {
  /// In the catalogue: counted and ordered.
  ok,

  /// Restored after a restart; the catalogue (or the promos) isn't loaded yet.
  loading,

  /// No longer sold: shown as "Non più disponibile", left out of the order.
  unavailable,

  /// A promo whose rule changed, so the saved mix no longer fits: it has to
  /// be chosen again. Left out of the order until then.
  changed,
}

/// A product line of the cart. [product] is null only while [status] is
/// `loading` or `unavailable` for a product restored from a previous launch.
class CartProductLine {
  const CartProductLine({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.status,
    this.product,
  });

  final String productId;
  final String name;
  final int quantity;
  final CartLineStatus status;
  final Product? product;
}

/// A promo in the cart, with the client's mix ([selection], complete when
/// [status] is `ok`).
class CartPromoLine {
  const CartPromoLine({
    required this.promoId,
    required this.name,
    required this.status,
    this.selection,
  });

  final int promoId;
  final String name;
  final CartLineStatus status;
  final PromoSelection? selection;
}

/// Product quantities, promos and the client's notes for Beverfood.
///
/// A promo is in the cart at most once per order, with the client's mix
/// ([PromoSelection]); at checkout it becomes one order line carrying its mix.
///
/// The cart is saved on the device ([CartStorage], F1) and restored at the
/// next launch: it keeps product ids, so prices always come from the current
/// catalogue ([syncCatalog]), and a product no longer sold stays in the list
/// as unavailable, left out of the totals and the order (F4). It is emptied
/// on sign-out and once an order is sent.
class CartController extends ChangeNotifier {
  CartController({CartStorage storage = const PreferencesCartStorage()})
    : _storage = storage;

  static const maxQuantity = 999;

  final CartStorage _storage;

  /// Product id → quantity, in the order they were added.
  final _quantities = <String, int>{};

  /// The latest catalogue data of each product in the cart.
  final _products = <String, Product>{};

  /// Names of restored products, shown until (or unless) the catalogue has
  /// them.
  final _names = <String, String>{};
  final _unavailable = <String>{};

  final _promos = <int, _PromoEntry>{};
  String _notes = '';

  /// Loads the current promos, for [reloadPromos]; set by `BeverfoodApp`.
  Future<List<Promo>> Function()? promoLoader;
  var _promosFailed = false;

  /// Bumped by [clear], so a restore still reading storage doesn't bring an
  /// emptied cart back.
  var _generation = 0;
  var _restored = false;

  // ── Reading ─────────────────────────────────────────────────────────────

  int quantityOf(Product product) => _quantities[product.id] ?? 0;

  bool get isEmpty => _quantities.isEmpty && _promos.isEmpty;

  String get notes => _notes;

  List<CartProductLine> get productLines => [
    for (final MapEntry(key: id, value: quantity) in _quantities.entries)
      CartProductLine(
        productId: id,
        name: _products[id]?.name ?? _names[id] ?? '',
        quantity: quantity,
        product: _products[id],
        status: _unavailable.contains(id)
            ? CartLineStatus.unavailable
            : _products.containsKey(id)
            ? CartLineStatus.ok
            : CartLineStatus.loading,
      ),
  ];

  List<CartPromoLine> get promoLines => [
    for (final MapEntry(key: id, value: entry) in _promos.entries)
      CartPromoLine(
        promoId: id,
        name: entry.name,
        status: entry.status,
        selection: entry.selection,
      ),
  ];

  /// Lines still waiting for the catalogue or the promos.
  bool get isUpdating =>
      productLines.any((l) => l.status == CartLineStatus.loading) ||
      _promos.values.any((e) => e.status == CartLineStatus.loading);

  /// The promos in the cart couldn't be brought up to date.
  bool get promosFailed => _promosFailed && _promos.isNotEmpty;

  Iterable<({double price, double iva, int quantity})> get _counted sync* {
    for (final line in productLines) {
      if (line.status == CartLineStatus.ok) {
        final p = line.product!;
        yield (price: p.price, iva: p.iva, quantity: line.quantity);
      }
    }
    for (final entry in _promos.values) {
      if (entry.status == CartLineStatus.ok) {
        final promo = entry.selection!.promo;
        yield (price: promo.price, iva: promo.iva, quantity: 1);
      }
    }
  }

  /// Items that will be ordered, counting quantities; a promo counts as one.
  int get itemCount => _counted.fold(0, (sum, l) => sum + l.quantity);

  /// Net of IVA, what will be ordered.
  double get subtotal =>
      _counted.fold(0.0, (sum, l) => sum + l.price * l.quantity);

  /// The IVA on [subtotal], each product at its own rate.
  double get vat =>
      _counted.fold(0.0, (sum, l) => sum + l.price * l.quantity * l.iva / 100);

  /// The promo's mix in the cart, or null when it isn't there complete.
  PromoSelection? promoSelection(int promoId) {
    final entry = _promos[promoId];
    return entry?.status == CartLineStatus.ok ? entry!.selection : null;
  }

  /// The lines to order, as the order API wants them: products still sold,
  /// complete promos.
  List<Map<String, Object?>> get orderItems => [
    for (final entry in _promos.values)
      if (entry.status == CartLineStatus.ok)
        {
          'product_id': entry.selection!.promo.id,
          'quantity': 1,
          'mix': entry.selection!.apiMix,
        },
    for (final line in productLines)
      if (line.status == CartLineStatus.ok)
        {'product_id': line.product!.dbId, 'quantity': line.quantity},
  ];

  // ── Products ────────────────────────────────────────────────────────────

  void add(Product product) => setQuantity(product, quantityOf(product) + 1);

  /// Removes one unit; the product leaves the cart at zero.
  void removeOne(Product product) {
    final quantity = quantityOf(product);
    if (quantity > 0) setQuantity(product, quantity - 1);
  }

  /// Sets the quantity (F3), up to [maxQuantity]; zero takes the product out.
  void setQuantity(Product product, int quantity) {
    final clamped = quantity.clamp(0, maxQuantity);
    if (clamped == 0) {
      if (_quantities.remove(product.id) == null) return;
      _forget(product.id);
    } else {
      if (_quantities[product.id] == clamped) return;
      _quantities[product.id] = clamped;
      _products[product.id] = product;
      _unavailable.remove(product.id);
    }
    _changed();
  }

  /// Takes a line out of the cart, in whatever state it is, and returns
  /// what [undoRemove] needs to put it back where it was.
  CartRemoval? remove(String productId) {
    final index = _quantities.keys.toList().indexOf(productId);
    if (index < 0) return null;
    final removal = CartRemoval._(
      index: index,
      productId: productId,
      quantity: _quantities[productId]!,
      product: _products[productId],
      name: _products[productId]?.name ?? _names[productId] ?? '',
      unavailable: _unavailable.contains(productId),
    );
    _quantities.remove(productId);
    _forget(productId);
    _changed();
    return removal;
  }

  void undoRemove(CartRemoval removal) {
    if (_quantities.containsKey(removal.productId)) return;
    final entries = _quantities.entries.toList()
      ..insert(
        removal.index.clamp(0, _quantities.length),
        MapEntry(removal.productId, removal.quantity),
      );
    _quantities
      ..clear()
      ..addEntries(entries);
    if (removal.product case final product?) {
      _products[removal.productId] = product;
    }
    _names[removal.productId] = removal.name;
    if (removal.unavailable) _unavailable.add(removal.productId);
    _changed();
  }

  void _forget(String productId) {
    _products.remove(productId);
    _names.remove(productId);
    _unavailable.remove(productId);
  }

  // ── Promos ──────────────────────────────────────────────────────────────

  /// Puts a complete promo in the cart, replacing its earlier mix.
  void putPromo(PromoSelection selection) {
    assert(selection.isComplete);
    _promos[selection.promo.id] = _PromoEntry.ok(selection);
    _changed();
  }

  /// Takes the promo out; the returned line puts it back with [undoRemovePromo].
  CartPromoRemoval? removePromo(int promoId) {
    final index = _promos.keys.toList().indexOf(promoId);
    final entry = _promos.remove(promoId);
    if (entry == null) return null;
    _changed();
    return CartPromoRemoval._(index, promoId, entry);
  }

  void undoRemovePromo(CartPromoRemoval removal) {
    if (_promos.containsKey(removal.promoId)) return;
    final entries = _promos.entries.toList()
      ..insert(
        removal.index.clamp(0, _promos.length),
        MapEntry(removal.promoId, removal._entry),
      );
    _promos
      ..clear()
      ..addEntries(entries);
    _changed();
  }

  // ── Notes, emptying ─────────────────────────────────────────────────────

  /// The client's notes for Beverfood (N1), kept with the cart until the
  /// order is sent. Saved without rebuilding the listeners, as it's typed.
  void setNotes(String notes) {
    if (notes == _notes) return;
    _notes = notes;
    _save();
  }

  /// Empties the cart and its notes: after an order, on sign-out, or from
  /// "Svuota carrello".
  void clear() {
    _generation++;
    _restored = true;
    final wasEmpty = isEmpty && _notes.isEmpty;
    _quantities.clear();
    _products.clear();
    _names.clear();
    _unavailable.clear();
    _promos.clear();
    _notes = '';
    _storage.write(null);
    if (!wasEmpty) notifyListeners();
  }

  // ── Following the catalogue ─────────────────────────────────────────────

  /// Brings the cart up to date with a (re)loaded catalogue: current prices
  /// and names, and products no longer sold marked unavailable. Prices change
  /// silently, by the user's choice.
  void syncCatalog(Catalog catalog) {
    for (final id in _quantities.keys) {
      final product = catalog.productById(id);
      if (product == null) {
        _unavailable.add(id);
        _names[id] = _products[id]?.name ?? _names[id] ?? '';
        _products.remove(id);
      } else {
        _products[id] = product;
        _unavailable.remove(id);
      }
    }
    _changed();
  }

  /// Rebinds the promos in the cart to the current [promos]: a promo no
  /// longer offered becomes unavailable, one whose rule no longer fits its
  /// saved mix has to be chosen again.
  void syncPromos(List<Promo> promos) {
    final byId = {for (final promo in promos) promo.id: promo};
    for (final MapEntry(key: id, value: entry) in _promos.entries.toList()) {
      final promo = byId[id];
      if (promo == null) {
        _promos[id] = entry.withStatus(CartLineStatus.unavailable);
        continue;
      }
      final selection = PromoSelection.restore(
        promo,
        saved: entry.selection?.toJson() ?? entry.saved,
      );
      _promos[id] = selection.isComplete
          ? _PromoEntry.ok(selection)
          : _PromoEntry(
              name: promo.displayName,
              status: CartLineStatus.changed,
              saved: entry.selection?.toJson() ?? entry.saved,
            );
    }
    notifyListeners();
  }

  /// Loads the promos with [promoLoader] and applies them ([syncPromos]),
  /// when the cart holds any.
  Future<void> reloadPromos() async {
    final loader = promoLoader;
    if (loader == null || _promos.isEmpty) return;
    try {
      final promos = await loader();
      _promosFailed = false;
      syncPromos(promos);
    } on Exception catch (error) {
      debugPrint('Cart promos not updated: $error');
      _promosFailed = true;
      notifyListeners();
    }
  }

  /// Marks products the server says are no longer sold (an order refused
  /// with `unavailable`), by database id.
  void markUnavailable(Iterable<int> dbIds) {
    for (final dbId in dbIds) {
      final id = 'db-$dbId';
      if (_quantities.containsKey(id)) {
        _unavailable.add(id);
        _names[id] = _products[id]?.name ?? _names[id] ?? '';
        _products.remove(id);
      }
      if (_promos[dbId] case final entry?) {
        _promos[dbId] = entry.withStatus(CartLineStatus.unavailable);
      }
    }
    _changed();
  }

  // ── Saving ──────────────────────────────────────────────────────────────

  /// Restores the cart saved at the last launch. Its lines wait (`loading`)
  /// for [syncCatalog] and [syncPromos].
  Future<void> restore() async {
    final generation = _generation;
    final saved = await _storage.read();
    if (generation != _generation || _restored) return;
    _restored = true;
    if (saved == null) {
      _save();
      return;
    }
    for (final line in saved['lines'] as List? ?? const []) {
      if (line case [
        final String id,
        final int quantity,
        final String name,
      ] when quantity > 0 && !_quantities.containsKey(id)) {
        _quantities[id] = quantity.clamp(1, maxQuantity);
        _names[id] = name;
      }
    }
    for (final promo in saved['promos'] as List? ?? const []) {
      if (promo case {
        'id': final int id,
        'name': final String name,
      } when !_promos.containsKey(id)) {
        _promos[id] = _PromoEntry(
          name: name,
          status: CartLineStatus.loading,
          saved: promo['counts'],
        );
      }
    }
    _notes = saved['notes'] as String? ?? _notes;
    _changed();
  }

  void _changed() {
    notifyListeners();
    _save();
  }

  void _save() {
    // Changes made before the restore finished are merged into it.
    if (!_restored) return;
    if (isEmpty && _notes.isEmpty) {
      unawaited(_storage.write(null));
      return;
    }
    unawaited(
      _storage.write({
        'lines': [
          for (final line in productLines)
            [line.productId, line.quantity, line.name],
        ],
        'promos': [
          for (final MapEntry(key: id, value: entry) in _promos.entries)
            {
              'id': id,
              'name': entry.name,
              'counts': entry.selection?.toJson() ?? entry.saved,
            },
        ],
        'notes': _notes,
      }),
    );
  }
}

class _PromoEntry {
  const _PromoEntry({required this.name, required this.status, this.saved})
    : selection = null;

  _PromoEntry.ok(PromoSelection this.selection)
    : name = selection.promo.displayName,
      status = CartLineStatus.ok,
      saved = null;

  final String name;
  final CartLineStatus status;
  final PromoSelection? selection;

  /// The saved mix ([PromoSelection.toJson]) while the promo isn't loaded.
  final Object? saved;

  _PromoEntry withStatus(CartLineStatus status) => _PromoEntry(
    name: name,
    status: status,
    saved: selection?.toJson() ?? saved,
  );
}

/// A product line taken out of the cart, for "Annulla".
class CartRemoval {
  const CartRemoval._({
    required this.index,
    required this.productId,
    required this.quantity,
    required this.product,
    required this.name,
    required this.unavailable,
  });

  final int index;
  final String productId;
  final int quantity;
  final Product? product;
  final String name;
  final bool unavailable;
}

/// A promo taken out of the cart, for "Annulla".
class CartPromoRemoval {
  const CartPromoRemoval._(this.index, this.promoId, this._entry);

  final int index;
  final int promoId;
  final _PromoEntry _entry;
}

/// Makes the [CartController] available to the widget tree.
class CartScope extends InheritedNotifier<CartController> {
  const CartScope({
    super.key,
    required CartController controller,
    required super.child,
  }) : super(notifier: controller);

  static CartController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<CartScope>()!.notifier!;
  }

  /// Without listening, for callbacks.
  static CartController read(BuildContext context) {
    return context.getInheritedWidgetOfExactType<CartScope>()!.notifier!;
  }
}
