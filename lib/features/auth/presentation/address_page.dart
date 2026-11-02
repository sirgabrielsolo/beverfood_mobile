import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/auth/data/auth_controller.dart';
import 'package:beverfood_mobile/features/auth/models/account.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/address_form.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/auth_widgets.dart';

/// Changes the delivery address alone. After approval it's the only data a
/// client changes, and it doesn't need a new approval.
class AddressPage extends StatefulWidget {
  const AddressPage({super.key});

  @override
  State<AddressPage> createState() => _AddressPageState();
}

class _AddressPageState extends State<AddressPage> {
  DeliveryAddress? _address;
  Map<String, String> _errors = const {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _address = AuthScope.read(context).account?.address;
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _errors = const {};
    });
    final auth = AuthScope.read(context);
    try {
      auth.update(await auth.repository.updateAddress(_address!));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Indirizzo aggiornato')));
      context.pop();
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _errors = {error.field ?? '_': error.message};
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consegna')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                children: [
                  AddressForm(
                    initial: _address,
                    errors: _errors,
                    onChanged: (address) => setState(() => _address = address),
                  ),
                  if (_errors['_'] != null) ...[
                    const SizedBox(height: 12),
                    FormError(_errors['_']),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: WideButton(
                label: 'Salva',
                busy: _busy,
                onPressed: _address == null ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
