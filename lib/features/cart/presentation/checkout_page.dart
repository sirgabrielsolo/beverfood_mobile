import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/app/theme/app_theme.dart';
import 'package:beverfood_mobile/core/formatting/price_format.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/auth/data/auth_controller.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:beverfood_mobile/features/cart/data/cart_controller.dart';
import 'package:beverfood_mobile/features/orders/data/order_repository.dart';
import 'package:beverfood_mobile/features/orders/presentation/widgets/order_summary.dart';

/// "Riepilogo ordine" (C2): the delivery address (with "Modifica"), a compact
/// list of what will be ordered, the notes and the totals; "Invia ordine"
/// sends it. On success the cart (notes included) empties and the
/// confirmation opens; on failure the cart stays as it was.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  /// One id for every attempt from this page, so a retry after a lost
  /// answer can't make a second order.
  final _requestId = OrderRepository.newRequestId();
  var _sending = false;

  Future<void> _send() async {
    final cart = CartScope.read(context);
    final orders = OrderRepositoryScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sending = true);
    try {
      final order = await orders.send(
        requestId: _requestId,
        notes: cart.notes,
        items: cart.orderItems,
      );
      cart.clear();
      if (mounted) context.go(AppRoutes.orderSent(order.id), extra: order);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _sending = false);
      if (error.code == 'unavailable') {
        cart.markUnavailable([
          for (final id in error.details['product_ids'] as List? ?? const [])
            if (id is int) id,
        ]);
        // Back to the cart, where they're marked.
        context.pop();
      }
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              error.code == 'unavailable'
                  ? 'Alcuni prodotti non sono più disponibili: li abbiamo '
                        'segnati nel carrello.'
                  : error.message,
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final account = AuthScope.of(context).account;
    final palette = context.palette;
    final lines = SummaryLine.fromCart(cart);
    final total = cart.subtotal + cart.vat;
    final address = account?.address;
    final canSend =
        lines.isNotEmpty &&
        (account?.canOrder ?? false) &&
        cart.subtotal + 0.004 >= (account?.orderMinimum ?? 150);

    return Scaffold(
      appBar: AppBar(title: const Text('Riepilogo ordine')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          SectionLabel(
            'Consegna',
            trailing: TextButton(
              onPressed: () => context.push(AppRoutes.editAddress),
              style: TextButton.styleFrom(
                foregroundColor: palette.brandText,
                // textStyle replaces the inherited one: name the font.
                textStyle: const TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w900,
                ),
                visualDensity: VisualDensity.compact,
              ),
              child: const Text('Modifica'),
            ),
          ),
          _Box(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (account?.companyName case final company?)
                  Text(
                    company,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                Text(
                  address?.oneLine ?? 'Indirizzo da completare',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                  ),
                ),
                if (address?.notes case final notes? when notes.isNotEmpty)
                  Text(
                    notes,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SectionLabel('Prodotti'),
          OrderSummaryList(lines: lines),
          if (cart.notes.trim().isNotEmpty) ...[
            const SectionLabel('Note per Beverfood'),
            _Box(
              child: Text(
                cart.notes.trim(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          OrderTotals(subtotal: cart.subtotal, vat: cart.vat),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
          child: WideButton(
            label: 'Invia ordine · ${formatPrice(total)} IVA incl.',
            busy: _sending,
            onPressed: canSend ? _send : null,
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: AppRadii.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}
