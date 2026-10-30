import 'package:flutter/material.dart';

import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_card.dart';

/// Horizontally scrolling row of the latest products.
class NewArrivalsCarousel extends StatelessWidget {
  const NewArrivalsCarousel({super.key, required this.products});

  final List<Product> products;

  static const _cardWidth = 150.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Square image as wide as the card, plus the text below it.
      height: _cardWidth + ProductCard.textHeight(context),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: products.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) => SizedBox(
          width: _cardWidth,
          child: ProductCard(product: products[index]),
        ),
      ),
    );
  }
}
