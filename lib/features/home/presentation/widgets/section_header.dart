import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';

/// Section title with an optional "Vedi tutti" link on the right.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll});

  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w600),
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                foregroundColor: context.palette.textSecondary,
              ),
              child: const Text('Vedi tutti'),
            ),
        ],
      ),
    );
  }
}
