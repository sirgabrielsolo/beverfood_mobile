import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's light/dark preference and persists it across launches.
class ThemeModeController extends ChangeNotifier {
  ThemeModeController(this._prefs) : _mode = _read(_prefs);

  static const _key = 'theme_mode';

  final SharedPreferences _prefs;
  ThemeMode _mode;

  /// [ThemeMode.system] follows the device setting.
  ThemeMode get mode => _mode;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    await _prefs.setString(_key, mode.name);
  }

  static ThemeMode _read(SharedPreferences prefs) {
    return ThemeMode.values.asNameMap()[prefs.getString(_key)] ??
        ThemeMode.system;
  }
}

/// Makes the [ThemeModeController] available to the widget tree.
class ThemeModeScope extends InheritedNotifier<ThemeModeController> {
  const ThemeModeScope({
    super.key,
    required ThemeModeController controller,
    required super.child,
  }) : super(notifier: controller);

  static ThemeModeController of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeModeScope>()!
        .notifier!;
  }
}
