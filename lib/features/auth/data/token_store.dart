import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the sign-in token is kept between launches.
abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

/// The device's secure storage: Android Keystore, iOS Keychain.
class SecureTokenStore implements TokenStore {
  const SecureTokenStore();

  static const _key = 'auth_token';
  static const _storage = FlutterSecureStorage();

  @override
  Future<String?> read() async {
    try {
      // Never let a stuck keystore hold the app on its start screen.
      return await _storage.read(key: _key).timeout(const Duration(seconds: 3));
    } on Exception {
      // Unreadable (e.g. restored from another device's backup) or too slow:
      // sign in again.
      return null;
    }
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

/// In memory only, for tests.
class MemoryTokenStore implements TokenStore {
  MemoryTokenStore([this.token]);

  String? token;

  @override
  Future<String?> read() async => token;

  @override
  Future<void> write(String token) async => this.token = token;

  @override
  Future<void> clear() async => token = null;
}
