import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beverfood_mobile/app/app.dart';
import 'package:beverfood_mobile/app/theme/theme_mode_controller.dart';

/// Measures frame build and raster times while scrolling Home and Prodotti,
/// and while switching between light and dark mode.
///
/// Run on a device or emulator, in profile mode:
/// `flutter drive --profile -d <device-id> --driver=test_driver/perf_driver.dart --target=integration_test/scroll_performance_test.dart`
///
/// Each page is measured twice: the first pass includes downloading and
/// decoding the images, the second scrolls over images already in memory.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  Finder pageScrollable() => find
      .descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      )
      .first;

  Future<void> scrollDownAndUp(WidgetTester tester) async {
    for (final dy in [-600.0, -600.0, -600.0, 600.0, 600.0, 600.0]) {
      await tester.fling(pageScrollable(), Offset(0, dy), 2500);
      await tester.pumpAndSettle();
    }
  }

  testWidgets('scroll performance', (tester) async {
    // An explicit mode, so the dark mode switch on Profilo is enabled.
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      BeverfoodApp(themeModeController: ThemeModeController(prefs)),
    );
    await tester.pumpAndSettle();

    await binding.watchPerformance(
      () => scrollDownAndUp(tester),
      reportKey: 'home_first',
    );
    await binding.watchPerformance(
      () => scrollDownAndUp(tester),
      reportKey: 'home_again',
    );

    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();

    await binding.watchPerformance(
      () => scrollDownAndUp(tester),
      reportKey: 'products_first',
    );
    await binding.watchPerformance(
      () => scrollDownAndUp(tester),
      reportKey: 'products_again',
    );

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
  });
}
