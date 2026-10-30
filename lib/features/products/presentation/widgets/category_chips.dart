import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';

/// Horizontally scrolling category filter. A `null` category means "Tutti".
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    const categories = [null, ...ProductCategory.values];

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == selected;
          return ChoiceChip(
            label: Text(category?.label ?? 'Tutti'),
            selected: isSelected,
            onSelected: (_) => onSelected(category),
            showCheckmark: false,
            shape: const StadiumBorder(),
            side: BorderSide.none,
            backgroundColor: context.palette.chip,
            selectedColor: AppColors.accent,
            labelStyle: TextStyle(
              color: isSelected ? AppColors.onAccent : context.palette.onChip,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }
}
