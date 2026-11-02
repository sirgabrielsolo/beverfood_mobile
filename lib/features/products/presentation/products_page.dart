import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/formatting/search_text.dart';
import 'package:beverfood_mobile/core/widgets/load_error_row.dart';
import 'package:beverfood_mobile/core/widgets/search_field.dart';
import 'package:beverfood_mobile/features/products/data/catalog_repository.dart';
import 'package:beverfood_mobile/features/products/models/catalog.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/models/product_sort.dart';
import 'package:beverfood_mobile/features/promotions/data/promo_repository.dart';
import 'package:beverfood_mobile/features/promotions/models/promo.dart';
import 'package:beverfood_mobile/features/promotions/presentation/widgets/promo_banner.dart';
import 'package:beverfood_mobile/features/promotions/presentation/widgets/promo_card.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/category_tab_bar.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_sliver_grid.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/sort_sheet.dart';

/// Pass a new instance as the `extra` of a navigation to Prodotti to open it
/// with the search field focused, e.g.
/// `context.go(AppRoutes.products, extra: FocusProductSearch())`.
///
/// Each instance is a separate request, so it has no const constructor.
class FocusProductSearch {}

/// Pass a new instance as the `extra` of a navigation to Prodotti to apply
/// the location's search, category and sort even when they equal the last
/// ones asked for (the client may have changed them on the page since), e.g.
/// Home's "Vedi tutti" under Più popolari.
class ApplyProductFilters {}

/// The catalogue: search, category tabs ("Tutti" first) and sorting, over
/// every product loaded once (`CatalogScope`). The Promozioni tab lists the
/// promos instead, which open their pages.
class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key,
    this.initialQuery = '',
    this.initialCategoryId,
    this.initialSort = ProductSort.popular,
    this.focusSearch,
    this.applyFilters,
  });

  final String initialQuery;

  /// A `Category.id`; null is "Tutti".
  final int? initialCategoryId;
  final ProductSort initialSort;

  /// Focuses the search field when the page opens, or when a new request
  /// arrives while the tab is alive.
  final FocusProductSearch? focusSearch;

  /// A new one applies the filters above again.
  final ApplyProductFilters? applyFilters;

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  late final _searchController = TextEditingController(
    text: widget.initialQuery,
  );
  final _searchFocus = FocusNode();
  late int? _categoryId = widget.initialCategoryId;
  late ProductSort _sort = widget.initialSort;

  // The last search, kept so rebuilds that change nothing (focus, the
  // cart bar) don't filter and sort ~1200 products again.
  ({Catalog catalog, String query, int? categoryId, ProductSort sort})? _key;
  List<Product> _results = const [];

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
    final again =
        widget.applyFilters != null &&
        !identical(widget.applyFilters, oldWidget.applyFilters);
    if (again ||
        widget.initialQuery != oldWidget.initialQuery ||
        widget.initialCategoryId != oldWidget.initialCategoryId ||
        widget.initialSort != oldWidget.initialSort) {
      _searchController.text = widget.initialQuery;
      _categoryId = widget.initialCategoryId;
      _sort = widget.initialSort;
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

  List<Product> _search(Catalog catalog, int? categoryId) {
    final key = (
      catalog: catalog,
      query: _searchController.text,
      categoryId: categoryId,
      sort: _sort,
    );
    if (key != _key) {
      _key = key;
      _results = catalog.search(
        query: key.query,
        categoryId: categoryId,
        sort: _sort,
      );
    }
    return _results;
  }

  @override
  Widget build(BuildContext context) {
    final controller = CatalogScope.of(context);
    final catalog = controller.catalog;
    // A category the catalogue no longer has (emptied since) shows Tutti.
    final category = _categoryId == null
        ? null
        : catalog?.categoryById(_categoryId!);

    final Widget content;
    if (catalog == null) {
      content = SliverToBoxAdapter(
        child: controller.status == CatalogStatus.failed
            ? LoadErrorRow(
                message: 'Prodotti non disponibili',
                onRetry: controller.load,
              )
            : const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
      );
    } else if (category != null && category.isPromo) {
      content = _PromoList(query: _searchController.text);
    } else {
      content = ProductSliverGrid(products: _search(catalog, category?.id));
    }

    return Scaffold(
      // The title and search bar scroll away and the category tabs stay
      // pinned; the safe area keeps the status bar clear.
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: controller.load,
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
                categories: catalog?.categories ?? const [],
                selectedId: category?.id,
                onSelected: (id) => setState(() => _categoryId = id),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              content,
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The Promozioni tab: every promo as on Home (its banner, or the text card),
/// full width, opening the promo's page. Filtered by the search words.
class _PromoList extends StatefulWidget {
  const _PromoList({required this.query});

  final String query;

  @override
  State<_PromoList> createState() => _PromoListState();
}

class _PromoListState extends State<_PromoList> {
  Future<List<Promo>>? _promos;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _promos ??= _load();
  }

  Future<List<Promo>> _load() =>
      PromoRepositoryScope.of(context).getActivePromos();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _promos,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: LoadErrorRow(
              message: 'Promozioni non disponibili',
              onRetry: () => setState(() => _promos = _load()),
            ),
          );
        }
        final promos = snapshot.data;
        if (promos == null) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final words = searchText(
          widget.query,
        ).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
        final shown = [
          for (final promo in promos)
            if (words.every(
              searchText(
                '${promo.name} ${promo.title} ${promo.highlight} '
                '${promo.subtitle}',
              ).contains,
            ))
              promo,
        ];
        return ProductSliverGrid.emptyOr(
          isEmpty: shown.isEmpty,
          sliver: SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList.separated(
              itemCount: shown.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final promo = shown[index];
                void open() =>
                    context.push(AppRoutes.promo(promo.id), extra: promo);
                return promo.bannerUrl != null
                    ? AspectRatio(
                        aspectRatio: PromoBanner.width / PromoBanner.height,
                        child: FittedBox(
                          child: PromoBanner(promo: promo, onTap: open),
                        ),
                      )
                    : Center(
                        child: PromoCard(promo: promo, onTap: open),
                      );
              },
            ),
          ),
        );
      },
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
