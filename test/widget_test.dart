import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beverfood_mobile/app/app.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/theme_mode_controller.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/core/widgets/load_error_row.dart';
import 'package:beverfood_mobile/features/auth/data/token_store.dart';
import 'package:beverfood_mobile/features/products/presentation/widgets/product_card.dart';

Future<ThemeModeController> _themeModeController() async {
  SharedPreferences.setMockInitialValues({});
  return ThemeModeController(await SharedPreferences.getInstance());
}

/// Builds the app against [server] (a new one by default), signed in unless
/// [signedIn] is false.
Future<_FakeServer> _pumpApp(
  WidgetTester tester,
  ThemeModeController controller, {
  _FakeServer? server,
  bool signedIn = true,
}) async {
  server ??= _FakeServer();
  await tester.pumpWidget(
    BeverfoodApp(
      themeModeController: controller,
      apiClient: ApiClient(client: server.client, baseUrl: 'https://test'),
      tokenStore: MemoryTokenStore(signedIn ? 'token' : null),
    ),
  );
  return server;
}

/// The client account as `/api/v1/me` returns it.
Map<String, Object?> _accountJson({
  String status = 'approved',
  bool isTest = false,
  bool phoneVerified = true,
}) => {
  'id': 1,
  'status': status,
  'can_order': status == 'approved',
  'is_test': isTest,
  'erp_client_id': status == 'approved' ? 40217 : null,
  'review_note': null,
  'phone': phoneVerified ? '+393334821756' : null,
  'phone_verified': phoneVerified,
  'email': null,
  'email_verified': false,
  'profile_editable': const [
    'registered',
    'pending',
    'rejected',
  ].contains(status),
  'profile': {
    'first_name': status == 'registered' ? null : 'Marco',
    'last_name': status == 'registered' ? null : 'Ferrero',
    'company_name': status == 'registered' ? null : 'Bar Aurora snc',
    'vat_number': status == 'registered' ? null : '01234567897',
  },
  'address': null,
};

/// Two products flagged new, named the way the ERP writes them.
const _newProductsJson = [
  {
    'id': 73284,
    'name': 'GIN NORDES 3 LT',
    'price': 99.99,
    'iva': 22.0,
    'image_url': 'https://example.com/73284.png',
    'is_new': true,
    'category': 'GIN',
  },
  {
    'id': 51725,
    'name': 'PEPSI ZERO GINGERBREAD LATT 330 ML 24 PZ',
    'price': 12.52,
    'iva': 22.0,
    'image_url': 'https://example.com/51725.png',
    'is_new': true,
    'category': 'BIBITE',
  },
];

/// The two most ordered products, as `/products/popular` returns them.
const _popularProductsJson = [
  {
    'id': 6121,
    'name': "BECK'S BT 330 ML 24 PZ",
    'price': 18.42,
    'iva': 22.0,
    'image_url': 'https://example.com/6121.png',
    'is_new': false,
    'category': 'BIRRE',
  },
  {
    'id': 5121,
    'name': 'COCA COLA LAT 330 ML 24 PZ',
    'price': 13.93,
    'iva': 22.0,
    'image_url': 'https://example.com/5121.png',
    'is_new': false,
    'category': 'BIBITE',
  },
];

/// beverfood_web's /api/v1, faked: one account ([account]), the promos (the
/// first [promoFailures] requests fail), the sign-in code `123456`, two
/// comuni and one Torino street. Records the profile sent.
class _FakeServer {
  _FakeServer({
    Map<String, Object?>? account,
    this.promoFailures = 0,
    this.newFailures = 0,
    this.popularFailures = 0,
    List<Map<String, Object?>>? newProducts,
    List<Map<String, Object?>>? popularProducts,
  }) : account = account ?? _accountJson(),
       newProducts = newProducts ?? _newProductsJson,
       popularProducts = popularProducts ?? _popularProductsJson;

  Map<String, Object?> account;
  int promoFailures;
  int newFailures;
  int popularFailures;
  List<Map<String, Object?>> newProducts;
  List<Map<String, Object?>> popularProducts;
  String? popularLimit;
  Map<String, Object?>? sentProfile;

