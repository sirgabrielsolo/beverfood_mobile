import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/features/products/models/product.dart';

/// Category tabs ("Tutti" first) pinned at the top while the content below
/// scrolls. Returns a sliver. A `null` category means "Tutti".
class CategoryTabBar extends StatefulWidget {
  const CategoryTabBar({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onSelected;

  @override
  State<CategoryTabBar> createState() => _CategoryTabBarState();
}

class _CategoryTabBarState extends State<CategoryTabBar>
    with SingleTickerProviderStateMixin {
  static const _categories = [null, ...ProductCategory.values];

  late final _controller = TabController(
    length: _categories.length,
    initialIndex: _categories.indexOf(widget.selected),
    vsync: this,
  );

  @override
  void didUpdateWidget(CategoryTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Follows category changes made from outside, e.g. a home tile.
    final index = _categories.indexOf(widget.selected);
    if (index != _controller.index) _controller.animateTo(index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final textScaler = MediaQuery.textScalerOf(context);

    final tabBar = TabBar(
      controller: _controller,
      onTap: (index) => widget.onSelected(_categories[index]),
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      // 16 from the screen edge to the first label, 22 between labels.
      padding: const EdgeInsets.symmetric(horizontal: 5),
      labelPadding: const EdgeInsets.symmetric(horizontal: 11),
      labelColor: palette.textPrimary,
      unselectedLabelColor: palette.textSecondary,
      labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
      unselectedLabelStyle: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: palette.brandText, width: 3),
      ),
      indicatorSize: TabBarIndicatorSize.label,
      dividerColor: palette.line,
      dividerHeight: 1,
      tabs: [
        for (final category in _categories)
          Tab(
            height: textScaler.scale(_TabBarHeaderDelegate.baseTabHeight),
            text: category?.label ?? 'Tutti',
          ),
      ],
    );

    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarHeaderDelegate(
        tabBar: tabBar,
        height: tabBar.preferredSize.height,
        background: palette.background,
      ),
    );
  }
}

class _TabBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabBarHeaderDelegate({
    required this.tabBar,
    required this.height,
    required this.background,
  });

  static const baseTabHeight = 46.0;

  final TabBar tabBar;
  final double height;
  final Color background;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(color: background, child: tabBar);
  }

  @override
  bool shouldRebuild(_TabBarHeaderDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar ||
      height != oldDelegate.height ||
      background != oldDelegate.background;
}
