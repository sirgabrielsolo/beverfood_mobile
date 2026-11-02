import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_theme.dart';
import 'package:beverfood_mobile/app/theme/theme_mode_controller.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/cart/data/cart_controller.dart';
import 'package:beverfood_mobile/features/products/data/favourites_controller.dart';
import 'package:beverfood_mobile/features/promotions/data/promo_repository.dart';

class BeverfoodApp extends StatefulWidget {
  const BeverfoodApp({
    super.key,
    required this.themeModeController,
    this.promoRepository,
  });

  final ThemeModeController themeModeController;

  /// Defaults to the production API (see [ApiClient]); tests pass a fake.
  final PromoRepository? promoRepository;

  @override
  State<BeverfoodApp> createState() => _BeverfoodAppState();
}

class _BeverfoodAppState extends State<BeverfoodApp> {
  // Owned by the widget so each app instance (e.g. in tests) gets fresh
  // navigation, cart and favourites state.
  late final GoRouter _router = createRouter();
  final _cart = CartController();
  final _favourites = FavouritesController();
  late final _promos = widget.promoRepository ?? PromoRepository(ApiClient());

  @override
  void dispose() {
    _router.dispose();
    _cart.dispose();
    _favourites.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeModeScope(
      controller: widget.themeModeController,
      child: CartScope(
        controller: _cart,
        child: FavouritesScope(
          controller: _favourites,
          child: PromoRepositoryScope(
            repository: _promos,
            child: MaterialApp.router(
              title: 'Beverfood',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              routerConfig: _router,
              // The theme is applied here, around the router, rather than with
              // `themeMode`: changing that rebuilds the MaterialApp and with it
              // the router and every page. Here the router is the same child,
              // so only the widgets that read the theme rebuild. It also
              // switches instantly; the default 200 ms interpolation rebuilds
              // them on every frame, which janks on a real device.
              builder: (context, router) => ListenableBuilder(
                listenable: widget.themeModeController,
                child: router,
                builder: (context, router) => Theme(
                  data: _isDark(context) ? AppTheme.dark : AppTheme.light,
                  child: router!,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isDark(BuildContext context) {
    return switch (widget.themeModeController.mode) {
      ThemeMode.system =>
        MediaQuery.platformBrightnessOf(context) == Brightness.dark,
      ThemeMode.light => false,
      ThemeMode.dark => true,
    };
  }
}
