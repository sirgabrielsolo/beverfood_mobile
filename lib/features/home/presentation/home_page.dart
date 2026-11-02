import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/category_tiles.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/product_rail.dart';
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: PromoSection(
                onPromoTap: (promo) =>
                    context.push(AppRoutes.promo(promo.id), extra: promo),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Novità',
              onSeeAll: () => context.go(AppRoutes.products),
            ),
          ),
          SliverToBoxAdapter(
            child: ProductRail(
              products: _productRepository.getNewArrivals(),
              showNewBadge: true,
            ),
          ),
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Più popolari',
              onSeeAll: () => context.go(AppRoutes.products),
            ),
          ),
          SliverToBoxAdapter(
            child: ProductRail(products: _productRepository.getPopular()),
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
