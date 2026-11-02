import 'package:flutter/foundation.dart';

import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/auth/models/account.dart';

/// How a sign-in code travels.
enum CodeChannel { sms, whatsapp, email }

/// A code was sent: where to, and when another may be asked for.
class CodeSent {
  const CodeSent({
    required this.channel,
    required this.destination,
    required this.resendIn,
  });

  final CodeChannel channel;

  /// The normalised phone (+39…) or email.
  final String destination;
  final Duration resendIn;
}

/// The account endpoints of beverfood_web's `/api/v1` (`api.py` there).
/// Every method throws [ApiException] with a message for the screen.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  Map<String, Object?> _contact(CodeChannel channel, String value) => {
    'channel': channel.name,
    if (channel == CodeChannel.email) 'email': value else 'phone': value,
  };

  CodeSent _sent(Object? json) {
    final map = json! as Map<String, Object?>;
    return CodeSent(
      channel: CodeChannel.values.byName(map['channel'] as String),
      destination: map['destination'] as String,
      resendIn: Duration(seconds: map['resend_in'] as int? ?? 0),
    );
  }

  Account _account(Object? json) => Account.fromJson(
    (json! as Map<String, Object?>)['client'] as Map<String, Object?>,
  );

  /// Sends a sign-in code; also signs up a new phone or email.
  Future<CodeSent> requestCode(CodeChannel channel, String value) async =>
      _sent(await _api.postJson('/api/v1/auth/code', _contact(channel, value)));

  /// Exchanges a code for a token and the account.
  Future<({String token, Account account})> verifyCode(
    CodeChannel channel,
    String destination,
    String code,
  ) async {
    final json = await _api.postJson('/api/v1/auth/verify', {
      ..._contact(channel, destination),
      'code': code,
      'device': defaultTargetPlatform.name,
    });
    final map = json! as Map<String, Object?>;
    return (token: map['token'] as String, account: _account(json));
  }

  Future<Account> me() async => _account(await _api.getJson('/api/v1/me'));

  Future<void> logout() => _api.postJson('/api/v1/auth/logout');

  Future<void> deleteAccount() => _api.delete('/api/v1/me');

  /// Sends the profile for approval (also again, after a rejection).
  Future<Account> submitProfile({
    required String firstName,
    required String lastName,
    required String companyName,
    required String vatNumber,
    required DeliveryAddress address,
  }) async => _account(
    await _api.putJson('/api/v1/me/profile', {
      'first_name': firstName,
      'last_name': lastName,
      'company_name': companyName,
      'vat_number': vatNumber,
      'address': address.toJson(),
    }),
  );

  /// Changes the delivery address alone; never needs a new approval.
  Future<Account> updateAddress(DeliveryAddress address) async =>
      _account(await _api.putJson('/api/v1/me/address', address.toJson()));

  /// Sends a code to add the other contact (the phone after an email
  /// sign-up, or an optional email).
  Future<CodeSent> requestContactCode(
    CodeChannel channel,
    String value,
  ) async => _sent(
    await _api.postJson('/api/v1/me/contact/code', _contact(channel, value)),
  );

  Future<Account> verifyContact(
    CodeChannel channel,
    String destination,
    String code,
  ) async => _account(
    await _api.postJson('/api/v1/me/contact/verify', {
      ..._contact(channel, destination),
      'code': code,
    }),
  );

  List<Comune>? _comuni;

  /// The province's 312 comuni; loaded once, then kept.
  Future<List<Comune>> comuni() async {
    if (_comuni != null) return _comuni!;
    final json = await _api.getJson('/api/v1/places/comuni');
    return _comuni = [
      for (final c in (json! as Map<String, Object?>)['comuni'] as List)
        Comune.fromJson(c as Map<String, Object?>),
    ];
  }

  Future<List<Street>> streets(String istat, String query) async {
    final json = await _api.getJson(
      Uri(
        path: '/api/v1/places/streets',
        queryParameters: {'istat': istat, 'q': query},
      ).toString(),
    );
    return [
      for (final s in (json! as Map<String, Object?>)['streets'] as List)
        Street.fromJson(s as Map<String, Object?>),
    ];
  }
}
