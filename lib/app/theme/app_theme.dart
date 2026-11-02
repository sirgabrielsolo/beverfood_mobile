import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';

abstract final class AppTheme {
  /// Bundled under `assets/fonts/`, declared in `pubspec.yaml`.
  static const fontFamily = 'NunitoSans';

  static final light = _build(
    brightness: Brightness.light,
    palette: AppPalette.light,
  );

  static final dark = _build(
    brightness: Brightness.dark,
    palette: AppPalette.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppPalette palette,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      primary: AppColors.brand,
      onPrimary: AppColors.onBrand,
      secondary: AppColors.accent,
      onSecondary: AppColors.onAccent,
      surface: palette.background,
      onSurface: palette.textPrimary,
      onSurfaceVariant: palette.textSecondary,
      outlineVariant: palette.line,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: palette.background,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: palette.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w900,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        hintStyle: TextStyle(
          color: palette.textSecondary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        prefixIconColor: palette.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.navIndicator,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? palette.brandText
                : palette.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? palette.brandText : palette.textSecondary,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
      ),
      // White thumb on a brand-colored track, without an outline.
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brand
              : palette.textSecondary.withValues(alpha: 0.5),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(
        color: palette.line,
        space: 1,
        thickness: 1,
      ),
    );
  }
}
