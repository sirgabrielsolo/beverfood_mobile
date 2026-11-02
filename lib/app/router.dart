import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/shell/app_shell.dart';
import 'package:beverfood_mobile/app/shell/branch_stack.dart';
import 'package:beverfood_mobile/features/auth/data/auth_controller.dart';
import 'package:beverfood_mobile/features/auth/data/auth_repository.dart';
import 'package:beverfood_mobile/features/auth/presentation/address_page.dart';
import 'package:beverfood_mobile/features/auth/presentation/code_page.dart';
import 'package:beverfood_mobile/features/auth/presentation/complete_profile_page.dart';
import 'package:beverfood_mobile/features/auth/presentation/contact_entry_page.dart';
import 'package:beverfood_mobile/features/auth/presentation/splash_page.dart';
import 'package:beverfood_mobile/features/auth/presentation/welcome_page.dart';
import 'package:beverfood_mobile/features/cart/presentation/cart_page.dart';
import 'package:beverfood_mobile/features/home/presentation/home_page.dart';
import 'package:beverfood_mobile/features/products/models/product_sort.dart';
import 'package:beverfood_mobile/features/products/presentation/products_page.dart';
import 'package:beverfood_mobile/features/profile/presentation/profile_page.dart';
import 'package:beverfood_mobile/features/promotions/models/promo.dart';
import 'package:beverfood_mobile/features/promotions/presentation/promo_page.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const products = '/products';
  static const cart = '/cart';
  static const profile = '/profile';

  // Signed out: only these (and the start screen) can be shown.
  static const splash = '/splash';
  static const welcome = '/welcome';
  static const loginPhone = '/login/phone';
  static const loginEmail = '/login/email';
  static const loginCode = '/login/code';

  /// Profile completion (C2), and the address alone after approval.
  static const completeProfile = '/account/complete';
  static const editAddress = '/account/address';

  /// An email added to the account from Profilo, verified with a code.
  static const addEmail = '/account/email';

  /// The code screen for a code just sent.
  static String loginCodeFor(CodeSent sent) => Uri(
    path: loginCode,
    queryParameters: {
      'channel': sent.channel.name,
      'to': sent.destination,
      'wait': '${sent.resendIn.inSeconds}',
    },
  ).toString();

  /// A promo's page. Push it with the [Promo] as `extra` to skip reloading it.
  static String promo(int id) => '/promo/$id';

  /// Location of the products page, optionally pre-filtered: a search, a
  /// category id (`Category.id`; none is "Tutti") and a sort (none is the
  /// default, Più popolari). Navigate to it with `extra: ApplyProductFilters()`
  /// so the filters apply even if they equal the last ones asked for.
  static String productsWith({
    String? query,
    int? categoryId,
    ProductSort? sort,
  }) {
    return Uri(
      path: products,
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (categoryId != null) 'category': '$categoryId',
        if (sort != null) 'sort': sort.name,
      },
    ).toString();
  }
}

bool _isSignedOutPage(String location) =>
    location == AppRoutes.welcome || location.startsWith('/login/');

GoRouter createRouter(AuthController auth) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: auth,
    // Nothing but the sign-in screens without an account.
    redirect: (context, state) {
      final location = state.matchedLocation;
      switch (auth.status) {
        case AuthStatus.loading:
        case AuthStatus.offline:
          return location == AppRoutes.splash ? null : AppRoutes.splash;
        case AuthStatus.signedOut:
          return _isSignedOutPage(location) ? null : AppRoutes.welcome;
        case AuthStatus.signedIn:
          return _isSignedOutPage(location) || location == AppRoutes.splash
              ? AppRoutes.home
              : null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: AppRoutes.loginPhone,
        builder: (context, state) =>
            const ContactEntryPage(channel: CodeChannel.sms),
      ),
      GoRoute(
        path: AppRoutes.loginEmail,
        builder: (context, state) =>
            const ContactEntryPage(channel: CodeChannel.email),
      ),
      GoRoute(
        path: AppRoutes.loginCode,
        builder: (context, state) {
          final params = state.uri.queryParameters;
          return CodePage(
            channel:
                CodeChannel.values.asNameMap()[params['channel']] ??
                CodeChannel.sms,
            destination: params['to'] ?? '',
            resendIn: Duration(
              seconds: int.tryParse(params['wait'] ?? '') ?? 0,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.completeProfile,
        builder: (context, state) => const CompleteProfilePage(),
      ),
      GoRoute(
        path: AppRoutes.editAddress,
        builder: (context, state) => const AddressPage(),
      ),
      GoRoute(
        path: AppRoutes.addEmail,
        builder: (context, state) => const ContactEntryPage(
          channel: CodeChannel.email,
          addToAccount: true,
        ),
      ),
      // Outside the shell: full screen, over the navigation bar.
      GoRoute(
        path: '/promo/:id',
        builder: (context, state) => PromoPage(
          promoId: int.tryParse(state.pathParameters['id']!) ?? -1,
          promo: state.extra is Promo ? state.extra as Promo : null,
        ),
      ),
      // One branch per bottom navigation tab; each keeps its own state.
      StatefulShellRoute(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            BranchStack(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.products,
                builder: (context, state) {
                  final params = state.uri.queryParameters;
                  final extra = state.extra;
                  return ProductsPage(
                    initialQuery: params['q'] ?? '',
                    initialCategoryId: int.tryParse(params['category'] ?? ''),
                    initialSort:
                        ProductSort.values.asNameMap()[params['sort']] ??
                        ProductSort.values.first,
                    focusSearch: extra is FocusProductSearch ? extra : null,
                    applyFilters: extra is ApplyProductFilters ? extra : null,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.cart,
                builder: (context, state) => const CartPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfilePage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
