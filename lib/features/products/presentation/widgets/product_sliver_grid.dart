import 'package:flutter/material.dart';

import 'package:beverfood_mobile/core/widgets/empty_state.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_card.dart';

/// Two-column product grid, to be placed inside a [CustomScrollView].
class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({super.key, required this.products});

  final List<Product> products;

  static const _columns = 2;
  static const _crossAxisSpacing = 14.0;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const SliverToBoxAdapter(
        child: EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Nessun prodotto trovato',
          message: 'Prova a cambiare categoria o termine di ricerca.',
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverLayoutBuilder(
        builder: (context, constraints) {
          // Square image as wide as the column, plus the text below it.
          final tileWidth =
              (constraints.crossAxisExtent - _crossAxisSpacing) / _columns;
          return SliverGrid.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columns,
              mainAxisSpacing: 20,
              crossAxisSpacing: _crossAxisSpacing,
              mainAxisExtent: tileWidth + ProductCard.textHeight(context),
            ),
            itemCount: products.length,
            itemBuilder: (context, index) =>
                ProductCard(product: products[index]),
          );
        },
      ),
    );
  }
}
