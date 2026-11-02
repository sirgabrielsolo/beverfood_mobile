import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';

/// A full-width 46 pt button for the sign-in and profile screens: brand red,
/// or outlined when not [primary]. Disabled while [onPressed] is null; shows
/// a spinner while [busy].
class WideButton extends StatelessWidget {
  const WideButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.primary = true,
    this.busy = false,
    this.destructive = false,
  });

  static const height = 46.0;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool primary;
  final bool busy;

  /// Outlined, with brand-red text (e.g. "Elimina account").
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final enabled = onPressed != null && !busy;
    final filled = primary && !destructive;

    final Color background;
    final Color foreground;
    if (filled) {
      background = enabled || busy ? AppColors.brand : palette.line;
      foreground = enabled || busy ? AppColors.onBrand : palette.textSecondary;
    } else {
      background = palette.surface;
      foreground = destructive ? palette.brandText : palette.textPrimary;
    }

    return Opacity(
      opacity: !filled && !enabled && !busy ? 0.5 : 1,
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.button,
          side: filled
              ? BorderSide.none
              : BorderSide(color: palette.line, width: 1.5),
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: AppRadii.button,
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: Center(
              child: busy
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: foreground,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: 20, color: foreground),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                            ),
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

/// A labelled, bordered text field for forms, with its error underneath.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.error,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.prefixText,
    this.suffix,
    this.autofocus = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.maxLength,
    this.focusNode,
  });

  final String label;
  final TextEditingController controller;
  final String? hint;
  final String? error;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextCapitalization textCapitalization;
  final String? prefixText;
  final Widget? suffix;
  final bool autofocus;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    OutlineInputBorder border(Color color, [double width = 1.5]) =>
        OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: palette.textSecondary,
            ),
          ),
        ),
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          autofocus: autofocus,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          inputFormatters: inputFormatters,
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            prefixText: prefixText,
            prefixStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: palette.textPrimary,
            ),
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 13,
            ),
            enabledBorder: border(
              error == null ? palette.line : AppColors.brand,
            ),
            focusedBorder: border(AppColors.brand, 2),
            disabledBorder: border(palette.line),
            border: border(palette.line),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 6),
            child: Text(
              error!,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: palette.brandText,
              ),
            ),
          ),
      ],
    );
  }
}

/// Small green "Verificato" chip, e.g. beside a verified phone.
class VerifiedChip extends StatelessWidget {
  const VerifiedChip({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: palette.success,
        borderRadius: AppRadii.badge,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Verificato',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                color: palette.onSuccess,
              ),
            ),
            const SizedBox(width: 3),
            Icon(Icons.check_rounded, size: 13, color: palette.onSuccess),
          ],
        ),
      ),
    );
  }
}

/// Error line in brand text color, for messages not tied to one field.
class FormError extends StatelessWidget {
  const FormError(this.message, {super.key});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Text(
      message!,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: context.palette.brandText,
      ),
    );
  }
}

/// A labelled value that can't be edited here (e.g. a verified phone), drawn
/// like a [LabeledField].
class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField({
    super.key,
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: palette.textSecondary,
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: palette.surface,
            borderRadius: AppRadii.field,
            border: Border.all(color: palette.line, width: 1.5),
          ),
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
