
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
bool _isDarkMode = false;

bool get isDarkMode => _isDarkMode;
ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

Future<void> loadSavedTheme() async {
final prefs = await SharedPreferences.getInstance();
_isDarkMode = prefs.getBool('dark_mode') ?? false;
notifyListeners();
}

Future<void> setDarkMode(bool value) async {
_isDarkMode = value;
notifyListeners();
final prefs = await SharedPreferences.getInstance();
await prefs.setBool('dark_mode', value);
}
}