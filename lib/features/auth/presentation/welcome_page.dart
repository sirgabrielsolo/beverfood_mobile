import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/app_assets.dart';
import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/auth_widgets.dart';

/// The only screen without an account (A1): the logo, large and in its own
/// red, then the two ways in. Signing in and signing up are the same path.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The logo takes all the room above the title.
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = math.min(
                        constraints.maxWidth * 0.75,
                        constraints.maxHeight * 0.85,
                      );
                      return Center(
                        child: Image.asset(
                          AppAssets.logo,
                          width: side,
                          height: side,
                          semanticLabel: 'Beverfood',
                        ),
                      );
                    },
                  ),
                ),
                const Text(
                  'Benvenuto su Beverfood',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bevande, vini e food per il tuo locale. Accedi o registrati '
                  'per vedere catalogo, prezzi e promozioni.',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),
                WideButton(
                  label: 'Continua con il telefono',
                  icon: Icons.smartphone_rounded,
                  onPressed: () => context.push(AppRoutes.loginPhone),
                ),
                const SizedBox(height: 10),
                WideButton(
                  label: "Continua con l'email",
                  icon: Icons.mail_outline_rounded,
                  primary: false,
                  onPressed: () => context.push(AppRoutes.loginEmail),
                ),
                const SizedBox(height: 14),
                Text(
                  "Continuando dichiari di aver letto l'Informativa privacy e "
                  "accetti i Termini d'uso.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
