import 'package:flutter/material.dart';

import 'package:beverfood_mobile/features/promotions/models/promo.dart';
import 'package:beverfood_mobile/features/promotions/presentation/widgets/promo_banner.dart';
import 'package:beverfood_mobile/features/promotions/presentation/widgets/promo_card.dart';

/// Horizontally scrolling promo banners. Each is narrower than the screen so
/// the next one peeks in from the right edge.
///
/// A promo with a banner image is shown as that image ([PromoBanner]); one
/// without (e.g. just added on the server) gets a text banner ([PromoCard]),
/// yellow if it comes first.
class PromoCarousel extends StatelessWidget {
  const PromoCarousel({super.key, required this.promos, this.onPromoTap});

  final List<Promo> promos;
  final ValueChanged<Promo>? onPromoTap;

  @override
  Widget build(BuildContext context) {
    // Text banners grow with large text sizes; image banners don't.
    final allImages = promos.every((promo) => promo.bannerUrl != null);
    final height = allImages
        ? PromoBanner.height
        : PromoCard.height(MediaQuery.textScalerOf(context));

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Spans the full screen width, so there's nothing to clip.
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: promos.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final promo = promos[index];
          final onTap = onPromoTap == null ? null : () => onPromoTap!(promo);
          if (promo.bannerUrl != null) {
            return Align(
              alignment: Alignment.topCenter,
              child: PromoBanner(promo: promo, onTap: onTap),
            );
          }
          return SizedBox(
            width: PromoCard.width,
            child: PromoCard(promo: promo, featured: index == 0, onTap: onTap),
          );
        },
      ),
    );
  }
}
