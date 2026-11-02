import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beverfood_mobile/app/app.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/theme_mode_controller.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/promotions/data/promo_repository.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_card.dart';

Future<ThemeModeController> _themeModeController() async {
  SharedPreferences.setMockInitialValues({});
  return ThemeModeController(await SharedPreferences.getInstance());
}

Future<void> _pumpApp(
  WidgetTester tester,
  ThemeModeController controller, {
  PromoRepository? promos,
}) {
  return tester.pumpWidget(
    BeverfoodApp(
      themeModeController: controller,
      promoRepository: promos ?? _fakePromos(),
    ),
  );
}

/// A promo picked freely (2 paid + 1 free among two waters), one with fixed
/// products, and one the server has no texts or banner for yet.
const _promosJson = {
  'promos': [
    {
      'id': 92,
      'name': 'PROMO ACQUA LILIA 2 + 1',
      'price': 8.6,
      'iva': 22.0,
      'image_url': 'https://example.com/92.png',
      'title': 'Acqua Lilia',
      'highlight': '2+1',
      'subtitle': 'Naturale o gas',
      'banner_url': 'https://example.com/promo_banner_92.png',
      'groups': [
        {'role': 'paid', 'mode': 'total', 'quantity': 2, 'products': _waters},
        {'role': 'free', 'mode': 'total', 'quantity': 1, 'products': _waters},
      ],
    },
    {
      'id': 95,
      'name': 'PROMO PEPSI 5 + 1',
      'price': 59.55,
      'iva': 22.0,
      'image_url': 'https://example.com/95.png',
      'title': 'Pepsi',
      'highlight': '5+1',
      'subtitle': 'Una Pepsi Zero in omaggio',
      'banner_url': 'https://example.com/promo_banner_95.png',
      'groups': [
        {
          'role': 'paid',
          'mode': 'each',
          'quantity': 5,
          'products': [
            {
              'id': 5171,
              'name': 'PEPSI LAT 330 ML 24 PZ',
              'price': 12.52,
              'iva': 22.0,
              'image_url': 'https://example.com/5171.png',
            },
          ],
        },
      ],
    },
    {
      'id': 97,
      'name': 'PROMO NUOVA',
      'price': 10.0,
      'iva': 22.0,
      'image_url': 'https://example.com/97.png',
      'title': null,
      'highlight': null,
      'subtitle': null,
      'banner_url': null,
      'groups': <Object>[],
    },
  ],
};

const _waters = [
  {
    'id': 5031,
    'name': 'LILIA NATURALE 500 ML 24 PZ',
    'price': 4.3,
    'iva': 22.0,
    'image_url': 'https://example.com/5031.png',
  },
  {
    'id': 5032,
    'name': 'LILIA GAS 500 ML 24 PZ',
    'price': 4.3,
    'iva': 22.0,
    'image_url': 'https://example.com/5032.png',
  },
];

/// Promos served by a fake HTTP client, which fails the first [failures]
/// requests.
PromoRepository _fakePromos({int failures = 0}) {
  var calls = 0;
  final client = MockClient((request) async {
    expect(request.url.path, '/api/v1/promos');
    if (++calls <= failures) return http.Response('', 503);
    return http.Response.bytes(utf8.encode(jsonEncode(_promosJson)), 200);
  });
  return PromoRepository(ApiClient(client: client, baseUrl: 'https://test'));
}

