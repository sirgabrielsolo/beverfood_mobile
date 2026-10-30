import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/formatting/price_format.dart';
import 'package:beverfood_mobile/core/widgets/app_network_image.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';

/// Square image on top, then a one-line name and a prominent price.
///
/// The card is [width] + [textHeight] tall; lists and grids use that to size
/// their items exactly.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product});

  final Product product;

  static const _nameStyle = TextStyle(fontSize: 15, height: 1.3);

  static const _priceStyle = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  // The euro sign is drawn smaller than the amount, e.g. "12,90€".
  static const _currencyStyle = TextStyle(fontSize: 14);

  static const _imageSpacing = 8.0;
  static const _priceSpacing = 2.0;

  /// Height of the text below the image, respecting the user's font scale.
  static double textHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return _imageSpacing +
        _lineHeight(scaler, _nameStyle) +
        _priceSpacing +
        _lineHeight(scaler, _priceStyle);
  }

  static double _lineHeight(TextScaler scaler, TextStyle style) =>
      scaler.scale(style.fontSize!) * style.height!;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);

    // Text lines get fixed heights so the card always matches [textHeight]
    // exactly, whatever the font's own metrics are.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: AppRadii.image,
            child: AppNetworkImage(product.imageUrl),
          ),
        ),
        const SizedBox(height: _imageSpacing),
        SizedBox(
          height: _lineHeight(scaler, _nameStyle),
          child: Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _nameStyle,
          ),
        ),
        const SizedBox(height: _priceSpacing),
        SizedBox(
          height: _lineHeight(scaler, _priceStyle),
          child: Text.rich(
            TextSpan(
              text: formatAmount(product.price),
              children: const [TextSpan(text: '€', style: _currencyStyle)],
            ),
            maxLines: 1,
            style: _priceStyle,
          ),
        ),
      ],
    );
  }
}
