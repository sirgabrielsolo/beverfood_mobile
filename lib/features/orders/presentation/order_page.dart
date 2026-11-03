import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/formatting/date_format.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/core/widgets/load_error_row.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:beverfood_mobile/features/cart/data/cart_controller.dart';
import 'package:beverfood_mobile/features/orders/data/order_repository.dart';
import 'package:beverfood_mobile/features/orders/models/order.dart';
import 'package:beverfood_mobile/features/orders/presentation/widgets/order_status_pill.dart';
import 'package:beverfood_mobile/features/orders/presentation/widgets/order_summary.dart';
import 'package:beverfood_mobile/features/products/data/catalog_repository.dart';
import 'package:beverfood_mobile/features/promotions/data/promo_repository.dart';
import 'package:beverfood_mobile/features/promotions/models/promo.dart';
import 'package:beverfood_mobile/features/promotions/models/promo_selection.dart';

/// One order (O1): its status (Inviato, then Evaso), the products as on the
/// review page, the address and notes, the totals at the prices of the day,
/// and "Riordina", which puts the same products in the cart at today's
/// prices. Products no longer sold are marked "Non disponibile" and skipped.
class OrderPage extends StatefulWidget {
  const OrderPage({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage> {
  Order? _order;
  String? _error;
  var _reordering = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final order = await OrderRepositoryScope.of(context).get(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  Future<void> _reorder(Order order, PromoRepository promoRepository) async {
    final cart = CartScope.read(context);
    final catalogController = CatalogScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _reordering = true);

    if (catalogController.catalog == null) await catalogController.load();
    final catalog = catalogController.catalog;
    var promos = const <int, Promo>{};
    if (order.lines.any((l) => l.isPromo)) {
      try {
        promos = {
          for (final p in await promoRepository.getActivePromos()) p.id: p,
        };
      } on ApiException {
        // The promos are then skipped, like products no longer sold.
      }
    }
    if (!mounted) return;
    setState(() => _reordering = false);
    if (catalog == null) {
      messenger.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Connessione non riuscita. Riprova.'),
        ),
      );
      return;
    }

    var added = 0;
    final skipped = <String>[];
    for (final line in order.lines) {
      if (line.isPromo) {
        final promo = promos[line.productId];
        final selection = promo == null
            ? null
            : PromoSelection.restore(
                promo,
                mix: [for (final item in line.mix) item.toJson()],
              );
        if (selection != null && selection.isComplete) {
          cart.putPromo(selection);
          added++;
        } else {
          skipped.add(promo?.displayName ?? line.displayName.name);
        }
        continue;
      }
      final product = catalog.productById('db-${line.productId}');
      if (product == null) {
        skipped.add(line.displayName.name);
      } else {
        cart.setQuantity(product, cart.quantityOf(product) + line.quantity);
        added++;
      }
    }

    final message = [
      if (added > 0)
        added == 1
            ? '1 prodotto aggiunto al carrello.'
            : '$added prodotti aggiunti al carrello.',
      if (skipped.isNotEmpty) 'Non più disponibili: ${skipped.join(', ')}.',
    ].join(' ');
    if (added > 0) context.go(AppRoutes.cart);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: skipped.isEmpty ? 4 : 8),
          content: Text(message),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final promoRepository = PromoRepositoryScope.of(context);

    return Scaffold(
      appBar: AppBar(title: Text('Ordine n. ${widget.orderId}')),
      body: order == null
          ? _error == null
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: LoadErrorRow(
                        message: 'Ordine non disponibile',
                        onRetry: () {
                          setState(() => _error = null);
                          _load();
                        },
                      ),
                    ),
                  )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _StatusCard(order: order),
                const SectionLabel('Prodotti'),
                OrderSummaryList(lines: SummaryLine.fromOrder(order)),
                if (order.deliveryAddress case final address?) ...[
                  const SectionLabel('Consegna'),
                  _TextBox(address),
                ],
                if (order.notes case final notes? when notes.isNotEmpty) ...[
                  const SectionLabel('Le tue note'),
                  _TextBox(notes),
                ],
                const SizedBox(height: 20),
                OrderTotals(subtotal: order.subtotal, vat: order.vat),
              ],
            ),
      bottomNavigationBar: order == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: WideButton(
                  label: 'Riordina',
                  icon: Icons.replay_rounded,
                  busy: _reordering,
                  onPressed: order.lines.any((l) => l.available)
                      ? () => _reorder(order, promoRepository)
                      : null,
                ),
              ),
            ),
    );
  }
}

/// The two steps the client sees: Inviato, then Evaso.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final fulfilled = order.status == OrderStatus.fulfilled;

    Widget step(String label, bool done, DateTime? when) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? palette.brandText : null,
              border: Border.all(
                color: done ? palette.brandText : palette.line,
                width: 2,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: done ? palette.textPrimary : palette.textSecondary,
              ),
            ),
          ),
          if (when != null)
            Text(
              formatDateTime(when),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
            ),
        ],
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.card,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Stato',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ),
                OrderStatusPill(order.status),
              ],
            ),
            const SizedBox(height: 6),
            step('Inviato', true, order.createdAt),
            step('Evaso', fulfilled, order.fulfilledAt),
          ],
        ),
      ),
    );
  }
}

class _TextBox extends StatelessWidget {
  const _TextBox(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: AppRadii.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: double.infinity,
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}
