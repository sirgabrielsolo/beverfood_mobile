import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/widgets/app_network_image.dart';
import 'package:beverfood_mobile/features/promotions/models/promo.dart';

/// A promo drawn entirely by its banner image (texts included), 300×124.
/// The images are opaque with square corners; the rounding is done here.
class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key, required this.promo, this.onTap});

  static const width = 300.0;
  static const height = 124.0;

  final Promo promo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final label = [
      promo.title,
      promo.highlight,
      promo.subtitle,
    ].where((text) => text.isNotEmpty).join(', ');

    return Semantics(
      label: label,
      button: onTap != null,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: AppRadii.card,
              child: AppNetworkImage(promo.bannerUrl!),
            ),
            // The ripple goes over the image, which would hide one drawn on
            // a Material underneath it.
            if (onTap != null)
              Material(
                type: MaterialType.transparency,
                child: InkWell(onTap: onTap, borderRadius: AppRadii.card),
              ),
          ],
        ),
      ),
    );
  }
}
