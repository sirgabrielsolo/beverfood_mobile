import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_theme.dart';
import 'package:beverfood_mobile/app/theme/theme_mode_controller.dart';

class BeverfoodApp extends StatefulWidget {
  const BeverfoodApp({super.key, required this.themeModeController});

  final ThemeModeController themeModeController;

  @override
  State<BeverfoodApp> createState() => _BeverfoodAppState();
}

class _BeverfoodAppState extends State<BeverfoodApp> {
  // Owned by the widget so each app instance (e.g. in tests) gets fresh
  // navigation state.
  late final GoRouter _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeModeScope(
      controller: widget.themeModeController,
      child: ListenableBuilder(
        listenable: widget.themeModeController,
        builder: (context, _) => MaterialApp.router(
          title: 'Beverfood',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: widget.themeModeController.mode,
          routerConfig: _router,
        ),
      ),
    );
  }
}
