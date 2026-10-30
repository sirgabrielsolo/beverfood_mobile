import 'package:flutter/material.dart';

/// Theme-dependent colors not covered by [ColorScheme] roles.
///
/// Read it with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.navigationBar,
    required this.imagePlaceholder,
    required this.textPrimary,
    required this.textSecondary,
    required this.chip,
    required this.onChip,
  });

  static const light = AppPalette(
    background: Color(0xFFF7F7F8),
    surface: Colors.white,
    navigationBar: Colors.white,
    imagePlaceholder: Color(0xFFECECEF),
    textPrimary: Color(0xFF1F1F24),
    textSecondary: Color(0xFF8E8E93),
    chip: Color(0xFF2B2D33),
    onChip: Colors.white,
  );

  static const dark = AppPalette(
    background: Color(0xFF121212),
    surface: Color(0xFF262626),
    navigationBar: Color(0xFF1C1C1C),
    imagePlaceholder: Color(0xFF2C2C2C),
    textPrimary: Color(0xFFF2F2F2),
    textSecondary: Color(0xFF9E9E9E),
    chip: Color(0xFF2E2E2E),
    onChip: Color(0xFFF2F2F2),
  );

  /// Page background.
  final Color background;

  /// Raised elements on the background: search fields, settings cards.
  final Color surface;

  final Color navigationBar;
  final Color imagePlaceholder;
  final Color textPrimary;
  final Color textSecondary;

  /// Unselected filter chip.
  final Color chip;
  final Color onChip;

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? navigationBar,
    Color? imagePlaceholder,
    Color? textPrimary,
    Color? textSecondary,
    Color? chip,
    Color? onChip,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      navigationBar: navigationBar ?? this.navigationBar,
      imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      chip: chip ?? this.chip,
      onChip: onChip ?? this.onChip,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      navigationBar: Color.lerp(navigationBar, other.navigationBar, t)!,
      imagePlaceholder: Color.lerp(
        imagePlaceholder,
        other.imagePlaceholder,
        t,
      )!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      chip: Color.lerp(chip, other.chip, t)!,
      onChip: Color.lerp(onChip, other.onChip, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
