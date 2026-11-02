# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Beverfood mobile: a Flutter e-commerce app for food & beverages (wine, beer, cocktails, coffee, soft drinks, Italian food), the client-facing side of the agents' web app **beverfood_web** (`/home/host-arch/projects/beverfood_web`, Flask + Postgres on Render, its own `CLAUDE.md`), whose product database it shares. All user-facing text is in **Italian**. Promos come from that app's read-only API; the other products are still mocked in memory.

**Progress log:** [`docs/progress.md`](docs/progress.md) records what has been built, the decisions made (including design approaches the user rejected, which shouldn't be proposed again) and what's next. Read it before starting work. At the end of a work session, append a dated entry to its Log (what was done, and the decisions and why) and update its "Next up" list. Keep this file (CLAUDE.md) for stack, architecture, conventions and commands only.

## Commands

```bash
flutter pub get                      # install dependencies
flutter analyze                      # lint (flutter_lints, see analysis_options.yaml)
dart format lib test                 # format
flutter test                         # all widget tests
flutter test --plain-name 'dark mode' # single test by (partial) name
flutter run -d <device-id>           # run; `flutter devices` lists ids (e.g. an Android emulator)
# against a local beverfood_web (python app.py, port 5000) instead of production:
flutter run -d <device-id> --dart-define=API_BASE_URL=http://10.0.2.2:5000   # emulator; a phone uses the PC's LAN IP

# Performance (frame build/raster ms scrolling Home and Prodotti, and switching the theme; needs a device or emulator)
flutter drive --profile --no-dds -d <device-id> --driver=test_driver/perf_driver.dart --target=integration_test/scroll_performance_test.dart
```

## Architecture

Code is organised **by functionality**; keep new code in this shape:

- `lib/app/`: app-wide wiring. `app.dart` (MaterialApp.router + theme mode), `router.dart` (go_router), `shell/app_shell.dart` (bottom NavigationBar), `shell/branch_stack.dart` (the tabs' container), `theme/`, `app_assets.dart` (asset path constants).
- `lib/core/`: cross-feature pieces: `network/api_client.dart` (JSON client for beverfood_web's `/api/v1`), `network/unsplash.dart` (image URL builder), `formatting/price_format.dart` (Italian euro format), `widgets/` (shared widgets such as `AppNetworkImage`, `EmptyState`, `SearchField`).
- `lib/features/<feature>/`: `data/` (repositories), `models/`, `presentation/` (pages + `widgets/`). Features: `home`, `products`, `promotions`, `cart`, `profile`. Features may import each other's models and widgets; e.g. home composes promotions and products widgets.
- Static files go in `assets/images/<purpose>/` (declared per folder in `pubspec.yaml`). Fonts go in `assets/fonts/` (Nunito Sans, static TTFs for weights 400–900, family `NunitoSans`, set as the app font in `AppTheme`). Web icons live in `web/`. `assets/images/placeholders/` is intentionally **not** declared yet, because its image is unused.

Add architecture layers (domain, DI, state-management packages) only when they clearly reduce coupling or simplify tests.

### Navigation

`createRouter()` uses a `StatefulShellRoute` with one branch per bottom-nav tab (home `/`, products `/products`, cart `/cart`, profile `/profile`), so each tab keeps its state. Its container is `BranchStack`, which works like `StatefulShellRoute.indexedStack` but keeps the theme of the tabs not on screen frozen until they're opened again (see Theming). The products page takes optional query params `q` and `category` (a `ProductCategory.name`). Build these locations with `AppRoutes.productsWith(...)`. Because the tab stays alive, `ProductsPage.didUpdateWidget` (and `CategoryTabBar.didUpdateWidget` for the selected tab) applies new filters when navigated to again; Home's category tiles use this. Promo pages (`/promo/:id`, `AppRoutes.promo(id)`) are a top-level route outside the shell, so they open full screen over the navigation bar; Home pushes them with the `Promo` as `extra` (without it, `PromoPage` reloads the promos and finds it by id). Home's search bar is a `SearchFieldButton`: it navigates with `context.go(AppRoutes.products, extra: FocusProductSearch())`, and a new `FocusProductSearch` instance focuses Prodotti's search field.

### Data

`ProductRepository` is a `const` class over hard-coded lists, and its public methods are what the UI depends on (`search` also takes a `ProductSort`; `categoryImageUrl` gives the Home tile covers). Swap the internals for the API section by section (Novità, then Più popolari, then the rest). Its images are Unsplash CDN URLs built with `unsplashImage(photoId, size:)`, always square crops, so `AppNetworkImage` can decode them at the size they're drawn (`cacheWidth`, the box's longer side).

**API.** `ApiClient` talks to beverfood_web's `/api/v1` (`api.py` there; full endpoint list and rules in its CLAUDE.md, "Mobile app clients"). Everything but `POST /auth/code` and `/auth/verify` needs `Authorization: Bearer <token>`, including `/promos`; the app has no sign-in yet, so today Home shows "Promozioni non disponibili" against an up-to-date server. Base URL: `--dart-define=API_BASE_URL`, default production `https://beverfood-web.onrender.com`; debug builds allow plain HTTP (`android/app/src/debug/AndroidManifest.xml`). Prices come **net of IVA** with the IVA rate, as the agents see them. `PromoRepository(ApiClient)` loads `GET /api/v1/promos`: the PROMO products (category 99) in banner order, each with banner texts, a `banner_url` and its rule (`groups`: paid/free, `each`/`total` quantities, the products). Banner texts and rules live in beverfood_web's `promos.py`. `BeverfoodApp` owns the repository (optional constructor argument, for tests) and exposes it with `PromoRepositoryScope.of(context)`. Home's `PromoSection` loads it once, with banner-sized placeholders while loading and a "Riprova" row on failure. A promo with a `banner_url` is shown as that image only (`PromoBanner`, 300×124, texts baked in, the Semantics label from the texts); one without falls back to the text `PromoCard`. Tapping a banner opens `PromoPage`: the wide banner (its texts are in the image, so no title is repeated), the price and "Risparmi", then one card per group, fixed products with "× n", freely mixed groups with a counter, progress bar and steppers. `PromoSelection` (immutable) holds the mix, what's missing, the list value and savings, and `orderNote` (the mix in database names, for the order notes the manager reads). A promo goes in the cart **at most once per order** (`CartController.putPromo/removePromo/promoSelection`); the 38 pt bottom bar shows what's missing, "Aggiungi · price", "Nel carrello" with a bin, or "Aggiorna il carrello" after the mix changes. The banner and square promo PNGs are rendered by `beverfood_ops/scripts/promo_banners/render.sh` and uploaded to Cloudinary by hand.

**Prices** are net of IVA everywhere, shown with `NetPriceText` ("12,52 € + IVA", the user's choice). **Product names** from the database are agent-style upper case; `splitProductName` (`core/formatting/product_name.dart`) gives a display name and pack ("Estathè Pesca lattina", "330 ml · 24 pz") until the user decides how names look. Product cut-outs (transparent PNGs) sit on `palette.cutoutBackground`, light in both themes, with `AppNetworkImage(fit: BoxFit.contain)`.

Cart quantities and favourites live in `CartController` (`features/cart/data/`) and `FavouritesController` (`features/products/data/`), both `ChangeNotifier`s, in memory only. `BeverfoodApp` owns them and exposes them with `CartScope.of(context)` / `FavouritesScope.of(context)`, the same pattern as `ThemeModeScope`. `ProductCard` reads both directly, so the same product shows the same state on every screen. `CartBar` (`features/cart/presentation/widgets/`) is the agreed "Vai al carrello" design, not shown anywhere yet.

### Theming (light + dark)

- Never hard-code theme-dependent colors in widgets. Use `context.palette` (the `AppPalette` ThemeExtension in `app/theme/app_palette.dart`, with `light`/`dark` instances) or `Theme.of(context).colorScheme`. Brand constants that don't change with the theme live in `AppColors`: `brand` red `#C8174A` (filled elements such as the card's add bar), `accent` yellow, and their `on*` colors. Brand-colored **text and icons** use `palette.brandText`, which is a lighter pink in dark mode. `colorScheme.primary` is `brand`.
- Home header colors are palette tokens (`header`, `onHeader`, `headerLogoTint`, `headerField`, `onHeaderField`): brand red with a white field in light mode, a dark surface (`#241E21`, field `#362D31`) in dark mode, where the logo keeps its own red (`headerLogoTint` is `null`).
- Corner radii come from `AppRadii` (card 10, image 8, field 10, button 10, badge 4, Home header bottom 10). The user wants these small radii, not the larger ones in design handoffs.
- Read theme colors in a widget's own `build`, not through a `ListView`/`SliverList` item builder's `context`: items built that way don't update when the theme changes (see `_CategoryTile`).
- `ThemeModeController` (ChangeNotifier) persists the mode with `shared_preferences` (key `theme_mode`). `main()` creates it and passes it into `BeverfoodApp`, and it is exposed to the tree via `ThemeModeScope.of(context)`. The profile page has the "follow device" / "dark mode" switches.
- Theme switches are kept to one cheap frame, because they used to stutter on a real device (a 65 ms frame):
  - The theme is applied by a `Theme` in `MaterialApp.router(builder:)`, around the router, not with `themeMode`. Changing `themeMode` rebuilds the MaterialApp, and with it the router and every page. `MaterialApp.theme` is only a fallback.
  - It switches instantly. The 200 ms interpolation rebuilt every theme-dependent widget on each frame.
  - `BranchStack` gives the tabs not on screen the theme they last showed, so a switch from Profilo doesn't rebuild Home's and Prodotti's cards. A tab picks up the new theme when it's opened. It provides its own Cupertino theme, because `Theme` makes a new one each build and `Theme.of` depends on it. The test "a theme switch rebuilds only the tab on screen" covers this.
- Status bar icon brightness is set from the theme by an `AnnotatedRegion` in `AppShell`. Home overrides it to light icons: its `HomeHeader` (red, or dark in dark mode, a pinned `SliverPersistentHeader`) extends behind the status bar, the logo row scrolls away and the search bar stays pinned. Prodotti is inside `SafeArea(bottom: false)`; its title and search scroll away and the `CategoryTabBar` stays pinned.

### Scroll performance

Measured with the performance test above, on the Android emulator (Impeller, OpenGL ES) and on the user's phone (CPH2399, Dimensity 1200, 90 Hz, so an 11 ms budget). The emulator exaggerates raster cost; the phone shows build cost more.
- Don't wrap a sliver in `SliverLayoutBuilder` to size its items: it runs its builder again whenever the sliver constraints change, and those include the scroll offset, so every visible card rebuilt on every scroll frame (Prodotti's build p90 was 8.6 ms on the phone). `ProductSliverGrid` sizes its cells in a `SliverGridDelegate` at layout time instead.
- Don't clip on scrolling content unless needed: rounded `Material`s and buttons shape their ripple with `InkWell(borderRadius:)` instead of `clipBehavior`, and full-width horizontal lists use `clipBehavior: Clip.none`. Only images keep a `ClipRRect`.
- No `TextField` in Home's pinned header: it cost about 10 ms of raster per frame there. That's why Home uses `SearchFieldButton`.
- Fade with color alpha instead of `Opacity` on things that animate while scrolling (it paints an offscreen layer each frame).
- The first scroll of each page is still slower while images download and decode; on the emulator this is the remaining jank. Emulator numbers vary between runs, so compare several runs.

### Product card sizing

`ProductCard` is a `surface` card (padding 8) with a square image (optional "NUOVO" badge, favourite heart), a fixed two-line name, the price line, and a full-width 38 pt red "Aggiungi" bar that turns into a stepper of the same size (bin at quantity 1, then minus; quantity; plus). The label slides up and the stepper slides in; the bar clips only while that animation runs. Its height is exactly `width + ProductCard.textHeight(context)` (the name box is fixed-height and respects text scaling). `ProductSliverGrid` (via its grid delegate) and Home's `ProductRail` use this to size items. If you change the card's layout, update `textHeight` with it, or cells overflow (the widget tests catch even 0.1 px overflows, including a 360 dp / 1.3× text test).

## Testing notes

- Tests must build the app with a controller: `SharedPreferences.setMockInitialValues({})`, then `BeverfoodApp(themeModeController: ThemeModeController(prefs))`, and pass `promoRepository:` one backed by `package:http/testing.dart`'s `MockClient` (`_fakePromos` in `test/widget_test.dart`), so Home's promos don't depend on the network.
- In tests, network images fail with HTTP 400. `AppNetworkImage` shows its error placeholder, so this is expected and harmless.
- The test viewport is 800×600. Content below the fold (e.g. "Più popolari") must be scrolled into view with `scrollUntilVisible`. Card buttons near the bottom sit behind the navigation bar until scrolled, so taps miss them.
- Promo page steppers are labelled "Aggiungi Lilia Naturale" / "Togli Lilia Naturale" (plus " in omaggio" in a free group). They apply +1/−1 to the latest selection, but a "+" disabled by a full group needs a `pump()` after the "−" that frees it.
- Card buttons have semantics labels ("Aggiungi al carrello", "Aggiungi uno", "Rimuovi uno", "Rimuovi dal carrello" for the bin at quantity 1, "Aggiungi ai preferiti"); find them with `find.bySemanticsLabel`.
