import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/shell/app_shell.dart';
import 'package:beverfood_mobile/app/shell/branch_stack.dart';
import 'package:beverfood_mobile/features/cart/presentation/cart_page.dart';
import 'package:beverfood_mobile/features/home/presentation/home_page.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';
import 'package:beverfood_mobile/features/products/presentation/products_page.dart';
import 'package:beverfood_mobile/features/profile/presentation/profile_page.dart';
import 'package:beverfood_mobile/features/promotions/models/promo.dart';
import 'package:beverfood_mobile/features/promotions/presentation/promo_page.dart';

abstract final class AppRoutes {
  static const home = '/';
  static const products = '/products';
  static const cart = '/cart';
  static const profile = '/profile';

  /// A promo's page. Push it with the [Promo] as `extra` to skip reloading it.
  static String promo(int id) => '/promo/$id';

  /// Location of the products page, optionally pre-filtered.
  static String productsWith({String? query, ProductCategory? category}) {
    return Uri(
      path: products,
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        if (category != null) 'category': category.name,
      },
    ).toString();
  }
}

GoRouter createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
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
                  return ProductsPage(
                    initialQuery: params['q'] ?? '',
                    initialCategory: ProductCategory.values
                        .asNameMap()[params['category']],
                    focusSearch: state.extra is FocusProductSearch
                        ? state.extra as FocusProductSearch
                        : null,
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
