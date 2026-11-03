import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_theme.dart';
import 'package:beverfood_mobile/app/theme/theme_mode_controller.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/auth/data/auth_controller.dart';
import 'package:beverfood_mobile/features/auth/data/auth_repository.dart';
import 'package:beverfood_mobile/features/auth/data/token_store.dart';
import 'package:beverfood_mobile/features/cart/data/cart_controller.dart';
import 'package:beverfood_mobile/features/cart/data/cart_storage.dart';
import 'package:beverfood_mobile/features/orders/data/order_repository.dart';
import 'package:beverfood_mobile/features/products/data/catalog_repository.dart';
import 'package:beverfood_mobile/features/products/data/favourites_controller.dart';
import 'package:beverfood_mobile/features/products/models/catalog.dart';
import 'package:beverfood_mobile/features/promotions/data/promo_repository.dart';

class BeverfoodApp extends StatefulWidget {
  const BeverfoodApp({
    super.key,
    required this.themeModeController,
    this.apiClient,
    this.tokenStore,
    this.cartStorage,
  });

  final ThemeModeController themeModeController;

  /// Defaults to the production API (see [ApiClient]); tests pass one with a
  /// fake HTTP client.
  final ApiClient? apiClient;

  /// Defaults to the device's secure storage; tests keep the token in memory.
  final TokenStore? tokenStore;

  /// Where the cart is kept between launches; defaults to shared preferences.
  final CartStorage? cartStorage;

  @override
  State<BeverfoodApp> createState() => _BeverfoodAppState();
}

class _BeverfoodAppState extends State<BeverfoodApp>
    with WidgetsBindingObserver {
  // Owned by the widget so each app instance (e.g. in tests) gets fresh
  // navigation, account, cart and favourites state.
  late final ApiClient _api = widget.apiClient ?? ApiClient();
  late final AuthController _auth = AuthController(
    api: _api,
    repository: AuthRepository(_api),
    tokenStore: widget.tokenStore ?? const SecureTokenStore(),
  );
  late final GoRouter _router = createRouter(_auth);
  late final _cart = CartController(
    storage: widget.cartStorage ?? const PreferencesCartStorage(),
  )..promoLoader = _promos.getActivePromos;
  final _favourites = FavouritesController();
  late final _promos = PromoRepository(_api);
  late final _catalog = CatalogController(CatalogRepository(_api));
  late final _orders = OrderRepository(_api);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _auth.addListener(_onAuthChanged);
    _catalog.addListener(_onCatalogChanged);
    _auth.start();
    // The cart saved at the last launch; brought up to date once the
    // catalogue is here.
    _cart.restore().then((_) => _syncCart(_catalog.catalog));
  }

  Catalog? _syncedCatalog;

  void _onCatalogChanged() {
    final catalog = _catalog.catalog;
    if (catalog != null && catalog != _syncedCatalog) _syncCart(catalog);
  }

  /// Current prices for the cart, and its products and promos no longer sold.
  void _syncCart(Catalog? catalog) {
    if (catalog == null) return;
    _syncedCatalog = catalog;
    _cart.syncCatalog(catalog);
    _cart.reloadPromos();
  }

  void _onAuthChanged() {
    switch (_auth.status) {
      case AuthStatus.signedIn:
        // Every catalogue request needs the token: loaded once signed in.
        if (_catalog.catalog == null) _catalog.load();
      case AuthStatus.signedOut:
        // Another account may sign in next: it starts with an empty cart.
        _cart.clear();
        _catalog.clear();
        _syncedCatalog = null;
      case AuthStatus.loading || AuthStatus.offline:
        break;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back in the foreground: pick up an approval (or a suspension).
    if (state == AppLifecycleState.resumed &&
        _auth.status == AuthStatus.signedIn) {
      _auth.refresh();
      _catalog.refreshIfStale();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth.removeListener(_onAuthChanged);
    _catalog.removeListener(_onCatalogChanged);
    _auth.dispose();
    _router.dispose();
    _cart.dispose();
    _favourites.dispose();
    _catalog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeModeScope(
      controller: widget.themeModeController,
      child: AuthScope(
        controller: _auth,
        child: CartScope(
          controller: _cart,
          child: FavouritesScope(
            controller: _favourites,
            child: PromoRepositoryScope(
              repository: _promos,
              child: OrderRepositoryScope(
                repository: _orders,
                child: CatalogScope(
                  controller: _catalog,
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
