import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';

abstract final class AppTheme {
  static final light = _build(
    brightness: Brightness.light,
    palette: AppPalette.light,
    primary: AppColors.primary,
  );

  static final dark = _build(
    brightness: Brightness.dark,
    palette: AppPalette.dark,
    primary: AppColors.primaryOnDark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppPalette palette,
    required Color primary,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: primary,
      onPrimary: Colors.white,
      surface: palette.background,
      onSurface: palette.textPrimary,
      onSurfaceVariant: palette.textSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: palette.background,
      extensions: [palette],
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: palette.textPrimary,
          fontSize: 26,
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surface,
        hintStyle: TextStyle(color: palette.textSecondary),
        prefixIconColor: palette.textSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        border: const OutlineInputBorder(
          borderRadius: AppRadii.field,
          borderSide: BorderSide.none,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.navigationBar,
        elevation: 0,
        indicatorColor: primary.withValues(alpha: 0.15),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? primary
                : palette.textSecondary,
          ),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(color: primary, fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
      // White thumb on a brand-colored track, without an outline.
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary
              : palette.textSecondary.withValues(alpha: 0.5),
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dividerTheme: DividerThemeData(
        color: palette.textSecondary.withValues(alpha: 0.2),
        space: 1,
        thickness: 1,
      ),
    );
  }
}
