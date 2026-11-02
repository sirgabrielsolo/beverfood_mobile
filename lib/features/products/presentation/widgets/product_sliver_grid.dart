import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:beverfood_mobile/core/widgets/empty_state.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_card.dart';

/// Two-column product grid, to be placed inside a [CustomScrollView].
class ProductSliverGrid extends StatelessWidget {
  const ProductSliverGrid({super.key, required this.products});

  final List<Product> products;

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
      sliver: SliverGrid.builder(
        gridDelegate: _ProductGridDelegate(
          textHeight: ProductCard.textHeight(context),
        ),
        itemCount: products.length,
        itemBuilder: (context, index) => ProductCard(product: products[index]),
      ),
    );
  }
}

/// [_columns] columns of cards exactly as tall as [ProductCard] needs: the
/// tile width (the square image) plus [textHeight].
///
/// The tile width comes from the sliver constraints at layout time. A
/// `SliverLayoutBuilder` would also work, but it runs its builder again
/// whenever the constraints change, and they include the scroll offset, so
/// every visible card would rebuild on every scroll frame.
class _ProductGridDelegate extends SliverGridDelegate {
  const _ProductGridDelegate({required this.textHeight});

  final double textHeight;

  static const _columns = 2;
  static const _crossAxisSpacing = 12.0;
  static const _mainAxisSpacing = 16.0;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final tileWidth =
        (constraints.crossAxisExtent - _crossAxisSpacing * (_columns - 1)) /
        _columns;
    final tileHeight = tileWidth + textHeight;
    return SliverGridRegularTileLayout(
      crossAxisCount: _columns,
      mainAxisStride: tileHeight + _mainAxisSpacing,
      crossAxisStride: tileWidth + _crossAxisSpacing,
      childMainAxisExtent: tileHeight,
      childCrossAxisExtent: tileWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_ProductGridDelegate oldDelegate) =>
      textHeight != oldDelegate.textHeight;
}
