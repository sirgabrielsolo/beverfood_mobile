import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/formatting/price_format.dart';
import 'package:beverfood_mobile/core/widgets/net_price_text.dart';

/// "Vai al carrello" bar above the bottom navigation, 16 from the sides and
/// 12 above the bar. `AppShell` shows it while the cart has items, except on
/// the Carrello tab. The total is net of IVA, like every price.
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
      label: 'Vai al carrello, $items, totale ${formatPrice(total)} più IVA',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadii.card,
          boxShadow: [
            // Small enough to stay inside the 12 pt above the navigation bar.
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.3),
              offset: const Offset(0, 3),
              blurRadius: 8,
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
                      // The count on its own line, so the total "+ IVA" fits.
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vai al carrello',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            Text(
                              items,
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                                color: AppColors.onBrand.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      NetPriceText(
                        total,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppColors.onBrand,
                        ),
                        suffixColor: AppColors.onBrand.withValues(alpha: 0.85),
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
