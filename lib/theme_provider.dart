import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {light, dark, blue}

class ThemeProvider extends ChangeNotifier {
  AppTheme _currentTheme = AppTheme.blue;
  static const String _themeKey = 'app_theme';

  AppTheme get currentTheme => _currentTheme;

  ThemeProvider() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_themeKey) ?? 2;
    _currentTheme = AppTheme.values[index];
    notifyListeners();
  }

  Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
    notifyListeners();
  }

  ThemeData getThemeData() {
    switch (_currentTheme) {
      case AppTheme.light:
        return ThemeData.light().copyWith(primaryColor: Colors.blue);
      case AppTheme.dark:
        return ThemeData.dark().copyWith(primaryColor: Colors.blue);
      case AppTheme.blue:
        return ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        );
    }
  }
}