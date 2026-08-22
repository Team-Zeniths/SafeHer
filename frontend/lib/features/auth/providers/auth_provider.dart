import 'package:flutter/material.dart';
import '../../../core/services/storage_service.dart';
import '../../../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Holds authentication state (current user, session status) and
/// exposes the actions the UI can trigger (login, register, Google
/// sign-in, logout). Also extends [ChangeNotifier] so it can double
/// as a `refreshListenable` for GoRouter's redirect logic.
class AuthProvider extends ChangeNotifier {
  AuthProvider({AuthService? authService}) : _authService = authService ?? AuthService() {
    _restoreSession();
  }

  final AuthService _authService;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> _restoreSession() async {
    final loggedIn = await StorageService.instance.isLoggedIn();
    _status = loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    return _runGuarded(() async {
      final result = await _authService.login(email: email, password: password);
      // Dev-auth issues a DRF token — sent as "Token <key>".
      await StorageService.instance.saveAuthToken(result.token, scheme: 'Token');
      await StorageService.instance.saveUserId(result.user.id);
      _user = result.user;
      _status = AuthStatus.authenticated;
    });
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    return _runGuarded(() async {
      final result = await _authService.register(
        fullName: fullName,
        email: email,
        phone: phone,
        password: password,
      );
      // Dev-auth: backend returns a token immediately, user logs in right away.
      await StorageService.instance.saveAuthToken(result.token, scheme: 'Token');
      await StorageService.instance.saveUserId(result.user.id);
      _user = result.user;
      _status = AuthStatus.authenticated;
    });
  }

  /// Signs in with Google via Firebase. The resulting Firebase ID token is
  /// sent as `Bearer <token>` and verified server-side by
  /// apps.core.firebase_auth.FirebaseAuthentication.
  Future<bool> loginWithGoogle() async {
    return _runGuarded(() async {
      final result = await _authService.signInWithGoogle();
      await StorageService.instance.saveAuthToken(result.token, scheme: 'Bearer');
      await StorageService.instance.saveUserId(result.user.id);
      _user = result.user;
      _status = AuthStatus.authenticated;
    });
  }

  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    return _runGuarded(() async {
      await _authService.resetPassword(
        email: email,
        newPassword: newPassword,
      );
    });
  }

  Future<void> logout() async {

    _isLoading = true;
    notifyListeners();
    await _authService.logout();
    await StorageService.instance.clearSession();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Refreshes the in-memory user after a profile edit.
  /// Call after a successful PATCH to /accounts/me/ or /auth/dev-me/.
  void updateUser({String? fullName, String? phone, String? avatarUrl}) {
    if (_user == null) return;
    _user = _user!.copyWith(
      fullName: fullName,
      phone: phone,
      avatarUrl: avatarUrl,
    );
    notifyListeners();
  }

  /// Runs [action], toggling loading state and capturing any error in
  /// [errorMessage]. Returns `true` on success, `false` otherwise.
  Future<bool> _runGuarded(Future<void> Function() action) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await action();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
