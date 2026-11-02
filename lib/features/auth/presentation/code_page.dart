import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/core/formatting/phone_format.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/auth/data/auth_controller.dart';
import 'package:beverfood_mobile/features/auth/data/auth_repository.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/code_input.dart';

/// Enter the code just sent (B2). Six digits verify by themselves; a right
/// code signs in (or up) and the router opens Home.
class CodePage extends StatefulWidget {
  const CodePage({
    super.key,
    required this.channel,
    required this.destination,
    required this.resendIn,
  });

  final CodeChannel channel;
  final String destination;
  final Duration resendIn;

  @override
  State<CodePage> createState() => _CodePageState();
}

class _CodePageState extends State<CodePage> {
  final _code = TextEditingController();
  late CodeChannel _channel = widget.channel;
  String? _error;
  bool _busy = false;
  late int _wait = widget.resendIn.inSeconds;
  Timer? _timer;

  bool get _isEmail => _channel == CodeChannel.email;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
    _startCountdown(_wait);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown(int seconds) {
    _timer?.cancel();
    _wait = seconds;
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _wait--);
      if (_wait <= 0) timer.cancel();
    });
  }

  Future<void> _verify() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final auth = AuthScope.read(context);
    try {
      final result = await auth.repository.verifyCode(
        _channel,
        widget.destination,
        _code.text,
      );
      await auth.signIn(result.token, result.account);
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message;
        _busy = false;
      });
      _code.clear();
    }
  }

  Future<void> _resend(CodeChannel channel) async {
    setState(() => _error = null);
    try {
      final sent = await AuthScope.read(
        context,
      ).repository.requestCode(channel, widget.destination);
      if (!mounted) return;
      setState(() {
        _channel = sent.channel;
        _startCountdown(sent.resendIn.inSeconds);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            channel == CodeChannel.whatsapp
                ? 'Codice inviato su WhatsApp'
                : 'Nuovo codice inviato',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  String get _sentBy => switch (_channel) {
    CodeChannel.sms => 'via SMS al',
    CodeChannel.whatsapp => 'su WhatsApp al',
    CodeChannel.email => 'a',
  };

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final secondary = TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: palette.textSecondary,
    );
    final link = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: palette.brandText,
    );
    final shown = _isEmail
        ? widget.destination
        : formatPhone(widget.destination);

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
                    _isEmail ? "Controlla l'email" : 'Inserisci il codice',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      style: secondary,
                      children: [
                        TextSpan(text: 'Abbiamo inviato un codice $_sentBy '),
                        TextSpan(
                          text: shown,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const TextSpan(text: '. '),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => context.pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 36),
                      ),
                      child: Text('Modifica', style: link),
                    ),
                  ),
                  const SizedBox(height: 8),
                  CodeInput(
                    controller: _code,
                    error: _error,
                    enabled: !_busy,
                    onCompleted: (_) => _verify(),
                  ),
                  const SizedBox(height: 14),
                  if (_wait > 0)
                    Text(
                      'Invia di nuovo tra 0:${_wait.toString().padLeft(2, '0')}'
                      '${_isEmail ? ' · Guarda anche nella posta indesiderata.' : ''}',
                      style: secondary.copyWith(fontSize: 13),
                    )
                  else
                    Wrap(
                      spacing: 16,
                      children: [
                        TextButton(
                          onPressed: () => _resend(
                            _isEmail ? CodeChannel.email : CodeChannel.sms,
                          ),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                          child: Text('Invia di nuovo', style: link),
                        ),
                        if (!_isEmail)
                          TextButton(
                            onPressed: () => _resend(CodeChannel.whatsapp),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: Text('Ricevilo su WhatsApp', style: link),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: WideButton(
                label: 'Verifica',
                busy: _busy,
                onPressed: _code.text.length == CodeInput.length
                    ? _verify
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
