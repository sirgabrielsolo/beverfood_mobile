# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Beverfood mobile: a Flutter e-commerce app for food & beverages (wine, beer, cocktails, coffee, soft drinks, Italian food). All user-facing text is in **Italian**. Data is currently mocked in-memory; there is no backend yet.

**Progress log:** [`docs/progress.md`](docs/progress.md) records what has been built, the decisions made (including design approaches the user rejected, which shouldn't be proposed again) and what's next. Read it before starting work. At the end of a work session, append a dated entry to its Log (what was done, and the decisions and why) and update its "Next up" list. Keep this file (CLAUDE.md) for stack, architecture, conventions and commands only.

## Commands

```bash
flutter pub get                      # install dependencies
flutter analyze                      # lint (flutter_lints, see analysis_options.yaml)
dart format lib test                 # format
flutter test                         # all widget tests
flutter test --plain-name 'dark mode' # single test by (partial) name
flutter run -d <device-id>           # run; `flutter devices` lists ids (e.g. an Android emulator)
```

## Architecture

Code is organised **by functionality**; keep new code in this shape:

- `lib/app/`: app-wide wiring. `app.dart` (MaterialApp.router + theme mode), `router.dart` (go_router), `shell/app_shell.dart` (bottom NavigationBar), `theme/`, `app_assets.dart` (asset path constants).
- `lib/core/`: cross-feature pieces: `network/unsplash.dart` (image URL builder), `formatting/price_format.dart` (Italian euro format), `widgets/` (shared widgets such as `AppNetworkImage`, `EmptyState`).
- `lib/features/<feature>/`: `data/` (repositories), `models/`, `presentation/` (pages + `widgets/`). Features: `home`, `products`, `promotions`, `cart`, `profile`. Features may import each other's models and widgets; e.g. home composes promotions and products widgets.
- Static files go in `assets/images/<purpose>/` (declared per folder in `pubspec.yaml`). Web icons live in `web/`. `assets/images/placeholders/` is intentionally **not** declared yet, because its image is unused.

Add architecture layers (domain, DI, state-management packages) only when they clearly reduce coupling or simplify tests.

### Navigation

`createRouter()` uses `StatefulShellRoute.indexedStack` with one branch per bottom-nav tab (home `/`, products `/products`, cart `/cart`, profile `/profile`), so each tab keeps its state. The products page takes optional query params `q` and `category` (a `ProductCategory.name`). Build these locations with `AppRoutes.productsWith(...)`. Because the tab stays alive, `ProductsPage.didUpdateWidget` applies new filters when navigated to again.

### Data

`ProductRepository` and `PromoRepository` are `const` classes over hard-coded lists, and their public methods are what the UI depends on. Swap the internals for an API later. Images are Unsplash CDN URLs built with `unsplashImage(photoId, width:)`.

### Theming (light + dark)

- Never hard-code theme-dependent colors in widgets. Use `context.palette` (the `AppPalette` ThemeExtension in `app/theme/app_palette.dart`, with `light`/`dark` instances) or `Theme.of(context).colorScheme`. Brand constants that don't change with the theme (accent amber, primary bordeaux and its lighter dark-mode variant) live in `AppColors`.
- Corner radii come from `AppRadii` (card 10, image 8, field 10).
- `ThemeModeController` (ChangeNotifier) persists the mode with `shared_preferences` (key `theme_mode`). `main()` creates it and passes it into `BeverfoodApp`, and it is exposed to the tree via `ThemeModeScope.of(context)`. The profile page has the "follow device" / "dark mode" switches.
- Status bar icon brightness is set from the theme by an `AnnotatedRegion` in `AppShell`. Home and Products use scroll-away `SliverAppBar`s inside `SafeArea(bottom: false)`, so content never scrolls under the status bar.

### Product card sizing

`ProductCard` is a square image plus a one-line name and a price. Its height is exactly `width + ProductCard.textHeight(context)` (text lines are fixed-height and respect text scaling). `ProductSliverGrid` (via `SliverLayoutBuilder`) and `NewArrivalsCarousel` use this to size items. If you change the card's text, update `textHeight` with it, or cells overflow (the widget tests catch even 0.1 px overflows).

## Testing notes

- Tests must build the app with a controller: `SharedPreferences.setMockInitialValues({})`, then `BeverfoodApp(themeModeController: ThemeModeController(prefs))`. See `test/widget_test.dart`.
- In tests, network images fail with HTTP 400. `AppNetworkImage` shows its error placeholder, so this is expected and harmless.
- The test viewport is 800×600. Content below the fold (e.g. "Più popolari") must be scrolled into view with `scrollUntilVisible`.
