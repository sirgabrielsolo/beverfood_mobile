import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/account_notice.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/category_grid.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/catalog_rail_section.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/section_header.dart';
import 'package:beverfood_mobile/features/products/models/category.dart';
import 'package:beverfood_mobile/features/products/models/product_sort.dart';
import 'package:beverfood_mobile/features/products/presentation/products_page.dart';
import 'package:beverfood_mobile/features/promotions/presentation/widgets/promo_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// Prodotti with these filters, applied even if the client changed them
  /// there since the last time.
  static void _openProducts(
    BuildContext context, {
    int? categoryId,
    ProductSort? sort,
  }) {
    context.go(
      AppRoutes.productsWith(categoryId: categoryId, sort: sort),
      extra: ApplyProductFilters(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // No SafeArea: the header's red block extends behind the status bar,
      // and its pinned search bar keeps content from scrolling underneath it.
      body: CustomScrollView(
        slivers: [
          const HomeHeader(),
          // Why the client can't order yet (D1); nothing once approved.
          const SliverToBoxAdapter(
            child: AccountNotice(padding: EdgeInsets.fromLTRB(16, 16, 16, 0)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: PromoSection(
                onPromoTap: (promo) =>
                    context.push(AppRoutes.promo(promo.id), extra: promo),
              ),
            ),
          ),
          // From the catalogue: the products the web app flags new, then the
          // most ordered ones (the agents' "Più popolari", promos left out).
          SliverToBoxAdapter(
            child: CatalogRailSection(
              title: 'Novità',
              products: (catalog) => catalog.newArrivals,
              errorMessage: 'Novità non disponibili',
              showNewBadge: true,
              onSeeAll: () =>
                  _openProducts(context, categoryId: Category.newId),
            ),
          ),
          SliverToBoxAdapter(
            child: CatalogRailSection(
              title: 'Più popolari',
              products: (catalog) => catalog.popular(),
              errorMessage: 'Più popolari non disponibili',
              // Tutti, most ordered first.
              onSeeAll: () => _openProducts(context, sort: ProductSort.popular),
            ),
          ),
          const SliverToBoxAdapter(child: SectionHeader(title: 'Categorie')),
          CategoryGrid(
            onSelected: (category) =>
                _openProducts(context, categoryId: category.id),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
