import 'package:flutter/material.dart';

import 'package:beverfood_mobile/features/products/data/product_repository.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/category_chips.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_sliver_grid.dart';

/// Full catalogue with search and category filter.
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key, this.initialQuery = '', this.initialCategory});

  final String initialQuery;
  final ProductCategory? initialCategory;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _repository = const ProductRepository();
  late final _searchController = TextEditingController(
    text: widget.initialQuery,
  );
  late ProductCategory? _category = widget.initialCategory;

  @override
  void didUpdateWidget(ProductsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The tab stays alive, so new filters arrive here when navigating to it
    // again (e.g. a search from the home page).
    if (widget.initialQuery != oldWidget.initialQuery ||
        widget.initialCategory != oldWidget.initialCategory) {
      _searchController.text = widget.initialQuery;
      _category = widget.initialCategory;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = _repository.search(
      query: _searchController.text,
      category: _category,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Prodotti')),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Cerca vini, birre, caffè…',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: CategoryChips(
              selected: _category,
              onSelected: (category) => setState(() => _category = category),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ProductSliverGrid(products: products),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
