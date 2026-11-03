import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/core/formatting/date_format.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:beverfood_mobile/features/orders/models/order.dart';

/// After "Invia ordine": the order number and where to find it again.
/// Back goes to Home, not to the emptied review page.
class OrderSentPage extends StatelessWidget {
  const OrderSentPage({super.key, required this.orderId, this.order});

  final int orderId;
  final Order? order;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final sentAt = order?.createdAt;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go(AppRoutes.home);
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: palette.success,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 40,
                    color: palette.onSuccess,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Ordine inviato',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    'Ordine n. $orderId',
                    if (sentAt != null) formatDateTime(sentAt),
                  ].join(' · '),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Lo trovi in Profilo → I miei ordini, con il suo stato.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
                const Spacer(),
                WideButton(
                  label: "Vedi l'ordine",
                  onPressed: () => context.go(AppRoutes.order(orderId)),
                ),
                const SizedBox(height: 10),
                WideButton(
                  label: 'Torna alla Home',
                  primary: false,
                  onPressed: () => context.go(AppRoutes.home),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
