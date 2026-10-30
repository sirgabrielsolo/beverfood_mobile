import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/app_assets.dart';
import 'package:beverfood_mobile/app/router.dart';

/// Brand logo plus search bar shown at the top of the home page.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  /// Matches the search bar so the two line up as one row.
  static const _height = 48.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          AppAssets.logo,
          height: _height,
          semanticLabel: 'Beverfood',
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            textInputAction: TextInputAction.search,
            // Searching opens the catalogue filtered by the query.
            onSubmitted: (query) {
              if (query.trim().isEmpty) return;
              context.go(AppRoutes.productsWith(query: query.trim()));
            },
            decoration: const InputDecoration(
              hintText: 'Cerca vini, birre, caffè…',
              prefixIcon: Icon(Icons.search_rounded),
              constraints: BoxConstraints.tightFor(height: _height),
            ),
          ),
        ),
      ],
    );
  }
}
