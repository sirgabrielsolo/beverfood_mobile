import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/core/formatting/price_format.dart';

/// A price net of IVA followed by a small "+ IVA", e.g. `12,52 € + IVA`.
///
/// Prices are shown net, as in the agents' web app (the user's choice "P2").
class NetPriceText extends StatelessWidget {
  const NetPriceText(
    this.price, {
    super.key,
    required this.style,
    this.suffixColor,
  });

  final double price;

  /// Style of the amount. The suffix is smaller and lighter.
  final TextStyle style;

  /// Defaults to the secondary text color.
  final Color? suffixColor;

  @override
  Widget build(BuildContext context) {
    final size = style.fontSize ?? 15;
    return Text.rich(
      TextSpan(
        text: formatPrice(price),
        style: style,
        children: [
          TextSpan(
            text: ' + IVA',
            style: TextStyle(
              fontSize: size * 0.55 < 11.5 ? 11.5 : size * 0.55,
              fontWeight: FontWeight.w700,
              color: suffixColor ?? context.palette.textSecondary,
            ),
          ),
        ],
      ),
      maxLines: 1,
      softWrap: false,
    );
  }
}
