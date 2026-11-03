import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';

/// The cart's stepper: the product cards' red stepper, smaller. Bin at 1,
/// then minus; the quantity (tap it to type one); plus.
class CartStepper extends StatelessWidget {
  const CartStepper({
    super.key,
    required this.quantity,
    required this.onRemove,
    required this.onAdd,
    required this.onEdit,
  });

  static const width = 112.0;
  static const height = 34.0;

  final int quantity;
  final VoidCallback onRemove;
  final VoidCallback onAdd;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final removesProduct = quantity == 1;
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: AppColors.brand,
        borderRadius: AppRadii.button,
        child: Row(
          children: [
            _Button(
              icon: removesProduct
                  ? Icons.delete_outline_rounded
                  : Icons.remove_rounded,
              label: removesProduct ? 'Rimuovi dal carrello' : 'Rimuovi uno',
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(10),
              ),
              onTap: onRemove,
            ),
            Expanded(
              child: Semantics(
                button: true,
                label: 'Quantità $quantity',
                hint: 'Tocca per scriverla',
                excludeSemantics: true,
                child: InkWell(
                  onTap: onEdit,
                  child: Center(
                    child: Text(
                      '$quantity',
                      maxLines: 1,
                      style: const TextStyle(
                        color: AppColors.onBrand,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _Button(
              icon: Icons.add_rounded,
              label: 'Aggiungi uno',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(10),
              ),
              onTap: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.icon,
    required this.label,
    required this.borderRadius,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: SizedBox(
          width: 36,
          height: double.infinity,
          child: Icon(icon, size: 17, color: AppColors.onBrand),
        ),
      ),
    );
  }
}
