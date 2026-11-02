import 'package:flutter/material.dart';

import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_card.dart';

/// Horizontally scrolling row of product cards.
class ProductRail extends StatelessWidget {
  const ProductRail({
    super.key,
    required this.products,
    this.showNewBadge = false,
  });

  final List<Product> products;
  final bool showNewBadge;

  static const _cardWidth = 140.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _cardWidth + ProductCard.textHeight(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Spans the full screen width, so there's nothing to clip.
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => SizedBox(
          width: _cardWidth,
          child: ProductCard(
            product: products[index],
            showNewBadge: showNewBadge,
          ),
        ),
      ),
    );
  }
}