/// The vertical scrollable of the page currently on screen.
Finder _pageScrollable() => find
    .descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  testWidgets('home shows promos, sections and bottom navigation', (
    tester,
  ) async {
    await _pumpApp(tester, await _themeModeController());
    await tester.pumpAndSettle();

    // From the API: an image banner described by its texts, and a text
    // banner for the promo without an image.
    expect(
      find.bySemanticsLabel('Pepsi, 5+1, Una Pepsi Zero in omaggio'),
      findsOneWidget,
    );
    expect(find.text('PROMO NUOVA'), findsOneWidget);
    expect(find.text('Novità'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationDestination), findsNWidgets(4));

    // The categories and popular sections are below the fold of the test
    // viewport.
    await tester.scrollUntilVisible(
      find.text('Categorie'),
      300,
      scrollable: _pageScrollable(),
    );
    expect(find.text('Categorie'), findsOneWidget);
    expect(find.text('Più popolari'), findsOneWidget);
    // The search bar stays pinned while the page scrolls.
    expect(find.bySemanticsLabel('Cerca vini, birre, caffè…'), findsOneWidget);
  });

  testWidgets('promos that fail to load can be retried', (tester) async {
    await _pumpApp(
      tester,
      await _themeModeController(),
      promos: _fakePromos(failures: 1),
    );
    await tester.pumpAndSettle();

    expect(find.text('Promozioni non disponibili'), findsOneWidget);
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();

    expect(find.text('Promozioni non disponibili'), findsNothing);
    expect(
      find.bySemanticsLabel('Pepsi, 5+1, Una Pepsi Zero in omaggio'),
      findsOneWidget,
    );
  });

  testWidgets('a promo is picked on its page and put in the cart once', (
    tester,
  ) async {
    // Tall enough for the whole promo page.
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpApp(tester, await _themeModeController());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Acqua Lilia, 2+1, Naturale o gas'));
    await tester.pumpAndSettle();

    // Full screen, no repeated title: the price, then what's saved
    // (3 × 4,30 of value for 8,60).
    expect(find.text('Promozione'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Risparmi 4,30 €'), findsOneWidget);
    expect(find.text('Scegli ancora 2'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Aggiungi Lilia Naturale'));
    await tester.tap(find.bySemanticsLabel('Aggiungi Lilia Gas'));
    await tester.pump();
    expect(find.text('Scegli ancora 1 in omaggio'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Aggiungi Lilia Gas in omaggio'));
    await tester.pump();

    await tester.tap(find.text('Aggiungi · '));
    await tester.pump();
    expect(find.text('Nel carrello'), findsOneWidget);

    // Changing the mix of the promo in the cart asks to update it.
    await tester.tap(find.bySemanticsLabel('Togli Lilia Gas in omaggio'));
    // "+" was disabled while the free group was full.
    await tester.pump();
    await tester.tap(
      find.bySemanticsLabel('Aggiungi Lilia Naturale in omaggio'),
    );
    await tester.pump();
    expect(find.text('Aggiorna il carrello'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Rimuovi dal carrello'));
    await tester.pump();
    expect(find.text('Aggiungi · '), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('a category tile opens Prodotti on that tab', (tester) async {
    await _pumpApp(tester, await _themeModeController());
    await tester.pumpAndSettle();

    final tile = find.text('Birre');
    await tester.scrollUntilVisible(tile, 300, scrollable: _pageScrollable());
    // Bring the tile out from behind the navigation bar.
    await tester.drag(_pageScrollable(), const Offset(0, -150));
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    expect(find.text('Birra Lager chiara'), findsOneWidget);
    expect(find.text('Chianti Classico DOCG'), findsNothing);

    await tester.tap(find.text('Tutti'));
    await tester.pumpAndSettle();
    expect(find.text("Montepulciano d'Abruzzo DOC"), findsOneWidget);
  });

  testWidgets('the cart quantity is shared between Home and Prodotti', (
    tester,
  ) async {
    await _pumpApp(tester, await _themeModeController());
    await tester.pumpAndSettle();

    // Bring the "Novità" cards' buttons out from behind the navigation bar.
    await tester.drag(_pageScrollable(), const Offset(0, -200));
    await tester.pumpAndSettle();

    // The first "Novità" card.
    await tester.tap(find.bySemanticsLabel('Aggiungi al carrello').first);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Aggiungi uno').first);
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();
    await tester.drag(_pageScrollable(), const Offset(0, -300));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);

    // At quantity 1 the minus becomes a bin, which takes the product out of
    // the cart and brings back the "Aggiungi" button.
    await tester.tap(find.bySemanticsLabel('Rimuovi uno').first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Rimuovi uno'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Rimuovi dal carrello').first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Rimuovi dal carrello'), findsNothing);
    expect(find.text('Aggiungi'), findsWidgets);
  });

  testWidgets('Prodotti can be sorted by price', (tester) async {
    await _pumpApp(tester, await _themeModeController());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filtra e ordina'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prezzo crescente'));
    await tester.pumpAndSettle();

    // The cheapest product comes first.
    expect(find.text('Acqua minerale naturale'), findsOneWidget);
  });

  testWidgets('Home and Prodotti fit a 360 dp screen with large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpApp(tester, await _themeModeController());
    await tester.pumpAndSettle();
    await tester.drag(_pageScrollable(), const Offset(0, -2000));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Aggiungi al carrello').first);
    await tester.pumpAndSettle();
    await tester.drag(_pageScrollable(), const Offset(0, -2000));
    await tester.pumpAndSettle();

    // Layout overflows would have failed the test with an exception.
    expect(tester.takeException(), isNull);
  });

  testWidgets('the home search bar opens Prodotti ready to search', (
    tester,
  ) async {
    await _pumpApp(tester, await _themeModeController());
    await tester.pumpAndSettle();

    // Home has no text field, just a button that looks like one.
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.bySemanticsLabel('Cerca vini, birre, caffè…'));
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    expect(tester.widget<TextField>(field).focusNode!.hasFocus, isTrue);

    await tester.enterText(field, 'chianti');
    await tester.pumpAndSettle();
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

    // Home's header turns from brand red into a dark surface, and keeps the
    // change after the theme switch (it reads the palette in its own build).
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.pumpAndSettle();
    final header = tester.widget<Material>(
      find
          .ancestor(of: find.text('Beverfood'), matching: find.byType(Material))
          .first,
    );
    expect(header.color, const Color(0xFF241E21));
  });

  testWidgets('a theme switch rebuilds only the tab on screen', (tester) async {
    final controller = await _themeModeController();
    await controller.setMode(ThemeMode.light);
    await _pumpApp(tester, controller);
    await tester.pumpAndSettle();

    // Home is alive already; open Prodotti so it's alive too.
    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();

    var cardBuilds = 0;
    debugOnRebuildDirtyWidget = (element, _) {
      if (element.widget is ProductCard) cardBuilds++;
    };
    addTearDown(() => debugOnRebuildDirtyWidget = null);

    await tester.tap(find.text('Modalità scura'));
    await tester.pumpAndSettle();
    expect(controller.mode, ThemeMode.dark);
    // Rebuilding every card of Home and Prodotti made the switch stutter.
    expect(cardBuilds, 0);

    // A tab takes the new theme when it's opened again.
    await tester.tap(find.byIcon(Icons.grid_view_outlined));
    await tester.pumpAndSettle();
    expect(cardBuilds, greaterThan(0));
    final card = find.byType(ProductCard).first;
    final cardMaterial = tester.widget<Material>(
      find.descendant(of: card, matching: find.byType(Material)).first,
    );
    expect(cardMaterial.color, AppPalette.dark.surface);
  });
}
