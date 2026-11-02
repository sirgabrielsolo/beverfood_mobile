import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/formatting/price_format.dart';
import 'package:beverfood_mobile/core/formatting/product_name.dart';
import 'package:beverfood_mobile/core/widgets/app_network_image.dart';
import 'package:beverfood_mobile/core/widgets/empty_state.dart';
import 'package:beverfood_mobile/core/widgets/net_price_text.dart';
import 'package:beverfood_mobile/features/cart/data/cart_controller.dart';
import 'package:beverfood_mobile/features/promotions/data/promo_repository.dart';
import 'package:beverfood_mobile/features/promotions/models/promo.dart';
import 'package:beverfood_mobile/features/promotions/models/promo_selection.dart';

/// A promo's page, opened from its Home banner: the banner, the price and
/// what the client saves, then what the bundle holds. Freely mixed groups
/// (Lilia, Schweppes…) are picked with steppers; the bundle goes in the cart,
/// at most once per order, when every group is complete.
///
/// Gets the [promo] from the banner it was opened from; opened by its
/// location alone, it loads it again by [promoId].
class PromoPage extends StatelessWidget {
  const PromoPage({super.key, required this.promoId, this.promo});

  final int promoId;
  final Promo? promo;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Opened by its location alone (e.g. a web link), there's nothing to
        // go back to: the arrow leads Home instead.
        leading: context.canPop()
            ? null
            : BackButton(onPressed: () => context.go(AppRoutes.home)),
        title: const Text('Promozione'),
      ),
      body: promo != null ? _PromoContent(promo: promo!) : _load(context),
    );
  }

  Widget _load(BuildContext context) {
    return FutureBuilder(
      future: PromoRepositoryScope.of(context).getActivePromos(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Promozione non disponibile',
          );
        }
        final promos = snapshot.data;
        if (promos == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final found = promos.where((p) => p.id == promoId).firstOrNull;
        if (found == null) {
          return const EmptyState(
            icon: Icons.local_offer_outlined,
            title: 'Questa promozione non è più attiva',
          );
        }
        return _PromoContent(promo: found);
      },
    );
  }
}

class _PromoContent extends StatefulWidget {
  const _PromoContent({required this.promo});

  final Promo promo;

  @override
  State<_PromoContent> createState() => _PromoContentState();
}

class _PromoContentState extends State<_PromoContent> {
  PromoSelection? _selection;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Starts from the mix already in the cart, if any.
    _selection ??=
        CartScope.of(context).promoSelection(widget.promo.id) ??
        PromoSelection(widget.promo);
  }

  @override
  Widget build(BuildContext context) {
    final selection = _selection!;
    final promo = widget.promo;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: [
              _Hero(promo: promo),
              const SizedBox(height: 16),
              _PriceRow(selection: selection),
              for (var i = 0; i < promo.groups.length; i++) ...[
                const SizedBox(height: 16),
                _GroupCard(
                  selection: selection,
                  group: i,
                  // Applied to the latest selection, so taps in the same
                  // frame don't overwrite each other.
                  onUpdate: (change) =>
                      setState(() => _selection = change(_selection!)),
                ),
              ],
            ],
          ),
        ),
        _CartActions(selection: selection),
      ],
    );
  }
}

/// The wide banner (the square image if the promo has none). Its texts are
/// in the image, so the page doesn't repeat the title.
class _Hero extends StatelessWidget {
  const _Hero({required this.promo});

  final Promo promo;

