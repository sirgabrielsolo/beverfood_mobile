import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/features/products/data/catalog_repository.dart';
import 'package:beverfood_mobile/features/products/models/category.dart';

/// Home's "Categorie" (H2): the catalogue's categories in two rows that
/// scroll sideways together, read top to bottom then left to right, each a
/// photo bundled with the app and its name on up to two lines. Novità and
/// Promozioni are left out: Home has their sections already (they stay tabs
/// in Prodotti). Grey tiles while the catalogue loads; nothing if it failed
/// (the rails above offer the retry).
class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key, required this.onSelected});

  final ValueChanged<Category> onSelected;

  static const tileWidth = 84.0;
  // Small: a one-line name already leaves its second line empty.
  static const _rowGap = 6.0;
  static const _columnGap = 12.0;
  static const _labelGap = 6.0;
  static const _placeholderColumns = 5;
  static const labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  /// One tile: the square photo, the gap and two lines of name.
  static double tileHeight(BuildContext context) =>
      tileWidth +
      _labelGap +
      MediaQuery.textScalerOf(context).scale(labelStyle.fontSize!) *
          labelStyle.height! *
          2;

  @override
  Widget build(BuildContext context) {
    final controller = CatalogScope.of(context);
    final categories = controller.catalog?.categories
        .where((c) => !c.isNew && !c.isPromo)
        .toList();
    if (categories == null && controller.status == CatalogStatus.failed) {
      return const SizedBox.shrink();
    }
    if (categories != null && categories.isEmpty) {
      return const SizedBox.shrink();
    }

    final tileHeight = CategoryGrid.tileHeight(context);
    // Ceil: two lines may round 1 px taller than their nominal height.
    final height = (tileHeight * 2 + _rowGap).ceilToDouble() + 2;
    final columns = categories == null
        ? _placeholderColumns
        : (categories.length + 1) ~/ 2;

    Widget tile(int index) {
      if (categories == null) return const _TileImage(child: null);
      if (index >= categories.length) return const SizedBox.shrink();
      final category = categories[index];
      return _CategoryTile(
        category: category,
        onTap: () => onSelected(category),
      );
    }

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Spans the full screen width, so there's nothing to clip.
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: columns,
        separatorBuilder: (context, index) => const SizedBox(width: _columnGap),
        itemBuilder: (context, column) => SizedBox(
          width: tileWidth,
          child: Column(
            children: [
              SizedBox(height: tileHeight, child: tile(column * 2)),
              const SizedBox(height: _rowGap),
              SizedBox(height: tileHeight, child: tile(column * 2 + 1)),
            ],
          ),
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
      label:
          '${category.name}, ${category.count} '
          '${category.count == 1 ? 'prodotto' : 'prodotti'}',
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
