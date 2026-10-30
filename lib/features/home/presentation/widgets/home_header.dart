import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';

/// Search bar plus profile avatar shown at the top of the home page.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
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
              constraints: BoxConstraints.tightFor(height: 48),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Semantics(
          button: true,
          label: 'Profilo',
          child: GestureDetector(
            onTap: () => context.go(AppRoutes.profile),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: primary.withValues(alpha: 0.15),
              child: Icon(Icons.person_rounded, color: primary),
            ),
          ),
        ),
      ],
    );
  }
}