  late final client = MockClient((request) async {
    final path = request.url.path;
    final body = request.body.isEmpty
        ? const <String, Object?>{}
        : jsonDecode(request.body) as Map<String, Object?>;
    final signedIn = request.headers['Authorization'] == 'Bearer token';

    if (path == '/api/v1/auth/code') {
      return _json({
        'destination': '+39${(body['phone'] as String).replaceAll(' ', '')}',
        'channel': body['channel'],
        'expires_in': 600,
        'resend_in': 45,
      });
    }
    if (path == '/api/v1/auth/verify') {
      if (body['code'] != '123456') {
        return _json({
          'error': 'Codice non corretto.',
          'code': 'wrong_code',
          'field': 'code',
        }, 400);
      }
      return _json({'token': 'token', 'client': account});
    }
    if (!signedIn) {
      return _json({'error': 'Accedi di nuovo.', 'code': 'unauthorized'}, 401);
    }
    switch ((request.method, path)) {
      case ('GET', '/api/v1/me'):
        return _json({'client': account});
      case ('GET', '/api/v1/promos'):
        if (promoFailures-- > 0) return http.Response('', 503);
        return _json(_promosJson);
      case ('GET', '/api/v1/products/new'):
        if (newFailures-- > 0) return http.Response('', 503);
        return _json({'products': newProducts});
      case ('GET', '/api/v1/products/popular'):
        popularLimit = request.url.queryParameters['limit'];
        if (popularFailures-- > 0) return http.Response('', 503);
        return _json({'products': popularProducts});
      case ('POST', '/api/v1/auth/logout'):
        return http.Response('', 204);
      case ('DELETE', '/api/v1/me'):
        return account['is_test'] == true
            ? _json({
                'error': "L'account di prova non si può eliminare.",
                'code': 'test_account',
              }, 403)
            : http.Response('', 204);
      case ('GET', '/api/v1/places/comuni'):
        return _json({
          'comuni': [
            {
              'istat': '001156',
              'name': 'Moncalieri',
              'caps': ['10024'],
            },
            {
              'istat': '001272',
              'name': 'Torino',
              'caps': ['10121', '10122', '10123'],
            },
          ],
        });
      case ('GET', '/api/v1/places/streets'):
        return _json({
          'streets': [
            {
              'name': 'Via Roma',
              'caps': ['10121'],
            },
          ],
        });
      case ('PUT', '/api/v1/me/profile'):
        sentProfile = body;
        account = {..._accountJson(status: 'pending')};
        return _json({'client': account});
    }
    return _json({'error': 'Non trovato', 'code': 'not_found'}, 404);
  });

  static http.Response _json(Object body, [int status = 200]) =>
      http.Response.bytes(utf8.encode(jsonEncode(body)), status);
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

/// Scrolls Profilo until [finder] is clear of the navigation bar.
Future<void> _scrollProfileTo(WidgetTester tester, Finder finder) async {
  final list = find
      .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
      .first;
  await tester.scrollUntilVisible(finder, 120, scrollable: list);
  await tester.drag(list, const Offset(0, -120));
  await tester.pumpAndSettle();
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
      server: _FakeServer(promoFailures: 1),
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

  testWidgets('a product shows the same cart quantity on every card', (
    tester,
  ) async {
    // The gin is both new and popular: one card in each Home rail.
    await _pumpApp(
      tester,
      await _themeModeController(),
      server: _FakeServer(
        popularProducts: [_newProductsJson.first, ..._popularProductsJson],
      ),
    );
    await tester.pumpAndSettle();

    // Bring the "Novità" cards' buttons out from behind the navigation bar.
    await tester.drag(_pageScrollable(), const Offset(0, -200));
    await tester.pumpAndSettle();

    // The gin, first in Novità.
    await tester.tap(find.bySemanticsLabel('Aggiungi al carrello').first);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Aggiungi uno').first);
    await tester.pumpAndSettle();

    // Its "Più popolari" card shows the same quantity.
    await tester.scrollUntilVisible(
      find.text('Più popolari'),
      200,
      scrollable: _pageScrollable(),
    );
    await tester.pumpAndSettle();
    expect(find.text('2'), findsNWidgets(2));

    // The minus on the popular card lowers the Novità card too…
    await tester.ensureVisible(find.bySemanticsLabel('Rimuovi uno').last);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Rimuovi uno').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Novità'),
      -200,
      scrollable: _pageScrollable(),
    );
    await tester.drag(_pageScrollable(), const Offset(0, -200));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsNothing);

