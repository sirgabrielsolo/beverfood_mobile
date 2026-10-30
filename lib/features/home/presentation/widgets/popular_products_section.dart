import 'package:flutter/material.dart';

import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/category_chips.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_sliver_grid.dart';

/// Category chips and the grid they filter. Returns a sliver.
class PopularProductsSection extends StatefulWidget {
  const PopularProductsSection({super.key, required this.products});

  final List<Product> products;

  @override
  State<PopularProductsSection> createState() => _PopularProductsSectionState();
}

class _PopularProductsSectionState extends State<PopularProductsSection> {
  ProductCategory? _category;

  @override
  Widget build(BuildContext context) {
    final visibleProducts = _category == null
        ? widget.products
        : widget.products.where((p) => p.category == _category).toList();

    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: CategoryChips(
            selected: _category,
            onSelected: (category) => setState(() => _category = category),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ProductSliverGrid(products: visibleProducts),
      ],
    );
  }
}
