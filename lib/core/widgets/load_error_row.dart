import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';

/// "Promozioni non disponibili · Riprova": a section that could not load.
class LoadErrorRow extends StatelessWidget {
  const LoadErrorRow({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: palette.surface,
        borderRadius: AppRadii.card,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 6, 6),
          child: Row(
            children: [
              Icon(Icons.cloud_off_outlined, color: palette.textSecondary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: palette.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: palette.brandText,
                  textStyle: const TextStyle(fontWeight: FontWeight.w800),
                ),
                child: const Text('Riprova'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
