import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/app_assets.dart';
import 'package:beverfood_mobile/core/widgets/empty_state.dart';
import 'package:beverfood_mobile/features/auth/data/auth_controller.dart';

/// Shown while the saved sign-in is checked, or when the server couldn't be
/// reached to check it.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthScope.of(context);
    return Scaffold(
      body: auth.status == AuthStatus.offline
          ? EmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Connessione non riuscita',
              message: 'Controlla la rete e riprova.',
              action: FilledButton(
                onPressed: auth.retry,
                child: const Text('Riprova'),
              ),
            )
          : Center(child: Image.asset(AppAssets.logo, width: 96, height: 96)),
    );
  }
}
