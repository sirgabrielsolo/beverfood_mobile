import 'package:beverfood_mobile/core/formatting/product_name.dart';

/// An order the client sent from the app, as `/api/v1/orders` returns it
/// (beverfood_web's `app_orders.py`). The list leaves out [lines], [notes]
/// and the address; the order page loads them.
class Order {
  const Order({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.itemCount,
    required this.subtotal,
    required this.vat,
    required this.total,
    this.fulfilledAt,
    this.notes,
    this.deliveryAddress,
    this.lines = const [],
  });

  factory Order.fromJson(Map<String, Object?> json) => Order(
    id: json['id'] as int,
    createdAt: DateTime.parse(json['created_at'] as String),
    status: json['status'] == 'fulfilled'
        ? OrderStatus.fulfilled
        : OrderStatus.sent,
    fulfilledAt: json['fulfilled_at'] == null
        ? null
        : DateTime.parse(json['fulfilled_at'] as String),
    itemCount: json['item_count'] as int,
    subtotal: (json['subtotal'] as num).toDouble(),
    vat: (json['vat'] as num).toDouble(),
    total: (json['total'] as num).toDouble(),
    notes: json['notes'] as String?,
    deliveryAddress: json['delivery_address'] as String?,
    lines: [
      for (final line in json['lines'] as List? ?? const [])
        OrderLine.fromJson(line as Map<String, Object?>),
    ],
  );

  final int id;

  /// When it was sent, Italian time.
  final DateTime createdAt;
  final OrderStatus status;
  final DateTime? fulfilledAt;

  /// Items counting quantities; a promo counts as one.
  final int itemCount;

  /// Net of IVA, the IVA, and both together, at the prices of the day it was
  /// sent.
  final double subtotal;
  final double vat;
  final double total;

  final String? notes;
  final String? deliveryAddress;

  /// Promos first, then by name.
  final List<OrderLine> lines;
}

/// What the client sees: "Inviato" until Beverfood marks it "Evaso" (the
/// managers' "In lavorazione" stays theirs, by the user's choice).
enum OrderStatus { sent, fulfilled }

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
    required this.iva,
    required this.isPromo,
    required this.available,
    this.mix = const [],
  });

  factory OrderLine.fromJson(Map<String, Object?> json) => OrderLine(
    productId: json['product_id'] as int,
    name: json['name'] as String,
    quantity: json['quantity'] as int,
    price: (json['price'] as num).toDouble(),
    iva: (json['iva'] as num).toDouble(),
    isPromo: json['is_promo'] as bool? ?? false,
    available: json['available'] as bool? ?? true,
    mix: [
      for (final item in json['mix'] as List? ?? const [])
        OrderMixItem.fromJson(item as Map<String, Object?>),
    ],
  );

  /// The database id.
  final int productId;

  /// As the database writes it ("BECK'S BT 330 ML 24 PZ").
  final String name;
  final int quantity;

  /// Net of IVA, as on the day it was sent.
  final double price;
  final double iva;
  final bool isPromo;

  /// Whether it's still sold, so it can be ordered again.
  final bool available;

  /// A promo's freely mixed groups, as the client chose them.
  final List<OrderMixItem> mix;

  ({String name, String pack}) get displayName => splitProductName(name);

  /// The mix, one line per group: "6 × Lilia Naturale, 4 × Lilia Gas",
  /// "Omaggio: 3 × Lilia Naturale".
  List<String> get mixLines {
    final groups = <int, List<OrderMixItem>>{};
    for (final item in mix) {
      (groups[item.group] ??= []).add(item);
    }
    return [
      for (final items in groups.values)
        (items.first.free ? 'Omaggio: ' : '') +
            items
                .map((i) => '${i.quantity} × ${splitProductName(i.name).name}')
                .join(', '),
    ];
  }
}

class OrderMixItem {
  const OrderMixItem({
    required this.group,
    required this.free,
    required this.productId,
    required this.name,
    required this.quantity,
  });

  factory OrderMixItem.fromJson(Map<String, Object?> json) => OrderMixItem(
    group: json['group'] as int,
    free: json['role'] == 'free',
    productId: json['product_id'] as int,
    name: json['name'] as String? ?? '',
    quantity: json['quantity'] as int,
  );

  final int group;
  final bool free;
  final int productId;
  final String name;
  final int quantity;

  Map<String, Object?> toJson() => {
    'group': group,
    'product_id': productId,
    'quantity': quantity,
  };
}
