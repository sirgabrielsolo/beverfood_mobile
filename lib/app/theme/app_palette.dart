import 'package:flutter/material.dart';

/// Theme-dependent colors not covered by [ColorScheme] roles.
///
/// Read it with `context.palette`.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.imagePlaceholder,
    required this.cutoutBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.line,
    required this.brandText,
    required this.promoAlt,
    required this.navIndicator,
    required this.favBackground,
    required this.favForeground,
    required this.header,
    required this.onHeader,
    required this.headerLogoTint,
    required this.headerField,
    required this.onHeaderField,
  });

  static const light = AppPalette(
    background: Color(0xFFF4F2F1),
    surface: Colors.white,
    imagePlaceholder: Color(0xFFF4F2F1),
    cutoutBackground: Color(0xFFF4F2F1),
    textPrimary: Color(0xFF1A1718),
    textSecondary: Color(0xFF6A6266),
    line: Color(0xFFE8E3E1),
    brandText: Color(0xFFC8174A),
    promoAlt: Color(0xFF1A1718),
    navIndicator: Color(0xFFFCE4EB),
    favBackground: Color(0xEBFFFFFF),
    favForeground: Color(0xFF1A1718),
    header: Color(0xFFC8174A),
    onHeader: Colors.white,
    headerLogoTint: Colors.white,
    headerField: Colors.white,
    onHeaderField: Color(0xFF6A6266),
  );

  static const dark = AppPalette(
    background: Color(0xFF121011),
    surface: Color(0xFF1F1B1D),
    imagePlaceholder: Color(0xFF121011),
    cutoutBackground: Color(0xFFE6E1E2),
    textPrimary: Color(0xFFF7F2F3),
    textSecondary: Color(0xFFABA1A5),
    line: Color(0xFF2D282A),
    brandText: Color(0xFFFF7A9C),
    promoAlt: Color(0xFF2E2A2C),
    navIndicator: Color(0xFF4A1A2A),
    favBackground: Color(0xB8121011),
    favForeground: Color(0xFFF7F2F3),
    header: Color(0xFF241E21),
    onHeader: Color(0xFFF7F2F3),
    headerLogoTint: null,
    headerField: Color(0xFF362D31),
    onHeaderField: Color(0xFFABA1A5),
  );

  /// Page background.
  final Color background;

  /// Raised elements on the background: cards, search fields, navigation bar.
  final Color surface;

  final Color imagePlaceholder;

  /// Behind product cut-outs (transparent PNGs from Cloudinary). Light in
  /// both themes: dark bottles would disappear on a dark surface.
  final Color cutoutBackground;
  final Color textPrimary;

  /// Secondary text, inactive icons and tabs, search hint.
  final Color textSecondary;

  /// Dividers and borders.
  final Color line;

  /// Brand color for text and icons on surfaces ("Vedi tutti", active tab).
  /// Filled brand elements use `AppColors.brand` instead.
  final Color brandText;

  /// Background of the secondary promo cards.
  final Color promoAlt;

  /// Pill behind the active navigation bar icon.
  final Color navIndicator;

  /// Circle behind the favourite heart on product images, and the heart's
  /// outline when the product isn't a favourite.
  final Color favBackground;
  final Color favForeground;

  /// Home header background: brand red in light mode, a raised dark surface
  /// in dark mode (the user's choice, so the header doesn't glare at night).
  final Color header;

  /// The "Beverfood" name on the header.
  final Color onHeader;

  /// Color the logo is tinted with on the header. The logo is a red square
  /// with cut-out lettering: tinted white on the red header, so the lettering
  /// shows the red; `null` (its own red) on the dark header.
  final Color? headerLogoTint;

  /// Search bar on the header, and its icon and hint.
  final Color headerField;
  final Color onHeaderField;

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? imagePlaceholder,
    Color? cutoutBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? line,
    Color? brandText,
    Color? promoAlt,
    Color? navIndicator,
    Color? favBackground,
    Color? favForeground,
    Color? header,
    Color? onHeader,
    Color? headerLogoTint,
    Color? headerField,
    Color? onHeaderField,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
      cutoutBackground: cutoutBackground ?? this.cutoutBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      line: line ?? this.line,
      brandText: brandText ?? this.brandText,
      promoAlt: promoAlt ?? this.promoAlt,
      navIndicator: navIndicator ?? this.navIndicator,
      favBackground: favBackground ?? this.favBackground,
      favForeground: favForeground ?? this.favForeground,
      header: header ?? this.header,
      onHeader: onHeader ?? this.onHeader,
      headerLogoTint: headerLogoTint ?? this.headerLogoTint,
      headerField: headerField ?? this.headerField,
      onHeaderField: onHeaderField ?? this.onHeaderField,
    );
  }

  @override
  AppPalette lerp(AppPalette? other, double t) {
    if (other == null) return this;
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      imagePlaceholder: Color.lerp(
        imagePlaceholder,
        other.imagePlaceholder,
        t,
      )!,
      cutoutBackground: Color.lerp(
        cutoutBackground,
        other.cutoutBackground,
        t,
      )!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      line: Color.lerp(line, other.line, t)!,
      brandText: Color.lerp(brandText, other.brandText, t)!,
      promoAlt: Color.lerp(promoAlt, other.promoAlt, t)!,
      navIndicator: Color.lerp(navIndicator, other.navIndicator, t)!,
      favBackground: Color.lerp(favBackground, other.favBackground, t)!,
      favForeground: Color.lerp(favForeground, other.favForeground, t)!,
      header: Color.lerp(header, other.header, t)!,
      onHeader: Color.lerp(onHeader, other.onHeader, t)!,
      // A tint can't be lerped to "no tint"; switch halfway.
      headerLogoTint: t < 0.5 ? headerLogoTint : other.headerLogoTint,
      headerField: Color.lerp(headerField, other.headerField, t)!,
      onHeaderField: Color.lerp(onHeaderField, other.onHeaderField, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
