import 'package:flutter/material.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/auth/data/auth_controller.dart';
import 'package:beverfood_mobile/features/auth/data/auth_repository.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/code_input.dart';

/// Sends a code to a second contact (the phone after an email sign-up, or an
/// email after a phone one) and asks for it in a bottom sheet. Returns true
/// once verified; the account is updated. Throws [ApiException] when the
/// code can't be sent (e.g. the contact belongs to another account).
Future<bool> verifyContact(
  BuildContext context,
  CodeChannel channel,
  String value,
) async {
  final auth = AuthScope.read(context);
  final sent = await auth.repository.requestContactCode(channel, value);
  if (!context.mounted) return false;
  final verified = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _CodeSheet(sent: sent),
  );
  return verified ?? false;
}

class _CodeSheet extends StatefulWidget {
  const _CodeSheet({required this.sent});

  final CodeSent sent;

  @override
  State<_CodeSheet> createState() => _CodeSheetState();
}

class _CodeSheetState extends State<_CodeSheet> {
  final _code = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = AuthScope.read(context);
    try {
      final account = await auth.repository.verifyContact(
        widget.sent.channel,
        widget.sent.destination,
        _code.text,
      );
      auth.update(account);
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _busy = false;
      });
      _code.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.sent.channel == CodeChannel.email;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isEmail ? "Verifica l'email" : 'Verifica il cellulare',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Inserisci il codice che abbiamo inviato a '
            '${widget.sent.destination}.',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: context.palette.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          CodeInput(
            controller: _code,
            error: _error,
            enabled: !_busy,
            onCompleted: (_) => _verify(),
          ),
        ],
      ),
    );
  }
}
