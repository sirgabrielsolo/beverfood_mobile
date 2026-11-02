import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/features/products/models/product_sort.dart';

/// Bottom sheet listing the sort options. Returns the chosen one, or `null`
/// if dismissed.
Future<ProductSort?> showSortSheet(
  BuildContext context, {
  required ProductSort selected,
}) {
  return showModalBottomSheet<ProductSort>(
    context: context,
    showDragHandle: true,
    // Sized to its content rather than capped at 9/16 of the screen; scrolls
    // when the screen is too short.
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Ordina per',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
            ),
            for (final sort in ProductSort.values)
              ListTile(
                title: Text(
                  sort.label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: sort == selected
                        ? FontWeight.w900
                        : FontWeight.w600,
                  ),
                ),
                trailing: sort == selected
                    ? Icon(
                        Icons.check_rounded,
                        color: context.palette.brandText,
                      )
                    : null,
                onTap: () => Navigator.pop(context, sort),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    ),
  );
}
