import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/account_notice.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/category_tiles.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/catalog_rail_section.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/section_header.dart';
import 'package:beverfood_mobile/features/products/data/product_repository.dart';
import 'package:beverfood_mobile/features/promotions/presentation/widgets/promo_section.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final _productRepository = const ProductRepository();

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
          // From the API: the products the web app flags new, then the most
          // ordered ones (the agents' "Più popolari", promos left out).
          SliverToBoxAdapter(
            child: CatalogRailSection(
              title: 'Novità',
              load: (catalog) => catalog.newProducts(),
              errorMessage: 'Novità non disponibili',
              showNewBadge: true,
              onSeeAll: () => context.go(AppRoutes.products),
            ),
          ),
          SliverToBoxAdapter(
            child: CatalogRailSection(
              title: 'Più popolari',
              load: (catalog) => catalog.popularProducts(),
              errorMessage: 'Più popolari non disponibili',
              onSeeAll: () => context.go(AppRoutes.products),
            ),
          ),
          const SliverToBoxAdapter(child: SectionHeader(title: 'Categorie')),
          SliverToBoxAdapter(
            child: CategoryTiles(
              imageUrlFor: _productRepository.categoryImageUrl,
              onSelected: (category) =>
                  context.go(AppRoutes.productsWith(category: category)),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}
