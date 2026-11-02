import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/widgets/search_field.dart';
import 'package:beverfood_mobile/features/products/data/product_repository.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/models/product_sort.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/category_tab_bar.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_sliver_grid.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/sort_sheet.dart';

/// Pass a new instance as the `extra` of a navigation to Prodotti to open it
/// with the search field focused, e.g.
/// `context.go(AppRoutes.products, extra: FocusProductSearch())`.
///
/// Each instance is a separate request, so it has no const constructor.
class FocusProductSearch {}

/// Full catalogue with search, category tabs and sorting.
class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    this.initialQuery = '',
    this.initialCategory,
    this.focusSearch,
  });

  final String initialQuery;
  final ProductCategory? initialCategory;

  /// Focuses the search field when the page opens, or when a new request
  /// arrives while the tab is alive.
  final FocusProductSearch? focusSearch;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _repository = const ProductRepository();
  late final _searchController = TextEditingController(
    text: widget.initialQuery,
  );
  final _searchFocus = FocusNode();
  late ProductCategory? _category = widget.initialCategory;
  var _sort = ProductSort.recommended;

  @override
  void initState() {
    super.initState();
    if (widget.focusSearch != null) _requestSearchFocus();
  }

  // After the frame, once the field is laid out and attached.
  void _requestSearchFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void didUpdateWidget(ProductsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The tab stays alive, so new filters arrive here when navigating to it
    // again (e.g. a search or a category tile on the home page).
    if (widget.initialQuery != oldWidget.initialQuery ||
        widget.initialCategory != oldWidget.initialCategory) {
      _searchController.text = widget.initialQuery;
      _category = widget.initialCategory;
    }
    if (widget.focusSearch != null &&
        !identical(widget.focusSearch, oldWidget.focusSearch)) {
      _requestSearchFocus();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _chooseSort() async {
    final sort = await showSortSheet(context, selected: _sort);
    if (sort != null) setState(() => _sort = sort);
  }

  @override
  Widget build(BuildContext context) {
    final products = _repository.search(
      query: _searchController.text,
      category: _category,
      sort: _sort,
    );

    return Scaffold(
      // The title and search bar scroll away and the category tabs stay
      // pinned; the safe area keeps the status bar clear.
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Prodotti',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        _SortButton(onPressed: _chooseSort),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SearchField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            CategoryTabBar(
              selected: _category,
              onSelected: (category) => setState(() => _category = category),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ProductSliverGrid(products: products),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

/// "Filtra e ordina" button. A widget of its own so that a theme change
/// rebuilds just the button, not the whole page.
class _SortButton extends StatelessWidget {
  const _SortButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Filtra e ordina',
      icon: const Icon(Icons.tune_rounded, size: 20),
      style: IconButton.styleFrom(
        backgroundColor: context.palette.surface,
        foregroundColor: context.palette.textPrimary,
        fixedSize: const Size.square(44),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.button),
      ),
    );
  }
}
