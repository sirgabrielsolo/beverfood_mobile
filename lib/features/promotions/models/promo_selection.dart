import 'package:flutter/foundation.dart';

import 'package:beverfood_mobile/features/promotions/models/promo.dart';

/// What the client picked for a promo's freely mixed groups (`PromoMode.total`,
/// e.g. Lilia: 10 among naturale and gas). Groups of `PromoMode.each` are
/// fixed and need no choice. Immutable: changes return a new selection.
@immutable
class PromoSelection {
  PromoSelection(this.promo)
    : _counts = List.filled(promo.groups.length, const {});

  const PromoSelection._(this.promo, this._counts);

  final Promo promo;

  /// Per group, product id → count. Empty for `each` groups.
  final List<Map<int, int>> _counts;

  /// How many of [productId] the bundle holds in group [group].
  int countOf(int group, int productId) {
    final g = promo.groups[group];
    return g.mode == PromoMode.each
        ? g.quantity
        : _counts[group][productId] ?? 0;
  }

  /// Items the group holds in all, when complete.
  int required(int group) {
    final g = promo.groups[group];
    return g.mode == PromoMode.each
        ? g.quantity * g.products.length
        : g.quantity;
  }

  int chosen(int group) {
    if (promo.groups[group].mode == PromoMode.each) return required(group);
    return _counts[group].values.fold(0, (sum, count) => sum + count);
  }

  int remaining(int group) => required(group) - chosen(group);

  /// The first group still missing items, if any.
  ({PromoGroup group, int remaining})? get firstMissing {
    for (var i = 0; i < promo.groups.length; i++) {
      if (remaining(i) > 0) {
        return (group: promo.groups[i], remaining: remaining(i));
      }
    }
    return null;
  }

  bool get isComplete => firstMissing == null;

  /// Sets the count of [productId] in the freely mixed group [group], kept
  /// between zero and what the group still has room for.
  PromoSelection withCount(int group, int productId, int count) {
    assert(promo.groups[group].mode == PromoMode.total);
    final current = countOf(group, productId);
    final max = current + remaining(group);
    final counts = [for (final map in _counts) Map.of(map)];
    final clamped = count.clamp(0, max);
    if (clamped == 0) {
      counts[group].remove(productId);
    } else {
      counts[group][productId] = clamped;
    }
    return PromoSelection._(promo, counts);
  }

  /// The bundle at catalogue prices, paid and free items together. Items not
  /// chosen yet count at the group's first product's price.
  double get listValue {
    var value = 0.0;
    for (var i = 0; i < promo.groups.length; i++) {
      final g = promo.groups[i];
      for (final product in g.products) {
        value += countOf(i, product.id) * product.price;
      }
      if (g.products.isNotEmpty) value += remaining(i) * g.products.first.price;
    }
    return value;
  }

  /// What the client saves against buying everything at catalogue prices.
  double get savings => listValue - promo.price;

  /// The client's mix, for the order notes the manager reads, e.g.
  /// `PROMO ACQUA LILIA 10 + 3 — pagati: 6 × LILIA NATURALE 500 ML 24 PZ;
  /// omaggio: 3 × LILIA GAS 500 ML 24 PZ`. Null when nothing was chosen
  /// (only fixed groups). Database names, as the manager knows them.
  String? get orderNote {
    final parts = <String>[];
    for (var i = 0; i < promo.groups.length; i++) {
      final g = promo.groups[i];
      if (g.mode != PromoMode.total) continue;
      final items = [
        for (final product in g.products)
          if (countOf(i, product.id) > 0)
            '${countOf(i, product.id)} × ${product.name}',
      ];
      final label = g.role == PromoRole.free ? 'omaggio' : 'pagati';
      parts.add('$label: ${items.join(', ')}');
    }
    if (parts.isEmpty) return null;
    return '${promo.name} — ${parts.join('; ')}';
  }

  /// Whether [other] holds the same choices for the same promo.
  bool sameChoicesAs(PromoSelection other) {
    if (other.promo.id != promo.id) return false;
    for (var i = 0; i < _counts.length; i++) {
      if (!mapEquals(_counts[i], other._counts[i])) return false;
    }
    return true;
  }
}
