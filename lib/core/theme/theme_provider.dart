import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class AppStateNotifier extends ChangeNotifier {
  static final AppStateNotifier instance = AppStateNotifier._internal();
  AppStateNotifier._internal();

  ThemeMode _themeMode = ThemeMode.light;
  String _currentLanguage = 'English';

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get currentLanguage => _currentLanguage;

  Future<void> init() async {
    try {
      final box = Hive.isBoxOpen('app_settings')
          ? Hive.box('app_settings')
          : await Hive.openBox('app_settings');
      final savedTheme = box.get('theme_mode', defaultValue: 'light') as String;
      _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;
      _currentLanguage = box.get('language', defaultValue: 'English') as String;
      notifyListeners();
    } catch (_) {
      // Keep defaults if error occurs
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _persistSettings();
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _persistSettings();
    notifyListeners();
  }

  void setLanguage(String language) {
    _currentLanguage = language;
    _persistSettings();
    notifyListeners();
  }

  void _persistSettings() {
    try {
      if (Hive.isBoxOpen('app_settings')) {
        final box = Hive.box('app_settings');
        box.put('theme_mode', _themeMode == ThemeMode.dark ? 'dark' : 'light');
        box.put('language', _currentLanguage);
      }
    } catch (_) {}
  }
}
