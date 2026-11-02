import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/widgets/app_network_image.dart';
import 'package:beverfood_mobile/core/widgets/net_price_text.dart';
import 'package:beverfood_mobile/features/cart/data/cart_controller.dart';
import 'package:beverfood_mobile/features/products/data/favourites_controller.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';

/// Product tile: square image with a favourite heart, a two-line name, the
/// price, and a full-width "Aggiungi" button that turns into a quantity
/// stepper of the same size.
///
/// The card is its width + [textHeight] tall; lists and grids use that to
/// size their items exactly.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    this.showNewBadge = false,
  });

  final Product product;

  /// Shows the "NUOVO" label on the image.
  final bool showNewBadge;

  static const _padding = 8.0;
  static const _gap = 8.0;
  static const _cartBarHeight = 38.0;

  static const _priceStyle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w900,
    height: 1.2,
  );

  static const _nameStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  /// Height of the card beyond its width (the image is square, inset by the
  /// padding), respecting the user's font scale.
  static double textHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return 3 * _gap +
        _nameHeight(scaler) +
        _priceHeight(scaler) +
        _cartBarHeight;
  }

  // Two lines, fixed so prices line up across a row.
  static double _nameHeight(TextScaler scaler) =>
      2 * scaler.scale(_nameStyle.fontSize!) * _nameStyle.height!;

  static double _priceHeight(TextScaler scaler) =>
      scaler.scale(_priceStyle.fontSize!) * _priceStyle.height!;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);

    return Material(
      color: context.palette.surface,
      borderRadius: AppRadii.card,
      child: Padding(
        padding: const EdgeInsets.all(_padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: AppRadii.image,
                    child: AppNetworkImage(product.imageUrl),
                  ),
                  if (showNewBadge)
                    const Positioned(top: 6, left: 6, child: _NewBadge()),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: _FavouriteButton(product: product),
                  ),
                ],
              ),
            ),
            const SizedBox(height: _gap),
            SizedBox(
              height: _nameHeight(scaler),
              child: Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _nameStyle,
              ),
            ),
            const SizedBox(height: _gap),
            SizedBox(
              height: _priceHeight(scaler),
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: NetPriceText(product.price, style: _priceStyle),
              ),
            ),
            const SizedBox(height: _gap),
            _CartBar(product: product),
          ],
        ),
      ),
    );
  }
}

