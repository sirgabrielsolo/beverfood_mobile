import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';

/// The 6-digit code as one wide field with spaced digits (B2). Calls
/// [onCompleted] as soon as six digits are in; the phone's keyboard offers
/// the code from the SMS.
class CodeInput extends StatelessWidget {
  const CodeInput({
    super.key,
    required this.controller,
    required this.onCompleted,
    this.error,
    this.enabled = true,
  });

  static const length = 6;

  final TextEditingController controller;
  final ValueChanged<String> onCompleted;
  final String? error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: AppRadii.field,
      borderSide: BorderSide(color: color, width: width),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: controller,
          enabled: enabled,
          autofocus: true,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(length),
          ],
          onChanged: (value) {
            if (value.length == length) onCompleted(value);
          },
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 12,
            color: palette.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          decoration: InputDecoration(
            semanticCounterText: '',
            counterText: '',
            hintText: '······',
            hintStyle: TextStyle(
              fontSize: 28,
              letterSpacing: 12,
              color: palette.line,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            enabledBorder: border(
              error == null ? palette.line : AppColors.brand,
              1.5,
            ),
            focusedBorder: border(AppColors.brand, 2),
            disabledBorder: border(palette.line, 1.5),
          ),
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 8),
            child: Text(
              error!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: palette.brandText,
              ),
            ),
          ),
      ],
    );
  }
}
