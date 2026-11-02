import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/widgets/load_error_row.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/product_rail.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/section_header.dart';
import 'package:beverfood_mobile/features/products/data/catalog_repository.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_card.dart';

/// Home's "Novità": the products the web app flags new, from the API, loaded
/// once (the Home tab stays alive). Card-sized placeholders while loading, a
/// retry row on failure, nothing at all when no product is new.
class NewArrivalsSection extends StatefulWidget {
  const NewArrivalsSection({super.key, this.onSeeAll});

  final VoidCallback? onSeeAll;

  @override
  State<NewArrivalsSection> createState() => _NewArrivalsSectionState();
}

class _NewArrivalsSectionState extends State<NewArrivalsSection> {
  Future<List<Product>>? _products;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _products ??= _load();
  }

  Future<List<Product>> _load() =>
      CatalogScope.of(context).newProducts().catchError((Object error) {
        debugPrint('Novità not loaded: $error');
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
            SectionHeader(title: 'Novità', onSeeAll: widget.onSeeAll),
            if (snapshot.hasError)
              LoadErrorRow(
                message: 'Novità non disponibili',
                onRetry: () => setState(() {
                  _products = _load();
                }),
              )
            else if (products == null)
              const _Loading()
            else
              ProductRail(products: products, showNewBadge: true),
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
