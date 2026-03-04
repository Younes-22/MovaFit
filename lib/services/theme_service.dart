import 'package:flutter/material.dart';

// A simple service to manage Theme Mode globally
class ThemeService {
  // Singleton pattern to ensure easy access
  static final ThemeService _instance = ThemeService._internal();
  factory ThemeService() => _instance;
  ThemeService._internal();

  // The state (Defaults to System, but we can toggle it)
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  void toggleTheme(bool isDark) {
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool get isDarkMode => themeMode.value == ThemeMode.dark;
}