import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/router.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/auth/data/auth_controller.dart';
import 'package:beverfood_mobile/features/auth/data/auth_repository.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/auth_widgets.dart';

/// Phone or email to sign in (or up) with; a code is sent to it.
class ContactEntryPage extends StatefulWidget {
  const ContactEntryPage({super.key, required this.channel});

  /// `sms` for the phone (WhatsApp is offered on the code screen), or `email`.
  final CodeChannel channel;

  @override
  State<ContactEntryPage> createState() => _ContactEntryPageState();
}

class _ContactEntryPageState extends State<ContactEntryPage> {
  final _field = TextEditingController();
  String? _error;
  bool _busy = false;

  bool get _isEmail => widget.channel == CodeChannel.email;

  @override
  void initState() {
    super.initState();
    _field.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final sent = await AuthScope.read(
        context,
      ).repository.requestCode(widget.channel, _field.text);
      if (mounted) context.push(AppRoutes.loginCodeFor(sent));
    } on ApiException catch (error) {
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ready = _field.text.trim().length >= (_isEmail ? 5 : 9);

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                children: [
                  Text(
                    _isEmail ? 'La tua email' : 'Il tuo cellulare',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _isEmail
                        ? 'Ti inviamo un codice per entrare.'
                        : 'Ti inviamo un codice via SMS per entrare. '
                              'Serve un cellulare italiano.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LabeledField(
                    label: _isEmail ? 'Email' : 'Cellulare',
                    controller: _field,
                    autofocus: true,
                    error: _error,
                    hint: _isEmail ? 'nome@azienda.it' : '333 123 4567',
                    prefixText: _isEmail ? null : '+39  ',
                    keyboardType: _isEmail
                        ? TextInputType.emailAddress
                        : TextInputType.phone,
                    autofillHints: [
                      _isEmail
                          ? AutofillHints.email
                          : AutofillHints.telephoneNumberNational,
                    ],
                    inputFormatters: _isEmail
                        ? [FilteringTextInputFormatter.deny(RegExp(r'\s'))]
                        : [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9 ]'),
                            ),
                          ],
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => ready && !_busy ? _send() : null,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: WideButton(
                label: 'Ricevi il codice',
                busy: _busy,
                onPressed: ready ? _send : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
