import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beverfood_mobile/app/app.dart';
import 'package:beverfood_mobile/app/theme/theme_mode_controller.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/core/widgets/app_network_image.dart';
import 'package:beverfood_mobile/features/auth/data/auth_repository.dart';
import 'package:beverfood_mobile/features/auth/data/token_store.dart';
import 'package:beverfood_mobile/features/home/presentation/widgets/category_grid.dart';
import 'package:beverfood_mobile/features/products/presentation/products_page.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_card.dart';

/// Measures frame build and raster times on Home and Prodotti with the real
/// catalogue (~1200 products), and while switching between light and dark.
///
/// Run on a device or emulator, in profile mode:
/// `flutter drive --profile --no-dds -d <device-id> --driver=test_driver/perf_driver.dart --target=integration_test/scroll_performance_test.dart`
///
/// The app talks to the API it was built for (`--dart-define=API_BASE_URL`,
/// production by default). It signs in as the test account (+39 300 000
/// 0000) when given its code, `--dart-define=PERF_SIGN_IN_CODE=…` (Render's
/// APP_TEST_CODE, or the local .env's); otherwise it uses the token saved on
/// the device. Add `--keep-app-running`: without it `flutter drive`
/// uninstalls the app afterwards, and the device's sign-in with it.
///
/// Home and Prodotti are scrolled twice: the first pass includes downloading
/// and decoding photos (unless the disk cache has them), the second scrolls
/// over photos already in memory.
const _signInCode = String.fromEnvironment('PERF_SIGN_IN_CODE');
const _semantics = bool.fromEnvironment('PERF_SEMANTICS');
const _noDiskCache = bool.fromEnvironment('PERF_NO_DISK_CACHE');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Finder pageScrollable([Finder? page]) => find
      .descendant(
        of: page ?? find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      )
      .first;

  Finder inProdotti(Finder finder) =>
      find.descendant(of: find.byType(ProductsPage), matching: finder);

  /// Pumps until [finder] matches: real network requests don't schedule
  /// frames, so `pumpAndSettle` can return before they answer.
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    for (var i = 0; i < 300 && finder.evaluate().isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(finder, findsWidgets, reason: 'Signed in on the device?');
  }

  Future<void> fling(
    WidgetTester tester,
    Finder target,
    List<double> dys,
  ) async {
    for (final dy in dys) {
      await tester.fling(target, Offset(0, dy), 2500);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('scroll performance', (tester) async {
    // As main() does: photos stay on disk.
    if (!_noDiskCache) {
      AppNetworkImage.provider = CachedNetworkImageProvider.new;
    }
    // An explicit mode, so the dark mode switch on Profilo is enabled.
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    final prefs = await SharedPreferences.getInstance();
    final api = ApiClient();
    TokenStore? tokens;
    if (_signInCode.isNotEmpty) {
      final auth = AuthRepository(api);
      final sent = await auth.requestCode(CodeChannel.sms, '300 000 0000');
      final signedIn = await auth.verifyCode(
        CodeChannel.sms,
        sent.destination,
        _signInCode,
      );
      tokens = MemoryTokenStore(signedIn.token);
    }
    await tester.pumpWidget(
      BeverfoodApp(
        themeModeController: ThemeModeController(prefs),
        apiClient: api,
        tokenStore: tokens,
      ),
    );
    await waitFor(tester, find.byType(ProductCard));
    await tester.pumpAndSettle();

    const homePass = [-600.0, -600.0, -600.0, 600.0, 600.0, 600.0];
    await binding.watchPerformance(
      () => fling(tester, pageScrollable(), homePass),
      reportKey: 'home_first',
    );
    await binding.watchPerformance(
      () => fling(tester, pageScrollable(), homePass),
      reportKey: 'home_again',
    );

    // The two rows of categories, sideways and back.
    await tester.scrollUntilVisible(
      find.byType(CategoryGrid),
      300,
      scrollable: pageScrollable(),
    );
    await tester.pumpAndSettle();
    final categories = find
        .descendant(
          of: find.byType(CategoryGrid),
          matching: find.byType(Scrollable),
        )
        .first;
    await binding.watchPerformance(() async {
      for (final dx in [-600.0, -600.0, 600.0, 600.0]) {
        await tester.fling(categories, Offset(dx, 0), 2500);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'home_categories');

    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();
    final products = pageScrollable(find.byType(ProductsPage));

    // Deep into the ~1200 products of Tutti and back.
    const productsPass = [
      -3000.0,
      -3000.0,
      -3000.0,
      -3000.0,
      3000.0,
      3000.0,
      3000.0,
      3000.0,
    ];
    await binding.watchPerformance(
      () => fling(tester, products, productsPass),
      reportKey: 'products_first',
    );
    await binding.watchPerformance(
      () => fling(tester, products, productsPass),
      reportKey: 'products_again',
    );

    // Switching category tabs: each filters and sorts the catalogue.
    await binding.watchPerformance(() async {
      for (final tab in ['Birre', 'Bibite', 'Acqua', 'Tutti']) {
        final finder = inProdotti(find.text(tab));
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }
    }, reportKey: 'products_tabs');

    // Typing a search, a letter at a time, from the top of the page (the
    // field scrolls away with the title).
    tester.state<ScrollableState>(products).position.jumpTo(0);
    await tester.pumpAndSettle();
    final field = inProdotti(find.byType(TextField));
    await binding.watchPerformance(() async {
      for (final text in ['c', 'co', 'coc', 'coca', 'coca ', 'coca l']) {
        await tester.enterText(field, text);
        await tester.pumpAndSettle();
      }
      await tester.enterText(field, '');
      await tester.pumpAndSettle();
    }, reportKey: 'products_search');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();

    // Switches the theme back and forth from Profilo, with Home and Prodotti
    // alive in their tabs.
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    await binding.watchPerformance(() async {
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('Modalità scura'));
        await tester.pumpAndSettle();
      }
    }, reportKey: 'theme_switch');
    // Without the accessibility tree, which testWidgets builds by default
    // but a phone builds only while a service such as TalkBack is on: these
    // are the numbers a client feels. Set it to true to measure with it.
  }, semanticsEnabled: _semantics);
}