  @override
  Widget build(BuildContext context) {
    final banner = promo.bannerUrl;
    final label = [
      promo.title,
      promo.highlight,
      promo.subtitle,
    ].where((text) => text.isNotEmpty).join(', ');

    return Semantics(
      label: label,
      image: true,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: banner != null ? 300 / 124 : 2,
        child: ClipRRect(
          borderRadius: AppRadii.card,
          child: banner != null
              ? AppNetworkImage(banner)
              : ColoredBox(
                  color: context.palette.cutoutBackground,
                  child: AppNetworkImage(promo.imageUrl, fit: BoxFit.contain),
                ),
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.selection});

  final PromoSelection selection;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final savings = selection.savings;

    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        NetPriceText(
          selection.promo.price,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: palette.textPrimary,
          ),
        ),
        if (savings >= 0.01)
          DecoratedBox(
            decoration: BoxDecoration(
              // The same pale brand tint as the navigation indicator.
              color: palette.navIndicator,
              borderRadius: AppRadii.badge,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text(
                'Risparmi ${formatPrice(savings)}',
                style: TextStyle(
                  color: palette.brandText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.selection,
    required this.group,
    required this.onUpdate,
  });

  final PromoSelection selection;
  final int group;
  final void Function(PromoSelection Function(PromoSelection)) onUpdate;

  String _title(PromoGroup g) {
    final free = g.role == PromoRole.free;
    if (g.mode == PromoMode.total) {
      if (free) return 'Scegli ${g.quantity} in omaggio';
      return g.quantity == 1
          ? 'Scegli 1 confezione'
          : 'Scegli ${g.quantity} confezioni';
    }
    if (free) return 'In omaggio';
    return selection.promo.groups.length == 1 ? 'Il prodotto' : 'Nel pacchetto';
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final g = selection.promo.groups[group];
    final mixed = g.mode == PromoMode.total;
    final chosen = selection.chosen(group);
    final required = selection.required(group);
    final complete = chosen == required;

    return Material(
      color: palette.surface,
      borderRadius: AppRadii.card,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title(g),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (mixed)
                  Text(
                    '$chosen / $required',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: complete
                          ? palette.brandText
                          : palette.textSecondary,
                    ),
                  ),
              ],
            ),
            if (mixed) ...[
              const SizedBox(height: 10),
              _Progress(value: required == 0 ? 1 : chosen / required),
            ],
            for (final product in g.products) ...[
              const SizedBox(height: 12),
              _ProductRow(
                product: product,
                free: g.role == PromoRole.free,
                trailing: mixed
                    ? _MixStepper(
                        count: selection.countOf(group, product.id),
                        canAdd: !complete,
                        label:
                            splitProductName(product.name).name +
                            (g.role == PromoRole.free ? ' in omaggio' : ''),
                        onStep: (delta) => onUpdate(
                          (s) => s.withCount(
                            group,
                            product.id,
                            s.countOf(group, product.id) + delta,
                          ),
                        ),
                      )
                    : Text(
                        '× ${g.quantity}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 4,
        child: ColoredBox(
          color: context.palette.line,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: value.clamp(0, 1),
              heightFactor: 1,
              child: const ColoredBox(color: AppColors.brand),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.free,
    required this.trailing,
  });

  final PromoProduct product;
  final bool free;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final name = splitProductName(product.name);

    return Row(
      children: [
        SizedBox.square(
          dimension: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: palette.cutoutBackground,
              borderRadius: AppRadii.image,
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: AppNetworkImage(product.imageUrl, fit: BoxFit.contain),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name.name,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              if (name.pack.isNotEmpty)
                Text(
                  name.pack,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              if (free) ...[const SizedBox(height: 3), const _FreeBadge()],
            ],
          ),
        ),
        const SizedBox(width: 10),
        trailing,
      ],
    );
  }
}

class _FreeBadge extends StatelessWidget {
  const _FreeBadge();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.brand,
        borderRadius: AppRadii.badge,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          'OMAGGIO',
          style: TextStyle(
            color: AppColors.onBrand,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

/// − count + for one product of a freely mixed group.
class _MixStepper extends StatelessWidget {
  const _MixStepper({
    required this.count,
    required this.canAdd,
    required this.label,
    required this.onStep,
  });

  final int count;
  final bool canAdd;

  /// The product, for the buttons' semantics ("Aggiungi Lilia Naturale").
  final String label;

  /// +1 or −1.
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.brand,
      borderRadius: AppRadii.button,
      child: SizedBox(
        height: 34,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StepButton(
              icon: Icons.remove_rounded,
              semanticLabel: 'Togli $label',
              onTap: count > 0 ? () => onStep(-1) : null,
            ),
            SizedBox(
              width: 24,
              child: Text(
                '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.onBrand,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
            _StepButton(
              icon: Icons.add_rounded,
              semanticLabel: 'Aggiungi $label',
              onTap: canAdd ? () => onStep(1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      button: true,
      enabled: onTap != null,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.button,
        child: SizedBox.square(
          dimension: 34,
          child: Icon(
            icon,
            size: 20,
            color: AppColors.onBrand.withValues(alpha: onTap == null ? 0.4 : 1),
          ),
        ),
      ),
    );
  }
}

/// The bar under the page: what's still missing, "Aggiungi", or the promo's
/// state in the cart. 38 pt, like the cards' "Aggiungi" bar.
class _CartActions extends StatelessWidget {
  const _CartActions({required this.selection});

  final PromoSelection selection;

  static const _height = 38.0;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final cart = CartScope.of(context);
    final inCart = cart.promoSelection(selection.promo.id);
    final missing = selection.firstMissing;

    final Widget main;
    if (missing != null) {
      final free = missing.group.role == PromoRole.free;
      main = _BarButton(
        label: Text(
          'Scegli ancora ${missing.remaining}${free ? ' in omaggio' : ''}',
        ),
      );
    } else if (inCart == null) {
      main = _BarButton(
        filled: true,
        onPressed: () => cart.putPromo(selection),
        icon: Icons.shopping_cart_outlined,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Aggiungi · '),
            NetPriceText(
              selection.promo.price,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColors.onBrand,
              ),
              suffixColor: AppColors.onBrand.withValues(alpha: 0.85),
            ),
          ],
        ),
      );
    } else if (inCart.sameChoicesAs(selection)) {
      main = const _BarButton(
        tonal: true,
        icon: Icons.check_rounded,
        label: Text('Nel carrello'),
      );
    } else {
      main = _BarButton(
        filled: true,
        onPressed: () => cart.putPromo(selection),
        icon: Icons.refresh_rounded,
        label: const Text('Aggiorna il carrello'),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.surface,
        border: Border(top: BorderSide(color: palette.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: SizedBox(
            height: _height,
            child: Row(
              children: [
                if (inCart != null) ...[
                  Semantics(
                    label: 'Rimuovi dal carrello',
                    button: true,
                    excludeSemantics: true,
                    child: Material(
                      color: palette.background,
                      borderRadius: AppRadii.button,
                      child: InkWell(
                        borderRadius: AppRadii.button,
                        onTap: () => cart.removePromo(selection.promo.id),
                        child: SizedBox.square(
                          dimension: _height,
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(child: main),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.label,
    this.icon,
    this.onPressed,
    this.filled = false,
    this.tonal = false,
  });

  final Widget label;
  final IconData? icon;
  final VoidCallback? onPressed;

  /// Brand red: the action to take.
  final bool filled;

  /// Pale brand tint: a state ("Nel carrello"). Neither: disabled grey.
  final bool tonal;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final (background, foreground) = filled
        ? (AppColors.brand, AppColors.onBrand)
        : tonal
        ? (palette.navIndicator, palette.brandText)
        : (palette.line, palette.textSecondary);

    return Material(
      color: background,
      borderRadius: AppRadii.button,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadii.button,
        child: Center(
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: foreground,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: foreground),
                    const SizedBox(width: 6),
                  ],
                  label,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
