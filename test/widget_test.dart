import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beverfood_mobile/app/app.dart';
import 'package:beverfood_mobile/app/theme/theme_mode_controller.dart';

Future<ThemeModeController> _themeModeController() async {
  SharedPreferences.setMockInitialValues({});
  return ThemeModeController(await SharedPreferences.getInstance());
}

Future<void> _pumpApp(WidgetTester tester, ThemeModeController controller) {
  return tester.pumpWidget(BeverfoodApp(themeModeController: controller));
}

void main() {
  testWidgets('home shows promos, sections and bottom navigation', (
    tester,
  ) async {
    await _pumpApp(tester, await _themeModeController());
    await tester.pumpAndSettle();

    expect(find.text('Settimana del vino'), findsOneWidget);
    expect(find.text('Novità'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    // The popular section is below the fold of the test viewport.
    await tester.scrollUntilVisible(
      find.text('Più popolari'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Più popolari'), findsOneWidget);
    expect(find.text('Tutti'), findsOneWidget);
  });

  testWidgets('searching from home opens the filtered catalogue', (
    tester,
  ) async {
    await _pumpApp(tester, await _themeModeController());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'chianti');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(find.text('Prodotti'), findsWidgets);
    expect(find.text('Chianti Classico DOCG'), findsOneWidget);
    expect(find.text('Rosé Spumante Brut'), findsNothing);
  });

  testWidgets('dark mode can be turned on from the profile page', (
    tester,
  ) async {
    final controller = await _themeModeController();
    await _pumpApp(tester, controller);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    Brightness brightness() =>
        Theme.of(tester.element(find.text('Modalità scura'))).brightness;

    // Follows the device by default (light in tests), so the dark mode
    // switch is disabled until "follow device" is turned off.
    expect(controller.mode, ThemeMode.system);
    expect(brightness(), Brightness.light);

    await tester.tap(find.text('Segui impostazione del dispositivo'));
    await tester.pumpAndSettle();
    expect(controller.mode, ThemeMode.light);

    await tester.tap(find.text('Modalità scura'));
    await tester.pumpAndSettle();
    expect(controller.mode, ThemeMode.dark);
    expect(brightness(), Brightness.dark);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });
}
