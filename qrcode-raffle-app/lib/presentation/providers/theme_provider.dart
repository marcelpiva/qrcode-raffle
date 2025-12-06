import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode provider with persistence
/// Default is dark mode to match web app
class ThemeNotifier extends StateNotifier<ThemeMode> {
  static const String _themeKey = 'theme_mode';

  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeString = prefs.getString(_themeKey);
      if (themeString != null) {
        state = ThemeMode.values.firstWhere(
          (e) => e.name == themeString,
          orElse: () => ThemeMode.dark,
        );
      }
    } catch (e) {
      // Keep default (dark)
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeKey, mode.name);
    } catch (e) {
      // Ignore persistence errors
    }
  }

  void toggleTheme() {
    setThemeMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  bool get isDark => state == ThemeMode.dark;
  bool get isLight => state == ThemeMode.light;
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

/// Provider for checking if current theme is dark
final isDarkModeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider);
  return themeMode == ThemeMode.dark;
});
