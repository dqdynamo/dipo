import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('isDarkTheme') ?? false;
    notifyListeners();
  }

  void toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = value;
    await prefs.setBool('isDarkTheme', value);
    notifyListeners();
  }
}
