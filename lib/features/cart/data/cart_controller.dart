import 'package:flutter/widgets.dart';

import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/promotions/models/promo_selection.dart';

/// Product quantities and promos in the cart.
///
/// A promo is in the cart at most once per order, with the client's mix
/// ([PromoSelection]); at checkout it becomes one order line, and its mix goes
/// into the order notes for the manager.
///
/// In memory only for now, so the cart is empty again after a restart.
/// The cart page, the "Vai al carrello" bar and the nav badge aren't wired to
/// it yet.
class CartController extends ChangeNotifier {
  final _lines = <String, ({Product product, int quantity})>{};
  final _promos = <int, PromoSelection>{};

  int quantityOf(Product product) => _lines[product.id]?.quantity ?? 0;

  /// Total number of items, counting quantities; a promo counts as one.
  int get itemCount =>
      _lines.values.fold(0, (sum, line) => sum + line.quantity) +
      _promos.length;

  double get total =>
      _lines.values.fold(
        0.0,
        (sum, line) => sum + line.product.price * line.quantity,
      ) +
      _promos.values.fold(0.0, (sum, s) => sum + s.promo.price);

  /// The promo's mix in the cart, or null when it isn't in the cart.
  PromoSelection? promoSelection(int promoId) => _promos[promoId];

  /// Puts a complete promo in the cart, replacing its earlier mix.
  void putPromo(PromoSelection selection) {
    assert(selection.isComplete);
    _promos[selection.promo.id] = selection;
    notifyListeners();
  }

  void removePromo(int promoId) {
    if (_promos.remove(promoId) != null) notifyListeners();
  }

  void add(Product product) {
    _lines[product.id] = (product: product, quantity: quantityOf(product) + 1);
    notifyListeners();
  }

  /// Removes one unit; the product leaves the cart at zero.
  void removeOne(Product product) {
    final quantity = quantityOf(product);
    if (quantity == 0) return;
    if (quantity == 1) {
      _lines.remove(product.id);
    } else {
      _lines[product.id] = (product: product, quantity: quantity - 1);
    }
    notifyListeners();
  }
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
}
