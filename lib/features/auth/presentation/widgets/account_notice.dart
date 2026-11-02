import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/app/theme/app_radii.dart';
import 'package:beverfood_mobile/features/auth/data/auth_controller.dart';
import 'package:beverfood_mobile/features/auth/models/account.dart';

/// Why the client can't order yet, on Home (D1) and in the cart (D2). Red
/// while something is up to the client (profile to complete or fix, account
/// suspended), yellow while Beverfood checks the data. Nothing once approved.
class AccountNotice extends StatelessWidget {
  const AccountNotice({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final account = AuthScope.of(context).account;
    if (account == null || account.canOrder) return const SizedBox.shrink();
    final palette = context.palette;

    final (
      IconData icon,
      String title,
      String body,
      String? action,
    ) = switch (account.status) {
      AccountStatus.pending => (
        Icons.schedule_rounded,
        'Profilo in verifica',
        'Potrai inviare ordini una volta verificati i tuoi dati.',
        null,
      ),
      AccountStatus.rejected => (
        Icons.error_outline_rounded,
        'Dati da correggere',
        account.reviewNote ?? 'Controlla i dati che ci hai inviato.',
        'Correggi i dati',
      ),
      AccountStatus.suspended => (
        Icons.block_rounded,
        'Account sospeso',
        account.reviewNote ?? 'Per informazioni contatta Beverfood.',
        null,
      ),
      _ => (
        Icons.person_outline_rounded,
        'Completa il profilo per ordinare',
        "Servono i dati della tua azienda e l'indirizzo di consegna.",
        'Completa ora',
      ),
    };
    final yellow = account.status == AccountStatus.pending;
    final background = yellow ? palette.warning : palette.navIndicator;
    final foreground = yellow ? palette.onWarning : palette.brandText;

    return Padding(
      padding: padding,
      child: Material(
        color: background,
        borderRadius: AppRadii.card,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foreground, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (action != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: InkWell(
                          onTap: () => context.push(AppRoutes.completeProfile),
                          child: Text(
                            action,
                            style: TextStyle(
                              color: foreground,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              decoration: TextDecoration.underline,
                              decorationColor: foreground,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
