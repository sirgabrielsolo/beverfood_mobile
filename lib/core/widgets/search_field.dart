import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';

const _hint = 'Cerca vini, birre, caffè…';
const _textStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);

/// Product search box, used at the top of Prodotti.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
  });

  static const height = 48.0;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      style: _textStyle,
      decoration: const InputDecoration(
        hintText: _hint,
        prefixIcon: Icon(Icons.search_rounded),
        constraints: BoxConstraints.tightFor(height: height),
      ),
    );
  }
}

/// A button that looks like [SearchField], for opening search elsewhere.
///
/// Used in Home's pinned header: a real text field there costs about 10 ms
/// of raster time on every scroll frame (measured with
/// `integration_test/scroll_performance_test.dart`).
class SearchFieldButton extends StatelessWidget {
  const SearchFieldButton({
    super.key,
    required this.onTap,
    this.color,
    this.contentColor,
  });

  final VoidCallback onTap;

  /// Background, `palette.surface` by default.
  final Color? color;

  /// Icon and hint, `palette.textSecondary` by default.
  final Color? contentColor;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final contentColor = this.contentColor ?? palette.textSecondary;

    return Semantics(
      button: true,
      label: _hint,
      excludeSemantics: true,
      child: Material(
        color: color ?? palette.surface,
        borderRadius: AppRadii.field,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.field,
          child: SizedBox(
            height: SearchField.height,
            // Lines up with the icon and hint of a [SearchField].
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  child: Icon(Icons.search_rounded, color: contentColor),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _textStyle.copyWith(color: contentColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
