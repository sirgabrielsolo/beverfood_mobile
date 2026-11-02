import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/app_assets.dart';
import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/core/widgets/search_field.dart';
import 'package:beverfood_mobile/features/products/presentation/products_page.dart';

/// Header at the top of the home page: logo and name, then the search bar.
/// Brand red in light mode, a raised dark surface in dark mode. Returns a
/// sliver.
///
/// The logo row scrolls away; the search bar stays pinned at the top.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HomeHeaderDelegate(
        topPadding: MediaQuery.paddingOf(context).top,
      ),
    );
  }
}

class _HomeHeaderDelegate extends SliverPersistentHeaderDelegate {
  _HomeHeaderDelegate({required this.topPadding});

  /// Status bar height; the header extends behind it.
  final double topPadding;

  static const _padding = 16.0;
  static const _logoSize = 42.0;

  /// Space above the pinned search bar, below the status bar.
  static const _pinnedTopGap = 8.0;

  @override
  double get maxExtent =>
      topPadding +
      _padding +
      _logoSize +
      _padding +
      SearchField.height +
      _padding;

  @override
  double get minExtent =>
      topPadding + _pinnedTopGap + SearchField.height + _padding;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return _HeaderContent(topPadding: topPadding, shrinkOffset: shrinkOffset);
  }

  @override
  bool shouldRebuild(_HomeHeaderDelegate oldDelegate) =>
      topPadding != oldDelegate.topPadding;
}

/// The header itself. A widget of its own so it reads the theme colors in its
/// own `build` and restyles when the theme changes.
class _HeaderContent extends StatelessWidget {
  const _HeaderContent({required this.topPadding, required this.shrinkOffset});

  final double topPadding;
  final double shrinkOffset;

  @override
  Widget build(BuildContext context) {
    const padding = _HomeHeaderDelegate._padding;
    final palette = context.palette;

    // The logo row fades out as it slides under the status bar. It fades by
    // color alpha rather than with `Opacity`, which would paint it into an
    // offscreen layer on every scroll frame.
    final logoOpacity =
        (1 - shrinkOffset / (padding + _HomeHeaderDelegate._logoSize)).clamp(
          0.0,
          1.0,
        );

    // Light status bar icons: the header is dark in both themes (brand red,
    // or a dark surface in dark mode).
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      // Nothing to clip: the header is pinned at the top of the screen, so the
      // logo row leaves through the screen edge. Clips are costly per frame.
      child: Material(
        color: palette.header,
        borderRadius: AppRadii.header,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              top: topPadding + padding - shrinkOffset,
              left: padding,
              right: padding,
              child: _BrandRow(opacity: logoOpacity),
            ),
            Positioned(
              left: padding,
              right: padding,
              bottom: padding,
              // Opens Prodotti with its search field focused.
              child: SearchFieldButton(
                color: palette.headerField,
                contentColor: palette.onHeaderField,
                onTap: () =>
                    context.go(AppRoutes.products, extra: FocusProductSearch()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return SizedBox(
      height: _HomeHeaderDelegate._logoSize,
      child: Row(
        children: [
          // A red square with cut-out lettering. Tinted white on the red
          // header so the lettering shows the red; its own red on the dark
          // header. `opacity` fades it through the paint, without a layer.
          Image.asset(
            AppAssets.logo,
            height: _HomeHeaderDelegate._logoSize,
            color: palette.headerLogoTint,
            opacity: AlwaysStoppedAnimation(opacity),
            semanticLabel: 'Beverfood',
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Beverfood',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.onHeader.withValues(alpha: opacity),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
