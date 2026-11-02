import 'package:flutter/cupertino.dart' show CupertinoTheme, CupertinoThemeData;
import 'package:flutter/material.dart';

/// The tabs' navigators, one on screen at a time. It works like
/// `StatefulShellRoute.indexedStack`'s container, so each tab keeps its
/// state, but a tab that isn't on screen keeps the theme it last showed
/// until it's opened again.
///
/// Switching the theme then rebuilds only the visible tab. Rebuilding every
/// live tab (Home and Prodotti and all their cards) in that one frame took
/// over 50 ms on a real device.
class BranchStack extends StatelessWidget {
  const BranchStack({
    super.key,
    required this.currentIndex,
    required this.children,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: currentIndex,
      children: [
        for (final (index, child) in children.indexed)
          _ThemeFreeze(
            active: index == currentIndex,
            child: Offstage(
              offstage: index != currentIndex,
              child: TickerMode(enabled: index == currentIndex, child: child),
            ),
          ),
      ],
    );
  }
}

/// Passes the app theme down while [active]. Otherwise it keeps passing the
/// theme it had when it was last active, so theme changes don't rebuild
/// anything below it.
class _ThemeFreeze extends StatefulWidget {
  const _ThemeFreeze({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_ThemeFreeze> createState() => _ThemeFreezeState();
}

class _ThemeFreezeState extends State<_ThemeFreeze> {
  ThemeData? _theme;
  CupertinoThemeData? _cupertinoTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.active || _theme == null) {
      if (!identical(theme, _theme)) {
        _theme = theme;
        _cupertinoTheme = MaterialBasedCupertinoThemeData(materialTheme: theme);
      }
    }

    // What `Theme` provides, but with a Cupertino theme that is kept between
    // builds: `Theme` creates a new one each time it builds, which rebuilds
    // every widget that reads the theme (`Theme.of` depends on it as well).
    // With identical values, nothing below is notified.
    final frozen = _theme!;
    return Theme(
      data: frozen,
      child: CupertinoTheme(
        data: _cupertinoTheme!,
        child: IconTheme(data: frozen.iconTheme, child: widget.child),
      ),
    );
  }
}
