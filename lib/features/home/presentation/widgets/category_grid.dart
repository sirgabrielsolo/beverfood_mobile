import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/features/products/data/catalog_repository.dart';
import 'package:beverfood_mobile/features/products/models/category.dart';

/// Home's "Categorie": every category with products (Novità and Promozioni
/// first), four per row, each a photo bundled with the app and its name on
/// up to two lines. Returns a sliver. Grey tiles while the catalogue loads;
/// nothing if it failed (the rails above offer the retry).
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.onSelected});

  final ValueChanged<Category> onSelected;

  static const _columns = 4;
  static const _placeholders = 8;
  static const _labelGap = 6.0;
  static const labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  @override
  Widget build(BuildContext context) {
    final controller = CatalogScope.of(context);
    final categories = controller.catalog?.categories;
    if (categories == null && controller.status == CatalogStatus.failed) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    final labelHeight =
        MediaQuery.textScalerOf(context).scale(labelStyle.fontSize!) *
        labelStyle.height! *
        2;
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid.builder(
        gridDelegate: _CategoryGridDelegate(
          textHeight: _labelGap + labelHeight,
        ),
        itemCount: categories?.length ?? _placeholders,
        itemBuilder: (context, index) => categories == null
            ? const _TileImage(child: null)
            : _CategoryTile(
                category: categories[index],
                onTap: () => onSelected(categories[index]),
              ),
      ),
    );
  }
}

// Its own widget so the theme colors are read (and updated on a theme change)
// in its own build, not through the grid builder's context.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category, required this.onTap});

  final Category category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${category.name}, ${category.count} prodotti',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            _TileImage(child: _CategoryImage(category.imageAsset)),
            const SizedBox(height: CategoryGrid._labelGap),
            // The rest of the cell: two lines (rounding may want 1 px more).
            Expanded(
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: CategoryGrid.labelStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The square card around the photo (grey and empty while loading).
class _TileImage extends StatelessWidget {
  const _TileImage({required this.child});

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: AppRadii.card,
        ),
        child: child == null
            ? null
            : ClipRRect(borderRadius: AppRadii.image, child: child),
      ),
    );
  }
}

/// A bundled category photo, decoded at the size drawn. A category added
/// after this release has no photo: a plain tile with an icon.
class _CategoryImage extends StatelessWidget {
  const _CategoryImage(this.asset);

  final String asset;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    return LayoutBuilder(
      builder: (context, constraints) => Image.asset(
        asset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        cacheWidth: constraints.maxWidth.isFinite
            ? (constraints.maxWidth * pixelRatio).ceil()
            : null,
        errorBuilder: (context, error, stackTrace) => ColoredBox(
          color: context.palette.imagePlaceholder,
          child: Center(
            child: Icon(
              Icons.category_outlined,
              color: context.palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// [CategoryGrid._columns] columns of tiles as tall as their square photo
/// plus [textHeight], sized at layout time (see `ProductSliverGrid` for why
/// not a `SliverLayoutBuilder`).
class _CategoryGridDelegate extends SliverGridDelegate {
  const _CategoryGridDelegate({required this.textHeight});

  final double textHeight;

  static const _crossAxisSpacing = 10.0;
  static const _mainAxisSpacing = 14.0;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    const columns = CategoryGrid._columns;
    final tileWidth =
        (constraints.crossAxisExtent - _crossAxisSpacing * (columns - 1)) /
        columns;
    final tileHeight = tileWidth + textHeight;
    return SliverGridRegularTileLayout(
      crossAxisCount: columns,
      mainAxisStride: tileHeight + _mainAxisSpacing,
      crossAxisStride: tileWidth + _crossAxisSpacing,
      childMainAxisExtent: tileHeight,
      childCrossAxisExtent: tileWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_CategoryGridDelegate oldDelegate) =>
      textHeight != oldDelegate.textHeight;
}
