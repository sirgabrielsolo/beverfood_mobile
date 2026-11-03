import 'dart:math';

import 'package:flutter/widgets.dart';

import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/orders/models/order.dart';

/// The client's orders, through beverfood_web's `/api/v1/orders`.
class OrderRepository {
  OrderRepository(this._api);

  final ApiClient _api;

  /// Bumped after each order sent, so an order list already open reloads.
  final sent = ValueNotifier<int>(0);

  /// A fresh id for one send. The same id sent again (a retry after a
  /// timeout) gets the order already made rather than a second one.
  static String newRequestId() {
    final random = Random.secure();
    return List.generate(
      16,
      (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  /// Sends the cart. Throws [ApiException]: `unavailable` (with
  /// `product_ids`), `below_minimum`, `cannot_order`, `bad_promo`…
  Future<Order> send({
    required String requestId,
    required String notes,
    required List<Map<String, Object?>> items,
  }) async {
    final json =
        await _api.postJson('/api/v1/orders', {
              'request_id': requestId,
              'notes': notes,
              'items': items,
            })
            as Map<String, Object?>;
    sent.value++;
    return Order.fromJson(json['order'] as Map<String, Object?>);
  }

  /// The newest first, without their lines.
  Future<List<Order>> list() async {
    final json = await _api.getJson('/api/v1/orders') as Map<String, Object?>;
    return [
      for (final order in json['orders'] as List)
        Order.fromJson(order as Map<String, Object?>),
    ];
  }

  Future<Order> get(int id) async {
    final json =
        await _api.getJson('/api/v1/orders/$id') as Map<String, Object?>;
    return Order.fromJson(json['order'] as Map<String, Object?>);
  }
}

/// Exposes the app's [OrderRepository]; `BeverfoodApp` owns it.
class OrderRepositoryScope extends InheritedWidget {
  const OrderRepositoryScope({
    super.key,
    required this.repository,
    required super.child,
  });

  final OrderRepository repository;

  static OrderRepository of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<OrderRepositoryScope>()!.repository;

  @override
  bool updateShouldNotify(OrderRepositoryScope oldWidget) =>
      repository != oldWidget.repository;
}
