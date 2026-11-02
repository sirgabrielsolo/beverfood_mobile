import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/widgets/load_error_row.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/product_rail.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/section_header.dart';
import 'package:beverfood_mobile/features/products/data/catalog_repository.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_card.dart';

/// A Home section of database products from the API ("Novità", "Più
/// popolari"): its title and a rail, loaded once (the Home tab stays alive).
/// Card-sized placeholders while loading, a retry row on failure, nothing at
/// all when the list is empty.
class CatalogRailSection extends StatefulWidget {
  const CatalogRailSection({
    super.key,
    required this.title,
    required this.load,
    required this.errorMessage,
    this.showNewBadge = false,
    this.onSeeAll,
  });

  final String title;

  /// Fetches the products, e.g. `(catalog) => catalog.newProducts()`.
  final Future<List<Product>> Function(CatalogRepository catalog) load;

  /// Shown with "Riprova" when loading fails, e.g. "Novità non disponibili".
  final String errorMessage;

  final bool showNewBadge;
  final VoidCallback? onSeeAll;

  @override
  State<CatalogRailSection> createState() => _CatalogRailSectionState();
}

class _CatalogRailSectionState extends State<CatalogRailSection> {
  Future<List<Product>>? _products;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _products ??= _load();
  }

  Future<List<Product>> _load() =>
      widget.load(CatalogScope.of(context)).catchError((Object error) {
        debugPrint('${widget.title} not loaded: $error');
        throw error;
      });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _products,
      builder: (context, snapshot) {
        final products = snapshot.data;
        if (products != null && products.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SectionHeader(title: widget.title, onSeeAll: widget.onSeeAll),
            if (snapshot.hasError)
              LoadErrorRow(
                message: widget.errorMessage,
                onRetry: () => setState(() {
                  _products = _load();
                }),
              )
            else if (products == null)
              const _Loading()
            else
              ProductRail(
                products: products,
                showNewBadge: widget.showNewBadge,
              ),
          ],
        );
      },
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
