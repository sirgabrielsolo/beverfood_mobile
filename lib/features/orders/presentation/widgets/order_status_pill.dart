import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/features/orders/models/order.dart';

/// "INVIATO" (yellow) or "EVASO" (green).
class OrderStatusPill extends StatelessWidget {
  const OrderStatusPill(this.status, {super.key});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (text, background, foreground) = switch (status) {
      OrderStatus.sent => ('INVIATO', palette.warning, palette.onWarning),
      OrderStatus.fulfilled => ('EVASO', palette.success, palette.onSuccess),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadii.badge,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