class _NewBadge extends StatelessWidget {
  const _NewBadge();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: AppRadii.badge,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        child: Text(
          'NUOVO',
          style: TextStyle(
            color: AppColors.onAccent,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

/// 30 pt heart in a circle, with a 44 pt tap target.
class _FavouriteButton extends StatelessWidget {
  const _FavouriteButton({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final favourites = FavouritesScope.of(context);
    final isFavourite = favourites.isFavourite(product);

    return Semantics(
      button: true,
      label: isFavourite ? 'Rimuovi dai preferiti' : 'Aggiungi ai preferiti',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => favourites.toggle(product),
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: context.palette.favBackground,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFavourite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                size: 16,
                color: isFavourite
                    ? AppColors.brand
                    : context.palette.favForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Full-width "Aggiungi" button when the product isn't in the cart, a
/// stepper of the same size otherwise: bin (at 1) or minus, quantity, plus.
///
/// On the first add the label slides up and out while the stepper slides in
/// from below, and back on removal.
class _CartBar extends StatelessWidget {
  const _CartBar({required this.product});

  final Product product;

  static const _duration = Duration(milliseconds: 220);

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final quantity = cart.quantityOf(product);
    final inCart = quantity > 0;

    return SizedBox(
      height: ProductCard._cartBarHeight,
      child: Material(
        color: AppColors.brand,
        borderRadius: AppRadii.button,
        // 0 shows the "Aggiungi" label, 1 the stepper. Starts at the current
        // state, so cards scrolled into view don't animate.
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: inCart ? 1 : 0),
          duration: _duration,
          curve: const Cubic(0.2, 0.8, 0.2, 1),
          builder: (context, t, _) {
            final slide = t * ProductCard._cartBarHeight;
            final layers = Stack(
              fit: StackFit.expand,
              children: [
                if (t < 1)
                  _slidingLayer(
                    dy: -slide,
                    active: !inCart,
                    child: _AddLabel(
                      alpha: 1 - t,
                      onTap: () => cart.add(product),
                    ),
                  ),
                if (t > 0)
                  _slidingLayer(
                    dy: ProductCard._cartBarHeight - slide,
                    active: inCart,
                    child: _Stepper(
                      alpha: t,
                      // Keeps showing 1 while sliding out after the last
                      // removal.
                      quantity: inCart ? quantity : 1,
                      onRemove: () => cart.removeOne(product),
                      onAdd: () => cart.add(product),
                    ),
                  ),
              ],
            );

            // Clip only while sliding: at rest nothing sticks out, and a
            // clip per card is costly while scrolling.
            if (t == 0 || t == 1) return layers;
            return ClipRRect(borderRadius: AppRadii.button, child: layers);
          },
        ),
      ),
    );
  }

  /// A layer of the bar moved by [dy]; taps and semantics only when [active].
  static Widget _slidingLayer({
    required double dy,
    required bool active,
    required Widget child,
  }) {
    return Transform.translate(
      offset: Offset(0, dy),
      child: IgnorePointer(
        ignoring: !active,
        child: ExcludeSemantics(excluding: !active, child: child),
      ),
    );
  }
}

/// Cart icon and "Aggiungi", faded by color alpha.
class _AddLabel extends StatelessWidget {
  const _AddLabel({required this.alpha, required this.onTap});

  final double alpha;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.onBrand.withValues(alpha: alpha);

    return Semantics(
      button: true,
      label: 'Aggiungi al carrello',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        // The ripple is shaped by the InkWell instead of clipping.
        borderRadius: AppRadii.button,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 18, color: color),
                  const SizedBox(width: 8),
                  Text(
                    'Aggiungi',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.alpha,
    required this.quantity,
    required this.onRemove,
    required this.onAdd,
  });

  final double alpha;
  final int quantity;
  final VoidCallback onRemove;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.onBrand.withValues(alpha: alpha);
    // At 1 the next tap takes the product out of the cart, so it's a bin.
    final removesProduct = quantity == 1;

    return Row(
      children: [
        _StepperButton(
          icon: removesProduct
              ? Icons.delete_outline_rounded
              : Icons.remove_rounded,
          label: removesProduct ? 'Rimuovi dal carrello' : 'Rimuovi uno',
          color: color,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(10),
          ),
          onTap: onRemove,
        ),
        Expanded(
          child: _QuantityText(quantity: quantity, color: color),
        ),
        _StepperButton(
          icon: Icons.add_rounded,
          label: 'Aggiungi uno',
          color: color,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(10),
          ),
          onTap: onAdd,
        ),
      ],
    );
  }
}

/// The quantity, which briefly grows when it changes.
class _QuantityText extends StatefulWidget {
  const _QuantityText({required this.quantity, required this.color});

  final int quantity;
  final Color color;

  @override
  State<_QuantityText> createState() => _QuantityTextState();
}

class _QuantityTextState extends State<_QuantityText>
    with SingleTickerProviderStateMixin {
  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );

  // Up to 1.35× at 40% of the way, then back.
  late final _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: 1.35), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.35, end: 1), weight: 60),
  ]).animate(CurvedAnimation(parent: _pop, curve: Curves.easeOut));

  @override
  void didUpdateWidget(_QuantityText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ScaleTransition(
        scale: _scale,
        child: Text(
          '${widget.quantity}',
          maxLines: 1,
          style: TextStyle(
            color: widget.color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// 44 pt wide stepper button, as tall as the bar.
class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.borderRadius,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;

  /// Shapes the ripple to the bar's outer corners.
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
          width: 44,
          height: double.infinity,
          child: Icon(icon, size: 18, color: color),
        ),
      ),
    );
  }
}
