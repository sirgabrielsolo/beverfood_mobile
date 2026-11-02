import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_theme.dart';
import 'package:beverfood_mobile/features/products/models/category.dart';

/// Category tabs ("Tutti" first, then the catalogue's categories) pinned at
/// the top while the content below scrolls. Returns a sliver. A `null`
/// category id means "Tutti".
class CategoryTabBar extends StatefulWidget {
  const CategoryTabBar({
    super.key,
    required this.categories,
    required this.selectedId,
    required this.onSelected,
  });

  /// Empty while the catalogue loads: only "Tutti" shows.
  final List<Category> categories;
  final int? selectedId;
  final ValueChanged<int?> onSelected;

  @override
  State<CategoryTabBar> createState() => _CategoryTabBarState();
}

class _CategoryTabBarState extends State<CategoryTabBar>
    with TickerProviderStateMixin {
  late List<int?> _ids;
  late TabController _controller;

  @override
  void initState() {
    super.initState();
    _ids = _idsOf(widget.categories);
    _controller = _newController();
  }

  static List<int?> _idsOf(List<Category> categories) => [
    null,
    for (final category in categories) category.id,
  ];

  int get _selectedIndex {
    final index = _ids.indexOf(widget.selectedId);
    return index < 0 ? 0 : index;
  }

  TabController _newController() => TabController(
    length: _ids.length,
    initialIndex: _selectedIndex,
    vsync: this,
  );

  @override
  void didUpdateWidget(CategoryTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final ids = _idsOf(widget.categories);
    if (!_sameIds(ids, _ids)) {
      // The catalogue arrived or changed: a controller of the new length.
      _ids = ids;
      _controller.dispose();
      _controller = _newController();
      return;
    }
    // Follows category changes made from outside, e.g. a home tile.
    if (_selectedIndex != _controller.index) {
      _controller.animateTo(_selectedIndex);
    }
  }

  static bool _sameIds(List<int?> a, List<int?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
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
      onTap: (index) => widget.onSelected(_ids[index]),
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      // 16 from the screen edge to the first label, 22 between labels.
      padding: const EdgeInsets.symmetric(horizontal: 5),
      labelPadding: const EdgeInsets.symmetric(horizontal: 11),
      labelColor: palette.textPrimary,
      unselectedLabelColor: palette.textSecondary,
      // The app font named explicitly: TabBar replaces the inherited text
      // style with these, so without it the tabs fall back to the system font.
      labelStyle: const TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
      unselectedLabelStyle: const TextStyle(
        fontFamily: AppTheme.fontFamily,
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
        Tab(
          height: textScaler.scale(_TabBarHeaderDelegate.baseTabHeight),
          text: 'Tutti',
        ),
        for (final category in widget.categories)
          Tab(
            height: textScaler.scale(_TabBarHeaderDelegate.baseTabHeight),
            text: category.name,
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