    // …where, at quantity 1, the minus has become a bin, which takes the
    // product out of the cart and brings back the "Aggiungi" button.
    expect(find.bySemanticsLabel('Rimuovi uno'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Rimuovi dal carrello').first);
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Rimuovi dal carrello'), findsNothing);
    expect(find.textContaining('Vai al carrello'), findsNothing);
  });

  testWidgets('Più popolari come from the database, without promos', (
    tester,
  ) async {
    final server = await _pumpApp(tester, await _themeModeController());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Più popolari'),
      200,
      scrollable: _pageScrollable(),
    );
    await tester.pumpAndSettle();

    expect(find.text("Beck's bottiglia 330 ml · 24 pz"), findsOneWidget);
    expect(find.text('Coca Cola lattina 330 ml · 24 pz'), findsOneWidget);
    // Only the Novità cards carry the badge.
    expect(find.text('NUOVO'), findsNWidgets(2));
    expect(server.popularLimit, '20');
  });

  testWidgets('Più popolari that fail to load can be retried', (tester) async {
    await _pumpApp(
      tester,
      await _themeModeController(),
      server: _FakeServer(popularFailures: 1),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Più popolari non disponibili'),
      200,
      scrollable: _pageScrollable(),
    );

    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.text('Più popolari non disponibili'),
          matching: find.byType(LoadErrorRow),
        ),
        matching: find.text('Riprova'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text("Beck's bottiglia 330 ml · 24 pz"), findsOneWidget);
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
    await _scrollProfileTo(tester, find.text('Modalità scura'));

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
    await _scrollProfileTo(tester, find.text('Modalità scura'));

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

  testWidgets('signed out, the app signs in with a code sent to the phone', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      await _themeModeController(),
      server: _FakeServer(account: _accountJson(status: 'registered')),
      signedIn: false,
    );
    await tester.pumpAndSettle();

    // Nothing but the welcome screen without an account.
    expect(find.text('Benvenuto su Beverfood'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Continua con il telefono'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '333 482 1756');
    await tester.pump();
    await tester.tap(find.text('Ricevi il codice'));
    await tester.pumpAndSettle();

    expect(find.text('Inserisci il codice'), findsOneWidget);
    expect(find.textContaining('+39 333 482 1756'), findsOneWidget);
    // Six digits verify by themselves.
    await tester.enterText(find.byType(TextField), '000000');
    await tester.pumpAndSettle();
    expect(find.text('Codice non corretto.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();

    // Signed up: Home, with the red notice until the profile is sent.
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Completa il profilo per ordinare'), findsOneWidget);
  });

  testWidgets('the profile is completed in three steps and sent for approval', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final server = await _pumpApp(
      tester,
      await _themeModeController(),
      server: _FakeServer(account: _accountJson(status: 'registered')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Completa ora'));
    await tester.pumpAndSettle();

    // 1 · Chi sei: the phone used to sign up is already verified.
    expect(find.text('Verificato'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'Marco');
    await tester.enterText(find.byType(TextField).at(1), 'Ferrero');
    await tester.pump();
    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();

    // 2 · Azienda: a wrong check digit is caught before sending.
    await tester.enterText(find.byType(TextField).at(0), 'Bar Aurora snc');
    await tester.enterText(find.byType(TextField).at(1), '01234567890');
    await tester.pump();
    await tester.tap(find.text('Avanti'));
    await tester.pump();
    expect(
      find.text('Controlla la Partita IVA: una cifra non torna.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).at(1), '01234567897');
    await tester.pump();
    await tester.tap(find.text('Avanti'));
    await tester.pumpAndSettle();

    // 3 · Consegna: comune from the list, street searched, CAP filled in.
    await tester.tap(find.text('Scegli il comune'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'tor');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Torino'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'roma');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Via Roma'));
    await tester.pumpAndSettle();
    expect(find.text('10121'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(1), '1');
    await tester.pump();
    await tester.tap(find.text("Invia per l'approvazione"));
    await tester.pumpAndSettle();

    expect(server.sentProfile, {
      'first_name': 'Marco',
      'last_name': 'Ferrero',
      'company_name': 'Bar Aurora snc',
      'vat_number': '01234567897',
      'address': {
        'comune_istat': '001272',
        'street': 'Via Roma',
        'street_unlisted': false,
        'civic': '1',
        'cap': '10121',
        'notes': null,
      },
    });
    // Back on Home: now waiting for Beverfood.
    expect(find.text('Profilo in verifica'), findsOneWidget);
  });

  testWidgets(
    'a pending account sees why it cannot order, on Home and in the cart',
    (tester) async {
      await _pumpApp(
        tester,
        await _themeModeController(),
        server: _FakeServer(account: _accountJson(status: 'pending')),
      );
      await tester.pumpAndSettle();

      const why = 'Potrai inviare ordini una volta verificati i tuoi dati.';
      expect(find.text(why), findsOneWidget);
      await tester.tap(find.byIcon(Icons.shopping_cart_outlined).last);
      await tester.pumpAndSettle();
      expect(find.text(why), findsOneWidget);
    },
  );

  testWidgets('the test account cannot be deleted; Esci signs out', (
    tester,
  ) async {
    await _pumpApp(
      tester,
      await _themeModeController(),
      server: _FakeServer(account: _accountJson(isTest: true)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Completa il profilo'), findsNothing);

    await tester.tap(find.byIcon(Icons.person_outline_rounded));
    await tester.pumpAndSettle();
    expect(find.text('ACCOUNT DI PROVA'), findsNothing);
    expect(find.text('APPROVATO'), findsOneWidget);
    expect(find.textContaining('Cliente 40217'), findsOneWidget);

    await _scrollProfileTo(tester, find.text('Elimina account'));
    await tester.tap(find.text('Elimina account'));
    await tester.pumpAndSettle();
    // Disabled: no confirmation opens.
    expect(find.text("Eliminare l'account?"), findsNothing);

    await tester.tap(find.text('Esci'));
    await tester.pumpAndSettle();
    expect(find.text('Benvenuto su Beverfood'), findsOneWidget);
  });

  testWidgets('a quantity in a promo is picked by tapping its number', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pumpApp(tester, await _themeModeController());
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Acqua Lilia, 2+1, Naturale o gas'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.bySemanticsLabel('Quantità Lilia Naturale: 0. Tocca per scegliere'),
    );
    await tester.pumpAndSettle();
    // A wheel with every quantity the paid group has room for: 0, 1, 2.
    expect(find.text('Puoi sceglierne fino a 2.'), findsOneWidget);
    await tester.drag(find.byType(CupertinoPicker), const Offset(0, -88));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Conferma'));
    await tester.pumpAndSettle();

    // Both paid packs chosen in one tap; the free one is next.
    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('Scegli ancora 1 in omaggio'), findsOneWidget);
  });

  testWidgets('Novità come from the database, with readable names', (
    tester,
  ) async {
    await _pumpApp(tester, await _themeModeController());
    await tester.pumpAndSettle();

    expect(find.text('Novità'), findsOneWidget);
    expect(find.text('Gin Nordes 3 l'), findsOneWidget);
    expect(
      find.text('Pepsi Zero Gingerbread lattina 330 ml · 24 pz'),
      findsOneWidget,
    );
    expect(find.text('NUOVO'), findsNWidgets(2));
  });

  testWidgets('Novità that fail to load can be retried', (tester) async {
    await _pumpApp(
      tester,
      await _themeModeController(),
      server: _FakeServer(newFailures: 1),
    );
    await tester.pumpAndSettle();

    expect(find.text('Novità non disponibili'), findsOneWidget);
    await tester.tap(find.text('Riprova'));
    await tester.pumpAndSettle();
    expect(find.text('Gin Nordes 3 l'), findsOneWidget);
  });

  testWidgets(
    'the cart bar appears with the first product and opens the cart',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pumpApp(tester, await _themeModeController());
      await tester.pumpAndSettle();
      expect(find.textContaining('Vai al carrello'), findsNothing);

      // The gin, first in Novità.
      await tester.tap(find.bySemanticsLabel('Aggiungi al carrello').first);
      await tester.pumpAndSettle();
      const bar = 'Vai al carrello, 1 articolo, totale 99,99 € più IVA';
      expect(find.bySemanticsLabel(bar), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(bar));
      await tester.pumpAndSettle();
      // On the cart tab the bar steps aside.
      expect(find.text('Carrello'), findsWidgets);
      expect(find.bySemanticsLabel(bar), findsNothing);
    },
  );
}
