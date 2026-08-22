import 'package:flutter/foundation.dart';

/// Centralized API configuration.
///
/// IMPORTANT:
/// - Android emulator: use --dart-define=API_URL=http://10.0.2.2:8000/api/v1/
/// - Physical phone on the same Wi-Fi: use your computer's current LAN IP.
/// - Web: by default use the browser's current host, so it is not tied to
///   127.0.0.1 or one LAN address.
/// - RELEASE BUILD (deployed backend): you MUST pass
///   --dart-define=API_URL=https://your-app.onrender.com/api/v1/
///   at build time — physicalDeviceUrl below is a local dev address and
///   will NOT work once you're not on the same Wi-Fi as this PC.
class ApiConfig {
  static const String emulatorUrl = 'http://10.0.2.2:8000/api/v1/';
  static const String localhostUrl = 'http://127.0.0.1:8000/api/v1/';

  /// Your PC's LAN IP, for testing on a physical phone over Wi-Fi.
  /// Both devices must be on the same network, and Django must be run with:
  ///   python manage.py runserver 0.0.0.0:8000
  static const String physicalDeviceUrl = 'http://172.23.195.140:8000/api/v1/';

  /// Set this at runtime if you need a temporary override.
  static String? customBaseUrl;

  static String get baseUrl {
    if (customBaseUrl != null && customBaseUrl!.trim().isNotEmpty) {
      return _normalize(customBaseUrl!);
    }

    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) {
      return _normalize(envUrl);
    }

    if (kIsWeb) {
      // Flutter Web runs on dynamic dev ports (e.g. 34795), but Django backend is on port 8000.
      final host = Uri.base.host.isEmpty ? '127.0.0.1' : Uri.base.host;
      return 'http://$host:8000/api/v1/';
    }

    // Physical Android/iOS devices cannot discover your development PC's
    // LAN IP reliably, so this defaults to it directly rather than to the
    // emulator-only 10.0.2.2 address. Update physicalDeviceUrl above if
    // your PC's IP changes, or pass --dart-define=API_URL=... to override
    // without editing this file.
    return physicalDeviceUrl;
  }

  static String _normalize(String url) {
    return url.endsWith('/') ? url : '$url/';
  }
}
