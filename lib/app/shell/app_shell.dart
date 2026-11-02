import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/features/cart/data/cart_controller.dart';
import 'package:beverfood_mobile/features/cart/presentation/widgets/cart_bar.dart';

/// Scaffold hosting the bottom navigation bar shared by all main tabs.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Status bar icons follow the theme. App bars set this themselves, but
    // pages whose bar scrolls away need a fallback for the empty status bar.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _CartBarSlot(
              currentIndex: navigationShell.currentIndex,
              onOpenCart: () => navigationShell.goBranch(_cartBranch),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: context.palette.line)),
              ),
              child: NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                // Tapping the active tab again returns it to its initial location.
                onDestinationSelected: (index) => navigationShell.goBranch(
                  index,
                  initialLocation: index == navigationShell.currentIndex,
                ),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home_rounded),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.grid_view_outlined),
                    selectedIcon: Icon(Icons.grid_view_rounded),
                    label: 'Prodotti',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.shopping_cart_outlined),
                    selectedIcon: Icon(Icons.shopping_cart_rounded),
                    label: 'Carrello',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'Profilo',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _cartBranch = 2;
}

/// The agreed "Vai al carrello" bar, above the navigation bar while the cart
/// has something in it (not on the Carrello tab itself). Only this widget
/// listens to the cart, so adding a product doesn't rebuild the shell.
class _CartBarSlot extends StatelessWidget {
  const _CartBarSlot({required this.currentIndex, required this.onOpenCart});

  final int currentIndex;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final cart = CartScope.of(context);
    final visible = cart.itemCount > 0 && currentIndex != AppShell._cartBranch;

    // Slides up from the navigation bar; the page above shrinks with it, so
    // nothing scrolls underneath.
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      // Don't cut the bar's shadow.
      clipBehavior: Clip.none,
      child: visible
          ? Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: CartBar(
                itemCount: cart.itemCount,
                total: cart.total,
                onTap: onOpenCart,
              ),
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
