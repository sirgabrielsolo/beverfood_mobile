import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/widgets/app_network_image.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';

/// Horizontally scrolling row of category tiles: a cover image in a card,
/// with the category name underneath.
class CategoryTiles extends StatelessWidget {
  const CategoryTiles({
    super.key,
    required this.imageUrlFor,
    required this.onSelected,
  });

  final String Function(ProductCategory category) imageUrlFor;
  final ValueChanged<ProductCategory> onSelected;

  static const _tileWidth = 84.0;
  static const _labelGap = 8.0;
  static const _labelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.3,
  );

  @override
  Widget build(BuildContext context) {
    final labelHeight =
        MediaQuery.textScalerOf(context).scale(_labelStyle.fontSize!) *
        _labelStyle.height!;

    return SizedBox(
      height: _tileWidth + _labelGap + labelHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // Spans the full screen width, so there's nothing to clip.
        clipBehavior: Clip.none,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: ProductCategory.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final category = ProductCategory.values[index];
          return _CategoryTile(
            label: category.label,
            imageUrl: imageUrlFor(category),
            labelHeight: labelHeight,
            onTap: () => onSelected(category),
          );
        },
      ),
    );
  }
}

// Its own widget so the theme colors are read (and updated on a theme change)
// in its own build, not through the list builder's context.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.label,
    required this.imageUrl,
    required this.labelHeight,
    required this.onTap,
  });

  final String label;
  final String imageUrl;
  final double labelHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: CategoryTiles._tileWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: CategoryTiles._tileWidth,
              height: CategoryTiles._tileWidth,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: AppRadii.card,
              ),
              child: ClipRRect(
                borderRadius: AppRadii.image,
                child: AppNetworkImage(imageUrl),
              ),
            ),
            const SizedBox(height: CategoryTiles._labelGap),
            SizedBox(
              height: labelHeight,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: CategoryTiles._labelStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
