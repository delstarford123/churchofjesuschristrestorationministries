import 'package:flutter/material.dart';

class AppStateNotifier extends ChangeNotifier {
  static final AppStateNotifier instance = AppStateNotifier._internal();
  AppStateNotifier._internal();

  ThemeMode _themeMode = ThemeMode.light;
  String _currentLanguage = 'English';

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  String get currentLanguage => _currentLanguage;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  void setLanguage(String language) {
    _currentLanguage = language;
    notifyListeners();
  }
}
