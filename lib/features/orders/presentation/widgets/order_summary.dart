import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/formatting/price_format.dart';
import 'package:beverfood_mobile/features/cart/data/cart_controller.dart';
import 'package:beverfood_mobile/features/orders/models/order.dart';

/// One line of [OrderSummaryList].
class SummaryLine {
  const SummaryLine({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.pack = '',
    this.details = const [],
    this.unavailable = false,
  });

  /// The cart's lines that will be ordered: complete promos first, then the
  /// products still sold.
  static List<SummaryLine> fromCart(CartController cart) => [
    for (final line in cart.promoLines)
      if (line.status == CartLineStatus.ok)
        SummaryLine(
          name: line.name,
          quantity: 1,
          unitPrice: line.selection!.promo.price,
          details: line.selection!.contents,
        ),
    for (final line in cart.productLines)
      if (line.status == CartLineStatus.ok)
        SummaryLine(
          name: line.product!.shortName,
          pack: line.product!.format,
          quantity: line.quantity,
          unitPrice: line.product!.price,
        ),
  ];

  static List<SummaryLine> fromOrder(Order order) => [
    for (final line in order.lines)
      SummaryLine(
        name: line.displayName.name,
        pack: line.displayName.pack,
        quantity: line.quantity,
        unitPrice: line.price,
        details: line.mixLines,
        unavailable: !line.available,
      ),
  ];

  final String name;
  final String pack;
  final int quantity;

  /// Net of IVA.
  final double unitPrice;

  /// A promo's contents, one line per group.
  final List<String> details;

  /// No longer sold (an old order): marked "Non disponibile".
  final bool unavailable;
}

/// A compact, read-only version of the cart, without photos (C2, O1): name
/// and pack, "quantity × price", the line total, a promo's mix underneath.
class OrderSummaryList extends StatelessWidget {
  const OrderSummaryList({super.key, required this.lines});

  final List<SummaryLine> lines;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: AppRadii.card,
      ),
      child: Column(
        children: [
          for (final (i, line) in lines.indexed) ...[
            if (i > 0) const Divider(height: 1, indent: 14, endIndent: 14),
            _SummaryRow(line: line),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.line});

  final SummaryLine line;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final secondary = TextStyle(
      fontSize: 12.5,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: palette.textSecondary,
    );
    final what = [
      if (line.pack.isNotEmpty) line.pack,
      '${line.quantity} × ${formatPrice(line.unitPrice)}',
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                Text(what, style: secondary),
                for (final detail in line.details)
                  Text(detail, style: secondary),
                if (line.unavailable)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Non disponibile',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: palette.brandText,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatPrice(line.unitPrice * line.quantity),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              height: 1.3,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Imponibile, IVA and Totale, under a cart or an order.
class OrderTotals extends StatelessWidget {
  const OrderTotals({super.key, required this.subtotal, required this.vat});

  final double subtotal;
  final double vat;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    Widget row(String label, double value, {bool total = false}) {
      final style = TextStyle(
        fontSize: total ? 16 : 14,
        fontWeight: total ? FontWeight.w900 : FontWeight.w700,
        color: total ? palette.textPrimary : palette.textSecondary,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            Text(formatPrice(value), style: style),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          row('Imponibile', subtotal),
          row('IVA', vat),
          Divider(height: 12, color: palette.line),
          row('Totale', subtotal + vat, total: true),
        ],
      ),
    );
  }
}

/// A small upper-case label above a section of a page.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
                color: context.palette.textSecondary,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
