import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:beverfood_mobile/app/theme/app_colors.dart';
import 'package:beverfood_mobile/app/theme/app_palette.dart';
import 'package:beverfood_mobile/core/formatting/phone_format.dart';
import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/auth/data/auth_controller.dart';
import 'package:beverfood_mobile/features/auth/data/auth_repository.dart';
import 'package:beverfood_mobile/features/auth/models/account.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/address_form.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/auth_widgets.dart';
import 'package:beverfood_mobile/features/auth/presentation/widgets/contact_verification.dart';

/// Completing the profile to be able to order (C2): Chi sei → Azienda →
/// Consegna, then it's sent for approval. Opens prefilled after a rejection.
class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

/// Whether an 11-digit Partita IVA has the right check digit.
bool isValidVat(String vat) {
  if (!RegExp(r'^\d{11}$').hasMatch(vat) || vat == '00000000000') return false;
  final digits = vat.split('').map(int.parse).toList();
  var total = 0;
  for (var i = 0; i < 10; i++) {
    final d = digits[i];
    total += i.isEven ? d : (d * 2 > 9 ? d * 2 - 9 : d * 2);
  }
  return (10 - total % 10) % 10 == digits[10];
}

class _CompleteProfilePageState extends State<CompleteProfilePage> {
  static const _titles = ['Chi sei', 'Azienda', 'Consegna'];

  // Fields the server may reject, by step.
  static const _stepOf = {
    'first_name': 0,
    'last_name': 0,
    'phone': 0,
    'company_name': 1,
    'vat_number': 1,
  };

  int _step = 0;
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _company = TextEditingController();
  final _vat = TextEditingController();
  DeliveryAddress? _address;
  Map<String, String> _errors = const {};
  bool _busy = false;
  bool _verifying = false;

  /// Sent: the page may close from any step.
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    final account = AuthScope.read(context).account;
    if (account != null) {
      _first.text = account.firstName ?? '';
      _last.text = account.lastName ?? '';
      _company.text = account.companyName ?? '';
      _vat.text = account.vatNumber ?? '';
      _address = account.address;
    }
    for (final c in [_first, _last, _phone, _email, _company, _vat]) {
      c.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final c in [_first, _last, _phone, _email, _company, _vat]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _canContinue(Account account) => switch (_step) {
    0 =>
      _first.text.trim().isNotEmpty &&
          _last.text.trim().isNotEmpty &&
          account.phoneVerified,
    1 => _company.text.trim().isNotEmpty && _vat.text.length == 11,
    _ => _address != null,
  };

  void _back() {
    if (_step == 0) {
      context.pop();
    } else {
      setState(() => _step--);
    }
  }

  Future<void> _next() async {
    if (_step == 1 && !isValidVat(_vat.text)) {
      setState(
        () => _errors = {
          'vat_number': 'Controlla la Partita IVA: una cifra non torna.',
        },
      );
      return;
    }
    setState(() => _errors = const {});
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    setState(() => _busy = true);
    final auth = AuthScope.read(context);
    try {
      final account = await auth.repository.submitProfile(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        companyName: _company.text.trim(),
        vatNumber: _vat.text,
        address: _address!,
      );
      auth.update(account);
      if (!mounted) return;
      // Back steps through the form until it's sent; after that it closes.
      setState(() => _sent = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.pop();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Dati inviati. Ti avviseremo quando saranno verificati.',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      final field = error.field;
      setState(() {
        _busy = false;
        _errors = {field ?? '_': error.message};
        if (field != null) _step = _stepOf[field] ?? 2;
      });
    }
  }

  Future<void> _verify(CodeChannel channel, String value) async {
    setState(() {
      _verifying = true;
      _errors = const {};
    });
    try {
      await verifyContact(context, channel, value);
    } on ApiException catch (error) {
      if (mounted) {
        setState(
          () => _errors = {
            channel == CodeChannel.email ? 'email' : 'phone': error.message,
          },
        );
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final account = AuthScope.of(context).account;
    if (account == null) return const Scaffold();
    final palette = context.palette;

    return PopScope(
      canPop: _step == 0 || _sent,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _back),
          title: Text(_titles[_step]),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: Row(
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: i <= _step ? AppColors.brand : palette.line,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Passo ${_step + 1} di 3',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: palette.textSecondary,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  children: [
                    switch (_step) {
                      0 => _whoStep(account),
                      1 => _companyStep(),
                      _ => AddressForm(
                        initial: _address,
                        errors: _errors,
                        onChanged: (address) =>
                            setState(() => _address = address),
                      ),
                    },
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
                  label: _step < 2 ? 'Avanti' : "Invia per l'approvazione",
                  busy: _busy,
                  onPressed: _canContinue(account) ? _next : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _whoStep(Account account) {
    final palette = context.palette;
    Widget verifyButton(CodeChannel channel, TextEditingController field) =>
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: TextButton(
            onPressed: _verifying || field.text.trim().isEmpty
                ? null
                : () => _verify(channel, field.text),
            child: Text(
              'Verifica',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: palette.brandText,
              ),
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LabeledField(
                label: 'Nome',
                controller: _first,
                error: _errors['first_name'],
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.givenName],
                textInputAction: TextInputAction.next,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: LabeledField(
                label: 'Cognome',
                controller: _last,
                error: _errors['last_name'],
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.familyName],
                textInputAction: TextInputAction.next,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (account.phoneVerified)
          ReadOnlyField(
            label: 'Cellulare',
            value: formatPhone(account.phone),
            trailing: const VerifiedChip(),
          )
        else ...[
          LabeledField(
            label: 'Cellulare',
            controller: _phone,
            hint: '333 123 4567',
            prefixText: '+39  ',
            keyboardType: TextInputType.phone,
            error: _errors['phone'],
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
            ],
            suffix: verifyButton(CodeChannel.sms, _phone),
          ),
          const SizedBox(height: 6),
          Text(
            'Serve per ordinare: ti mandiamo un codice per verificarlo.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: palette.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 14),
        if (account.emailVerified)
          ReadOnlyField(
            label: 'Email',
            value: account.email ?? '',
            trailing: const VerifiedChip(),
          )
        else
          LabeledField(
            label: 'Email (facoltativa)',
            controller: _email,
            hint: 'nome@azienda.it',
            keyboardType: TextInputType.emailAddress,
            error: _errors['email'],
            suffix: verifyButton(CodeChannel.email, _email),
          ),
      ],
    );
  }

  Widget _companyStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LabeledField(
          label: 'Ragione sociale',
          controller: _company,
          error: _errors['company_name'],
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.organizationName],
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        LabeledField(
          label: 'Partita IVA',
          controller: _vat,
          hint: '11 cifre',
          error: _errors['vat_number'],
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Controlliamo la Partita IVA prima di approvare il profilo.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.palette.textSecondary,
          ),
        ),
      ],
    );
  }
}
