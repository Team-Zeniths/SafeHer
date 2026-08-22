import 'package:flutter/material.dart';
import '../core/services/storage_service.dart';

/// Controls the app-wide [ThemeMode] and persists the user's choice
/// so it survives app restarts.
class ThemeProvider extends ChangeNotifier {
  ThemeProvider() {
    _loadSavedTheme();
  }

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> _loadSavedTheme() async {
    final saved = await StorageService.instance.getThemeMode();
    switch (saved) {
      case 'light':
        _themeMode = ThemeMode.light;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    await StorageService.instance.saveThemeMode(mode.name);
  }

  Future<void> toggleTheme() async {
    final next = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }
}
