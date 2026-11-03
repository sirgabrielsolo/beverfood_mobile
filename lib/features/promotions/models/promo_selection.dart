import 'package:flutter/foundation.dart';

import 'package:beverfood_mobile/core/formatting/product_name.dart';
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

  /// The choices, to keep the cart across restarts: per group, product id
  /// → count (empty for fixed groups).
  List<Map<String, int>> toJson() => [
    for (final counts in _counts)
      {for (final MapEntry(:key, :value) in counts.entries) '$key': value},
  ];

  /// The choices saved by [toJson], or listed by `mix` (an order's freely
  /// mixed groups: `[{group, product_id, quantity}]`), applied to [promo] as
  /// it is now. Counts the rule no longer allows are dropped, so the result
  /// may be incomplete: the promo then needs choosing again.
  factory PromoSelection.restore(Promo promo, {Object? saved, Object? mix}) {
    var selection = PromoSelection(promo);
    void apply(int group, int productId, int count) {
      if (group < 0 || group >= promo.groups.length) return;
      final g = promo.groups[group];
      if (g.mode != PromoMode.total) return;
      if (!g.products.any((p) => p.id == productId)) return;
      selection = selection.withCount(
        group,
        productId,
        selection.countOf(group, productId) + count,
      );
    }

    if (saved is List) {
      for (final (group, counts) in saved.indexed) {
        if (counts is! Map) continue;
        for (final MapEntry(:key, :value) in counts.entries) {
          final id = int.tryParse('$key');
          if (id != null && value is int) apply(group, id, value);
        }
      }
    }
    if (mix is List) {
      for (final entry in mix.whereType<Map>()) {
        final (group, id, count) = (
          entry['group'],
          entry['product_id'],
          entry['quantity'],
        );
        if (group is int && id is int && count is int) apply(group, id, count);
      }
    }
    return selection;
  }

  /// The freely mixed groups' choices, as the order API wants them.
  List<Map<String, int>> get apiMix => [
    for (final (i, group) in promo.groups.indexed)
      if (group.mode == PromoMode.total)
        for (final product in group.products)
          if (countOf(i, product.id) > 0)
            {
              'group': i,
              'product_id': product.id,
              'quantity': countOf(i, product.id),
            },
  ];

  /// What the bundle holds, one line per group for the cart and the order
  /// summary: "6 × Lilia Naturale, 4 × Lilia Gas", "Omaggio: 3 × Lilia
  /// Naturale".
  List<String> get contents => [
    for (final (i, group) in promo.groups.indexed)
      if (group.products.any((p) => countOf(i, p.id) > 0))
        (group.role == PromoRole.free ? 'Omaggio: ' : '') +
            [
              for (final product in group.products)
                if (countOf(i, product.id) > 0)
                  '${countOf(i, product.id)} × '
                      '${splitProductName(product.name).name}',
            ].join(', '),
  ];

  /// Whether [other] holds the same choices for the same promo.
  bool sameChoicesAs(PromoSelection other) {
    if (other.promo.id != promo.id) return false;
    for (var i = 0; i < _counts.length; i++) {
      if (!mapEquals(_counts[i], other._counts[i])) return false;
    }
    return true;
  }
}
