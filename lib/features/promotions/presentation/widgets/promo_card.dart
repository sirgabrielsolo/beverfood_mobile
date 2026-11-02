import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/widgets/app_network_image.dart';
import 'package:beverfood_mobile/features/promotions/models/promo.dart';

/// Promo banner: eyebrow, highlight and subtitle on the left, a photo on the
/// right. The [featured] card is yellow, the others dark.
class PromoCard extends StatelessWidget {
  const PromoCard({
    super.key,
    required this.promo,
    this.featured = false,
    this.onTap,
  });

  static const width = 300.0;

  /// 124 pt, taller only when large text sizes need the room.
  static double height(TextScaler scaler) {
    // Padding, gaps, and the three text lines at their natural line height.
    final content =
        32 +
        4 +
        scaler.scale(11) * 1.4 +
        scaler.scale(27) * 1.05 +
        scaler.scale(13) * 1.4;
    return math.max(124, content);
  }

  final Promo promo;
  final bool featured;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final foreground = featured ? AppColors.onAccent : AppColors.onPromoAlt;

    return Material(
      color: featured ? AppColors.accent : context.palette.promoAlt,
      borderRadius: AppRadii.card,
      // The ripple is shaped by the InkWell rather than by clipping the card,
      // which would cost a clip on every scroll frame.
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.card,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: foreground),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        promo.title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.9,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Long highlights shrink to fit rather than wrap.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          promo.highlight,
                          style: const TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            height: 1.05,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        promo.subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: AppRadii.image,
                child: SizedBox(
                  width: 88,
                  height: 92,
                  child: AppNetworkImage(promo.imageUrl),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
