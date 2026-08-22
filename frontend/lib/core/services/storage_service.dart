import 'package:shared_preferences/shared_preferences.dart';

/// Wraps [SharedPreferences] so the rest of the app never touches the
/// plugin directly. Keeps key names in one place and exposes typed,
/// intention-revealing methods.
class StorageService {
  StorageService._internal();
  static final StorageService instance = StorageService._internal();

  static const _keyAuthToken = 'auth_token';
  static const _keyAuthScheme = 'auth_scheme'; // 'Token' (dev-auth) | 'Bearer' (Firebase)
  static const _keyUserId = 'user_id';
  static const _keyIsLoggedIn = 'is_logged_in';
  static const _keyThemeMode = 'theme_mode'; // 'light' | 'dark' | 'system'
  static const _keyOnboardingSeen = 'onboarding_seen';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  // ---- Auth ------------------------------------------------------------

  Future<void> saveAuthToken(String token, {String scheme = 'Token'}) async {
    final prefs = await _prefs;
    await prefs.setString(_keyAuthToken, token);
    await prefs.setString(_keyAuthScheme, scheme);
    await prefs.setBool(_keyIsLoggedIn, true);
  }

  Future<String?> getAuthToken() async {
    final prefs = await _prefs;
    return prefs.getString(_keyAuthToken);
  }

  /// 'Token' for DRF dev-auth, 'Bearer' for Firebase ID tokens.
  Future<String> getAuthScheme() async {
    final prefs = await _prefs;
    return prefs.getString(_keyAuthScheme) ?? 'Token';
  }

  Future<void> saveUserId(String userId) async {
    final prefs = await _prefs;
    await prefs.setString(_keyUserId, userId);
  }

  Future<String?> getUserId() async {
    final prefs = await _prefs;
    return prefs.getString(_keyUserId);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyAuthScheme);
    await prefs.remove(_keyUserId);
    await prefs.setBool(_keyIsLoggedIn, false);
  }

  // ---- Preferences -------------------------------------------------------

  Future<void> saveThemeMode(String mode) async {
    final prefs = await _prefs;
    await prefs.setString(_keyThemeMode, mode);
  }

  Future<String?> getThemeMode() async {
    final prefs = await _prefs;
    return prefs.getString(_keyThemeMode);
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await _prefs;
    await prefs.setBool(_keyOnboardingSeen, true);
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await _prefs;
    return prefs.getBool(_keyOnboardingSeen) ?? false;
  }
}
