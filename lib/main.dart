import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beverfood_mobile/app/app.dart';
import 'package:beverfood_mobile/app/theme/theme_mode_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  runApp(BeverfoodApp(themeModeController: ThemeModeController(prefs)));
}
