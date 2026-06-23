import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import 'api_client.dart';

/// Owns authentication state: token, current user (with roles + employee),
/// password login, biometric unlock, and logout. The token is held in secure
/// storage; biometrics gate its release rather than replacing the password.
class AuthService extends ChangeNotifier {
  AuthService() {
    api = ApiClient(
      tokenProvider: () => _token,
      localeProvider: () => localeCode,
    );
  }

  late final ApiClient api;
  final _storage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  String? _token;
  Map<String, dynamic>? user;
  bool initializing = true;

  // Set by main so the API sends the right Accept-Language header.
  String localeCode = 'en';

  bool get isLoggedIn => _token != null && user != null;
  List<String> get roles =>
      ((user?['roles'] as List?)?.cast<String>()) ?? const [];
  bool hasAnyRole(List<String> r) => roles.any(r.contains);

  static const _tokenKey = 'auth_token';

  /// On startup, try to restore a stored session.
  Future<void> bootstrap() async {
    _token = await _storage.read(key: _tokenKey);
    if (_token != null) {
      try {
        await _loadProfile();
      } catch (_) {
        await logout();
      }
    }
    initializing = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final res = await api.post('/login', data: {
      'email': email,
      'password': password,
      'device_name': 'flutter',
    });
    _token = res.data['token'] as String;
    user = (res.data['user'] as Map).cast<String, dynamic>();
    await _storage.write(key: _tokenKey, value: _token);
    _registerDeviceToken();
    notifyListeners();
  }

  bool get biometricPossible => !kIsWeb;

  /// Unlock with fingerprint/Face ID, then restore the stored session.
  Future<bool> loginWithBiometrics() async {
    if (await _storage.read(key: _tokenKey) == null) return false;

    final ok = await _localAuth.authenticate(
      localizedReason: 'Authenticate to access the HR app',
      options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
    );
    if (!ok) return false;

    _token = await _storage.read(key: _tokenKey);
    await _loadProfile();
    notifyListeners();
    return true;
  }

  Future<bool> canUseBiometrics() async {
    if (kIsWeb) return false;
    try {
      final has = await _localAuth.canCheckBiometrics;
      final stored = await _storage.read(key: _tokenKey) != null;
      return has && stored;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadProfile() async {
    final res = await api.get('/me');
    user = (res.data['user'] as Map).cast<String, dynamic>();
  }

  Future<void> _registerDeviceToken() async {
    if (kIsWeb) return;
    // FCM token registration placeholder — in production, obtain the
    // actual FCM token from firebase_messaging and send it here.
    // For now this is a no-op that shows the integration point.
  }

  Future<void> logout() async {
    try {
      if (_token != null) await api.post('/logout');
    } catch (_) {}
    _token = null;
    user = null;
    await _storage.delete(key: _tokenKey);
    notifyListeners();
  }
}
