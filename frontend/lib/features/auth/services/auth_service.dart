import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import '../../../constants.dart';
import '../../../models/user_model.dart';

/// Handles all network calls for the authentication feature.
///
/// Email/password goes through the Django dev-auth endpoints directly.
/// Google Sign-In goes through Firebase Auth, then syncs the resulting
/// profile to the backend (which verifies the Firebase ID token itself
/// via apps.core.firebase_auth.FirebaseAuthentication).
class AuthService {
  AuthService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );
  }

  late final Dio _dio;

  // ── Register ─────────────────────────────────────────────────────────────

  /// Creates a new account on the backend.
  /// Returns (token, user) immediately — dev mode logs the user in right away.
  Future<({String token, UserModel user})> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        'auth/dev-register/',
        data: {
          'email': email,
          'password': password,
          'full_name': fullName,
          'phone': phone,
        },
      );
      return _parseAuthResponse(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  // ── Login ────────────────────────────────────────────────────────────────

  Future<({String token, UserModel user})> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        'auth/dev-login/',
        data: {'email': email, 'password': password},
      );
      return _parseAuthResponse(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  // ── Google Sign-In (via Firebase) ────────────────────────────────────────

  /// Signs in with Google via Firebase Auth, then syncs the profile to the
  /// backend. Returns a Bearer-scheme Firebase ID token (not a DRF token) —
  /// callers must store it as such so [ApiService] sends the right header.
  Future<({String token, UserModel user})> signInWithGoogle() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      // User cancelled the picker.
      throw Exception('Google sign-in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await fb.FirebaseAuth.instance.signInWithCredential(credential);
    final firebaseUser = userCredential.user;
    if (firebaseUser == null) {
      throw Exception('Firebase sign-in did not return a user.');
    }

    final idToken = await firebaseUser.getIdToken();
    if (idToken == null) {
      throw Exception('Could not obtain a Firebase ID token.');
    }

    // Sync display name to the backend profile (best-effort, fire-and-forget —
    // profile row is created lazily by FirebaseAuthentication on first request,
    // and login shouldn't wait on this network round-trip to complete).
    unawaited(
      _dio
          .patch(
            'accounts/me/',
            data: {
              if (firebaseUser.displayName != null)
                'display_name': firebaseUser.displayName,
            },
            options: Options(headers: {'Authorization': 'Bearer $idToken'}),
          )
          .catchError((_) => Response(requestOptions: RequestOptions(path: 'accounts/me/'))),
    );

    final user = UserModel(
      id: firebaseUser.uid,
      fullName: firebaseUser.displayName ?? '',
      email: firebaseUser.email ?? '',
      phone: firebaseUser.phoneNumber ?? '',
      isVerified: true,
    );

    return (token: idToken, user: user);
  }

  // ── Reset Password ───────────────────────────────────────────────────────

  Future<String> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        'auth/dev-reset-password/',
        data: {
          'email': email,
          'password': newPassword,
        },
      );
      final data = response.data;
      if (data is Map && data.containsKey('detail')) {
        return data['detail'] as String;
      }
      return 'Password has been reset successfully.';
    } on DioException catch (e) {
      throw Exception(_extractError(e));
    }
  }

  // ── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    // Best-effort — clear whichever session type is active.
    try {
      await fb.FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {
      // No Firebase/Google session was active (dev-auth login) — fine.
    }
  }


  // ── Helpers ───────────────────────────────────────────────────────────────

  ({String token, UserModel user}) _parseAuthResponse(Map<String, dynamic> data) {
    final userJson = data['user'] as Map<String, dynamic>;
    final user = UserModel(
      id: userJson['id']?.toString() ?? '',
      fullName: userJson['full_name'] as String? ?? '',
      email: userJson['email'] as String? ?? '',
      phone: userJson['phone'] as String? ?? '',
      isVerified: userJson['is_verified'] as bool? ?? false,
    );
    return (token: data['token'] as String, user: user);
  }

  String _extractError(DioException e) {
    final data = e.response?.data;
    if (data is Map && data.containsKey('detail')) {
      return data['detail'] as String;
    }
    return e.message ?? 'Network error — check your connection.';
  }
}
