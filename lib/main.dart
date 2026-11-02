import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:beverfood_mobile/app/app.dart';
import 'package:beverfood_mobile/app/theme/theme_mode_controller.dart';
import 'package:beverfood_mobile/core/widgets/app_network_image.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  // Product photos stay on disk between launches.
  AppNetworkImage.provider = CachedNetworkImageProvider.new;

  runApp(BeverfoodApp(themeModeController: ThemeModeController(prefs)));
}
