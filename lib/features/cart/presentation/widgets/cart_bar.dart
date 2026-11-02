import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/formatting/price_format.dart';

/// "Vai al carrello" bar that floats above the bottom navigation.
///
/// Not shown yet: it's the agreed design for when the cart is built. Show it
/// only while the cart has items (slide in/out with `AnimatedSlide` +
/// `AnimatedOpacity`), 16 from the sides and 12 above the navigation bar,
/// and give scrolling content enough bottom padding to clear it.
class CartBar extends StatelessWidget {
  const CartBar({
    super.key,
    required this.itemCount,
    required this.total,
    required this.onTap,
  });

  final int itemCount;
  final double total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final items = itemCount == 1 ? '1 articolo' : '$itemCount articoli';

    return Semantics(
      button: true,
      label: 'Vai al carrello, $items, totale ${formatPrice(total)}',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadii.card,
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.35),
              offset: const Offset(0, 8),
              blurRadius: 24,
            ),
          ],
        ),
        child: Material(
          color: AppColors.brand,
          borderRadius: AppRadii.card,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 56,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(color: AppColors.onBrand),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.onBrand.withValues(alpha: 0.18),
                          borderRadius: AppRadii.image,
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          size: 18,
                          color: AppColors.onBrand,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Vai al carrello · $items',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatPrice(total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
