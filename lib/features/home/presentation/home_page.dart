import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/new_arrivals_carousel.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/popular_products_section.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/section_header.dart';
import 'package:beverfood_mobile/features/products/data/product_repository.dart';
import 'package:beverfood_mobile/features/promotions/data/promo_repository.dart';
import 'package:beverfood_mobile/features/promotions/presentation/widgets/promo_carousel.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final _productRepository = const ProductRepository();
  final _promoRepository = const PromoRepository();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The header scrolls away with the content; the safe area keeps the
      // status bar clear so content never scrolls underneath it.
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            const SliverAppBar(
              toolbarHeight: 76,
              titleSpacing: 16,
              title: Padding(
                padding: EdgeInsets.only(top: 12),
                child: HomeHeader(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 28),
                child: PromoCarousel(
                  promos: _promoRepository.getActivePromos(),
                  onPromoTap: (promo) => context.go(
                    AppRoutes.productsWith(category: promo.category),
                  ),
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
              child: NewArrivalsCarousel(
                products: _productRepository.getNewArrivals(),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Più popolari',
                onSeeAll: () => context.go(AppRoutes.products),
              ),
            ),
            PopularProductsSection(products: _productRepository.getPopular()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
