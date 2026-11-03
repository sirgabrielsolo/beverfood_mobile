import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/formatting/price_format.dart';
import 'package:beverfood_mobile/core/widgets/app_network_image.dart';
import 'package:beverfood_mobile/features/cart/data/cart_controller.dart';
import 'package:beverfood_mobile/features/cart/presentation/widgets/cart_stepper.dart';
import 'package:beverfood_mobile/features/cart/presentation/widgets/quantity_sheet.dart';

/// A product row of the cart: photo, name, pack and unit price with
/// "Rimuovi" underneath; the stepper and the line total on the right.
/// A product no longer sold is greyed, "Non più disponibile", with only
/// "Rimuovi".
class CartProductTile extends StatelessWidget {
  const CartProductTile({super.key, required this.line});

  final CartProductLine line;

  @override
  Widget build(BuildContext context) {
    final product = line.product;
    final ok = line.status == CartLineStatus.ok;
    final cart = CartScope.read(context);

    final name = product?.shortName ?? line.name;
    final details = <Widget>[
      if (product != null && product.format.isNotEmpty)
        _Secondary(product.format),
      switch (line.status) {
        CartLineStatus.ok => _Secondary(
          '${formatPrice(product!.price)} cad. + IVA',
        ),
        CartLineStatus.loading => const _Secondary('Aggiornamento…'),
        _ => const _Warning('Non più disponibile'),
      },
    ];

    return _TileLayout(
      dimmed: !ok,
      thumb: _Thumb(url: product?.imageUrl),
      name: name,
      details: details,
      links: [
        _Link(
          label: 'Rimuovi',
          semanticsLabel: 'Rimuovi $name',
          onTap: () => removeWithUndo(context, line.productId),
        ),
      ],
      trailing: ok
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                CartStepper(
                  quantity: line.quantity,
                  onRemove: line.quantity == 1
                      ? () => removeWithUndo(context, line.productId)
                      : () => cart.removeOne(product!),
                  onAdd: () => cart.add(product!),
                  onEdit: () async {
                    final quantity = await askQuantity(
                      context,
                      productName: name,
                      current: line.quantity,
                    );
                    if (quantity == null || !context.mounted) return;
                    if (quantity == 0) {
                      removeWithUndo(context, line.productId);
                    } else {
                      cart.setQuantity(product!, quantity);
                    }
                  },
                ),
                const SizedBox(height: 8),
                _LineTotal(product!.price * line.quantity),
              ],
            )
          : null,
    );
  }

  /// Takes the line out, with "Annulla" in a message (F2).
  static void removeWithUndo(BuildContext context, String productId) {
    final cart = CartScope.read(context);
    final removal = cart.remove(productId);
    if (removal == null) return;
    _showUndo(
      context,
      '${removal.product?.shortName ?? removal.name} rimosso dal carrello',
      () => cart.undoRemove(removal),
    );
  }
}

/// A promo row: its picture, name and mix, "Modifica" (its page) and
/// "Rimuovi"; the price on the right. A promo whose rule changed asks to be
/// chosen again.
class CartPromoTile extends StatelessWidget {
  const CartPromoTile({super.key, required this.line});

  final CartPromoLine line;

  @override
  Widget build(BuildContext context) {
    final selection = line.selection;
    final ok = line.status == CartLineStatus.ok;
    final canEdit =
        line.status == CartLineStatus.ok ||
        line.status == CartLineStatus.changed;

    return _TileLayout(
      dimmed: !ok,
      thumb: _Thumb(url: selection?.promo.imageUrl),
      name: line.name,
      details: [
        if (selection != null)
          for (final text in selection.contents) _Secondary(text),
        switch (line.status) {
          CartLineStatus.ok => const SizedBox.shrink(),
          CartLineStatus.loading => const _Secondary('Aggiornamento…'),
          CartLineStatus.changed => const _Warning(
            'La promozione è cambiata: scegli di nuovo i prodotti.',
          ),
          CartLineStatus.unavailable => const _Warning('Non più disponibile'),
        },
      ],
      links: [
        if (canEdit)
          _Link(
            label: 'Modifica',
            semanticsLabel: 'Modifica ${line.name}',
            onTap: () => context.push(
              AppRoutes.promo(line.promoId),
              extra: selection?.promo,
            ),
          ),
        _Link(
          label: 'Rimuovi',
          semanticsLabel: 'Rimuovi ${line.name}',
          onTap: () {
            final cart = CartScope.read(context);
            final removal = cart.removePromo(line.promoId);
            if (removal == null) return;
            _showUndo(
              context,
              '${line.name} rimossa dal carrello',
              () => cart.undoRemovePromo(removal),
            );
          },
        ),
      ],
      trailing: ok ? _LineTotal(selection!.promo.price) : null,
    );
  }
}

void _showUndo(BuildContext context, String message, VoidCallback undo) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(label: 'Annulla', onPressed: undo),
      ),
    );
}

class _TileLayout extends StatelessWidget {
  const _TileLayout({
    required this.dimmed,
    required this.thumb,
    required this.name,
    required this.details,
    required this.links,
    this.trailing,
  });

  final bool dimmed;
  final Widget thumb;
  final String name;
  final List<Widget> details;
  final List<Widget> links;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // A cart has a few dozen rows at most: a plain Opacity is fine.
          Opacity(opacity: dimmed ? 0.45 : 1, child: thumb),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                    color: dimmed ? palette.textSecondary : palette.textPrimary,
                  ),
                ),
                ...details,
                Wrap(spacing: 4, children: links),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadii.image,
      child: SizedBox.square(
        dimension: 58,
        child: ColoredBox(
          color: context.palette.cutoutBackground,
          child: url == null
              ? null
              : Padding(
                  padding: const EdgeInsets.all(5),
                  child: AppNetworkImage(url!, fit: BoxFit.contain),
                ),
        ),
      ),
    );
  }
}

class _Secondary extends StatelessWidget {
  const _Secondary(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: context.palette.textSecondary,
      ),
    );
  }
}

class _Warning extends StatelessWidget {
  const _Warning(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
        height: 1.35,
        color: context.palette.brandText,
      ),
    );
  }
}

/// "Rimuovi", "Modifica": brand-colored text with a 36 pt tap area.
class _Link extends StatelessWidget {
  const _Link({
    required this.label,
    required this.semanticsLabel,
    required this.onTap,
  });

  final String label;
  final String semanticsLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.badge,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 6, 12, 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
                color: context.palette.brandText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineTotal extends StatelessWidget {
  const _LineTotal(this.value);

  final double value;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatPrice(value),
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w900,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
  }
}
