import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/formatting/date_format.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/core/widgets/empty_state.dart';
import 'package:beverfood_mobile/core/widgets/load_error_row.dart';
import 'package:beverfood_mobile/core/widgets/net_price_text.dart';
import 'package:beverfood_mobile/features/orders/data/order_repository.dart';
import 'package:beverfood_mobile/features/orders/models/order.dart';
import 'package:beverfood_mobile/features/orders/presentation/widgets/order_status_pill.dart';

/// "I miei ordini" (O1), from Profilo: number, date, items, total and
/// status, newest first.
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrderRepository _repository;
  List<Order>? _orders;
  String? _error;

  @override
  void initState() {
    super.initState();
    // An order sent while this page stays open behind it reloads the list.
    _repository = OrderRepositoryScope.of(context)..sent.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    _repository.sent.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final orders = await _repository.list();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orders = _orders;
    return Scaffold(
      appBar: AppBar(title: const Text('I miei ordini')),
      body: switch ((orders, _error)) {
        (null, null) => const Center(child: CircularProgressIndicator()),
        (null, final String _) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Align(
            alignment: Alignment.topCenter,
            child: LoadErrorRow(
              message: 'Ordini non disponibili',
              onRetry: () {
                setState(() => _error = null);
                _load();
              },
            ),
          ),
        ),
        (final List<Order> list, _) when list.isEmpty => EmptyState(
          icon: Icons.receipt_long_outlined,
          title: 'Nessun ordine ancora',
          message: 'Gli ordini che invii dal carrello compaiono qui.',
          action: FilledButton(
            onPressed: () => context.go(AppRoutes.products),
            child: const Text('Scopri i prodotti'),
          ),
        ),
        (final List<Order> list, _) => RefreshIndicator(
          onRefresh: _load,
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _OrderRow(order: list[i]),
          ),
        ),
      },
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final items = order.itemCount == 1
        ? '1 articolo'
        : '${order.itemCount} articoli';

    return Material(
      color: palette.surface,
      borderRadius: AppRadii.card,
      child: InkWell(
        borderRadius: AppRadii.card,
        onTap: () => context.go(AppRoutes.order(order.id)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ordine n. ${order.id}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${formatShortDate(order.createdAt)} · $items',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  OrderStatusPill(order.status),
                  const SizedBox(height: 6),
                  NetPriceText(
                    order.subtotal,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: palette.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
