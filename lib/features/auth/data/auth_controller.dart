import 'package:flutter/widgets.dart';

import 'package:beverfood_mobile/core/network/api_client.dart';
import 'package:beverfood_mobile/features/auth/data/auth_repository.dart';
import 'package:beverfood_mobile/features/auth/data/token_store.dart';
import 'package:beverfood_mobile/features/auth/models/account.dart';

enum AuthStatus {
  /// Reading the saved token and the account.
  loading,

  /// A saved token, but the server couldn't be reached to check it.
  offline,

  signedOut,
  signedIn,
}

/// Who is signed in. The router follows [status]: nothing but the sign-in
/// screens without an account. Owned by `BeverfoodApp`, exposed with
/// [AuthScope.of].
class AuthController extends ChangeNotifier {
  AuthController({
    required ApiClient api,
    required this.repository,
    required TokenStore tokenStore,
  }) : _api = api,
       _tokens = tokenStore {
    // A token refused mid-session (expired, account deleted) signs out.
    _api.onUnauthorized = () => _signOutLocally();
  }

  final ApiClient _api;
  final TokenStore _tokens;
  final AuthRepository repository;

  AuthStatus _status = AuthStatus.loading;
  AuthStatus get status => _status;

  Account? _account;

  /// The signed-in account; null unless [status] is `signedIn`.
  Account? get account => _account;

  /// Restores the saved session. Called once at launch.
  Future<void> start() async {
    final token = await _tokens.read();
    if (token == null) {
      _set(AuthStatus.signedOut, null);
      return;
    }
    _api.token = token;
    await refresh();
  }

  /// Reloads the account, e.g. when the app comes back to the foreground
  /// (to see an approval). Signs out if the token was refused.
  Future<void> refresh() async {
    if (_api.token == null) return;
    try {
      _set(AuthStatus.signedIn, await repository.me());
    } on ApiException catch (error) {
      if (error.isOffline) {
        // Keep a known account on screen; only a cold start needs the server.
        if (_account == null) _set(AuthStatus.offline, null);
      } else if (error.status == 401) {
        await _signOutLocally();
      } else if (_account == null) {
        _set(AuthStatus.offline, null);
      }
    }
  }

  /// Retries a launch that couldn't reach the server.
  Future<void> retry() async {
    _set(AuthStatus.loading, null);
    await refresh();
  }

  Future<void> signIn(String token, Account account) async {
    await _tokens.write(token);
    _api.token = token;
    _set(AuthStatus.signedIn, account);
  }

  /// Shows a changed account (profile sent, address, contact verified).
  void update(Account account) => _set(AuthStatus.signedIn, account);

  Future<void> signOut() async {
    try {
      await repository.logout();
    } on ApiException {
      // Signed out on this device anyway; the server session just expires.
    }
    await _signOutLocally();
  }

  /// Deletes the account on the server, then signs out. Throws
  /// [ApiException] (e.g. for the test account) and stays signed in.
  Future<void> deleteAccount() async {
    await repository.deleteAccount();
    await _signOutLocally();
  }

  Future<void> _signOutLocally() async {
    _api.token = null;
    await _tokens.clear();
    _set(AuthStatus.signedOut, null);
  }

  void _set(AuthStatus status, Account? account) {
    _status = status;
    _account = account;
    notifyListeners();
  }
}

/// Makes the [AuthController] available to the widget tree.
class AuthScope extends InheritedNotifier<AuthController> {
  const AuthScope({
    super.key,
    required AuthController controller,
    required super.child,
  }) : super(notifier: controller);

  static AuthController of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AuthScope>()!.notifier!;
  }

  /// The controller without rebuilding when it changes, for callbacks.
  static AuthController read(BuildContext context) {
    return context.getInheritedWidgetOfExactType<AuthScope>()!.notifier!;
  }
}
