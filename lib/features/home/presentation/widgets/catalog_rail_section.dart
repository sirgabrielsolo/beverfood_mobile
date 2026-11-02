import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/widgets/load_error_row.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/product_rail.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/section_header.dart';
import 'package:beverfood_mobile/features/products/data/catalog_repository.dart';
import 'package:beverfood_mobile/features/products/models/catalog.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_card.dart';

/// A Home section of database products ("Novità", "Più popolari"): its
/// title and a rail, picked from the catalogue (`CatalogScope`). Card-sized
/// placeholders while it loads, a retry row if it fails, nothing at all when
/// the list is empty.
class CatalogRailSection extends StatelessWidget {
  const CatalogRailSection({
    super.key,
    required this.title,
    required this.products,
    required this.errorMessage,
    this.showNewBadge = false,
    this.onSeeAll,
  });

  final String title;

  /// Picks the products, e.g. `(catalog) => catalog.newArrivals`.
  final List<Product> Function(Catalog catalog) products;

  /// Shown with "Riprova" when loading fails, e.g. "Novità non disponibili".
  final String errorMessage;

  final bool showNewBadge;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final controller = CatalogScope.of(context);
    final catalog = controller.catalog;
    final list = catalog == null ? null : products(catalog);
    if (list != null && list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title: title, onSeeAll: onSeeAll),
        if (list != null)
          ProductRail(products: list, showNewBadge: showNewBadge)
        else if (controller.status == CatalogStatus.failed)
          LoadErrorRow(message: errorMessage, onRetry: controller.load)
        else
          const _Loading(),
      ],
    );
  }
}

/// Card-sized placeholders, so the page doesn't jump when the rail arrives.
class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    final color = context.palette.surface;
    final height = ProductRail.cardWidth + ProductCard.textHeight(context);
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) => DecoratedBox(
          decoration: BoxDecoration(color: color, borderRadius: AppRadii.card),
          child: const SizedBox(width: ProductRail.cardWidth),
        ),
      ),
    );
  }
}
