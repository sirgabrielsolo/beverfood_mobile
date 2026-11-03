import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:beverfood_mobile/features/cart/data/cart_controller.dart';

/// Asks for a quantity with the number keypad (F3): tapping the number of a
/// stepper, on a product card or in the cart, so 20 cases take no 20 taps.
/// Returns the new quantity (0 takes the product out), or null if dismissed.
Future<int?> askQuantity(
  BuildContext context, {
  required String productName,
  required int current,
}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    backgroundColor: context.palette.surface,
    builder: (context) =>
        _QuantitySheet(productName: productName, current: current),
  );
}

class _QuantitySheet extends StatefulWidget {
  const _QuantitySheet({required this.productName, required this.current});

  final String productName;
  final int current;

  @override
  State<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends State<_QuantitySheet> {
  late final _controller = TextEditingController(text: '${widget.current}')
    ..selection = TextSelection(
      baseOffset: 0,
      extentOffset: '${widget.current}'.length,
    );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null) return;
    Navigator.of(context).pop(value.clamp(0, CartController.maxQuantity));
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: BorderSide(color: color, width: width),
        );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Quantità',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            widget.productName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 3,
            textAlign: TextAlign.center,
            onSubmitted: (_) => _confirm(),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
            decoration: InputDecoration(
              counterText: '',
              helperText:
                  'Da 0 a ${CartController.maxQuantity}; 0 toglie il '
                  'prodotto dal carrello.',
              helperStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: palette.textSecondary,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              enabledBorder: border(palette.line),
              focusedBorder: border(AppColors.brand, 2),
              border: border(palette.line),
            ),
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => WideButton(
              label: 'Conferma',
              onPressed: int.tryParse(_controller.text.trim()) == null
                  ? null
                  : _confirm,
            ),
          ),
        ],
      ),
    );
  }
}
