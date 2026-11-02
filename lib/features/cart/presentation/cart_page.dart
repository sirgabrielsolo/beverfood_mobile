import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/core/widgets/empty_state.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/account_notice.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Carrello')),
      body: Column(
        children: [
          // The same notice as on Home (D2): ordering waits for approval.
          const AccountNotice(padding: EdgeInsets.fromLTRB(16, 8, 16, 0)),
          Expanded(
            child: EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Il tuo carrello è vuoto',
              message: 'Aggiungi i prodotti che ti piacciono per vederli qui.',
              action: FilledButton(
                onPressed: () => context.go(AppRoutes.products),
                child: const Text('Scopri i prodotti'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
