import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/formatting/price_format.dart';
import 'package:beverfood_mobile/core/widgets/empty_state.dart';
import 'package:beverfood_mobile/core/widgets/load_error_row.dart';
import 'package:beverfood_mobile/features/auth/data/auth_controller.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/account_notice.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:beverfood_mobile/features/cart/data/cart_controller.dart';
import 'package:beverfood_mobile/features/cart/presentation/widgets/cart_line_tile.dart';
import 'package:beverfood_mobile/features/orders/presentation/widgets/order_summary.dart';
import 'package:beverfood_mobile/features/products/data/catalog_repository.dart';

/// The Carrello tab (K1): one compact row per product (photo, name and pack,
/// unit price, stepper, line total, "Rimuovi"), promos first with their mix;
/// then the notes for Beverfood (N1) and the totals. "Procedi" opens the
/// review page (C2) once the account may order and the order reaches the
/// minimum.
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _notes = TextEditingController();
  final _notesFocus = FocusNode();
  CartController? _cart;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final cart = CartScope.read(context);
    if (cart != _cart) {
      _cart?.removeListener(_followNotes);
      _cart = cart..addListener(_followNotes);
      _notes.text = cart.notes;
    }
  }

  /// The notes follow the cart when it changes elsewhere (emptied after an
  /// order, restored at launch); typed text goes the other way.
  void _followNotes() {
    final notes = _cart!.notes;
    if (_notes.text != notes) _notes.text = notes;
  }

  @override
  void dispose() {
    _cart?.removeListener(_followNotes);
    _notes.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final palette = context.palette;
    final count = cart.itemCount;

    return Scaffold(
      appBar: AppBar(
        title: Text.rich(
          TextSpan(
            text: 'Carrello',
            children: [
              if (count > 0)
                TextSpan(
                  text: count == 1 ? '   1 articolo' : '   $count articoli',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: palette.textSecondary,
                  ),
                ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (!cart.isEmpty)
            PopupMenuButton<void>(
              tooltip: 'Altre azioni',
              icon: const Icon(Icons.more_vert_rounded),
              itemBuilder: (context) => [
                PopupMenuItem(
                  onTap: () => _confirmEmpty(context),
                  child: const Text('Svuota carrello'),
                ),
              ],
            ),
        ],
      ),
      body: cart.isEmpty
          ? Column(
              children: [
                // The same notice as on Home (D2): ordering waits for approval.
                const AccountNotice(padding: EdgeInsets.fromLTRB(16, 8, 16, 0)),
                Expanded(
                  child: EmptyState(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Il tuo carrello è vuoto',
                    message:
                        'Aggiungi i prodotti che ti piacciono per vederli qui.',
                    action: FilledButton(
                      onPressed: () => context.go(AppRoutes.products),
                      child: const Text('Scopri i prodotti'),
                    ),
                  ),
                ),
              ],
            )
          : _CartList(notes: _notes, notesFocus: _notesFocus),
      bottomNavigationBar: cart.isEmpty ? null : const _ProceedBar(),
    );
  }

  Future<void> _confirmEmpty(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Svuotare il carrello?'),
        content: const Text('Togliamo tutti i prodotti e le note.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
            child: const Text(
              'Svuota',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) CartScope.read(context).clear();
  }
}

class _CartList extends StatelessWidget {
  const _CartList({required this.notes, required this.notesFocus});

  final TextEditingController notes;
  final FocusNode notesFocus;

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final catalog = CatalogScope.of(context);
    final palette = context.palette;
    final tiles = [
      for (final line in cart.promoLines) CartPromoTile(line: line),
      for (final line in cart.productLines) CartProductTile(line: line),
    ];

    return ListView(
      // LoadErrorRow brings its own side padding.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const AccountNotice(padding: EdgeInsets.only(bottom: 12)),
        if (cart.isUpdating &&
            (catalog.status == CatalogStatus.failed || cart.promosFailed))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LoadErrorRow(
              message: 'Prezzi non aggiornati',
              onRetry: () {
                if (catalog.catalog == null) catalog.load();
                cart.reloadPromos();
              },
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadii.card,
          ),
          child: Column(
            children: [
              for (final (i, tile) in tiles.indexed) ...[
                if (i > 0) const Divider(height: 1, indent: 12, endIndent: 12),
                tile,
              ],
            ],
          ),
        ),
        const SectionLabel('Note per Beverfood'),
        _NotesField(controller: notes, focusNode: notesFocus),
        const SizedBox(height: 20),
        OrderTotals(subtotal: cart.subtotal, vat: cart.vat),
      ],
    );
  }
}

/// "Note per Beverfood" (N1): up to 500 characters, kept with the cart.
class _NotesField extends StatelessWidget {
  const _NotesField({required this.controller, required this.focusNode});

  static const maxLength = 500;

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      minLines: 2,
      maxLines: 6,
      maxLength: maxLength,
      keyboardType: TextInputType.multiline,
      textCapitalization: TextCapitalization.sentences,
      onChanged: CartScope.read(context).setNotes,
      onTapOutside: (_) => focusNode.unfocus(),
      style: TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
        color: palette.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Orari di consegna, accesso, richieste…',
        filled: true,
        fillColor: palette.surface,
        contentPadding: const EdgeInsets.all(12),
        enabledBorder: border(palette.line),
        focusedBorder: border(AppColors.brand, 2),
        border: border(palette.line),
        counterStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: palette.textSecondary,
        ),
      ),
    );
  }
}

/// "Procedi" above the navigation bar, with what still stops the order.
class _ProceedBar extends StatelessWidget {
  const _ProceedBar();

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final account = AuthScope.of(context).account;
    final palette = context.palette;
    final minimum = account?.orderMinimum ?? 150;
    final missing = minimum - cart.subtotal;

    final String? hint;
    if (cart.isUpdating) {
      hint = 'Aggiornamento dei prezzi…';
    } else if (cart.itemCount == 0) {
      hint = 'Nessun prodotto disponibile da ordinare.';
    } else if (missing > 0.004) {
      hint =
          'Ordine minimo ${formatPrice(minimum)} + IVA: '
          'mancano ${formatPrice(missing)}.';
    } else {
      hint = null;
    }
    final canProceed = hint == null && (account?.canOrder ?? false);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  hint,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            WideButton(
              label: 'Procedi · ${formatPrice(cart.subtotal)} + IVA',
              onPressed: canProceed
                  ? () => context.push(AppRoutes.checkout)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
