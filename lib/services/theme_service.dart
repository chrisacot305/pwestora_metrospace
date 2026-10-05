import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage app-wide ThemeMode (Light, Dark, System)
/// with persistence via SharedPreferences.
class ThemeService {
  static const String _prefKey = 'pwestora_theme_mode';

  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier<ThemeMode>(ThemeMode.light);

  /// Initialize and load saved theme preference (defaults to light mode)
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_prefKey);
      if (savedMode == 'dark') {
        themeModeNotifier.value = ThemeMode.dark;
      } else {
        themeModeNotifier.value = ThemeMode.light;
      }
    } catch (_) {
      themeModeNotifier.value = ThemeMode.light;
    }
  }

  /// Change theme mode and persist to storage
  static Future<void> setThemeMode(ThemeMode mode) async {
    themeModeNotifier.value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.dark) {
        await prefs.setString(_prefKey, 'dark');
      } else if (mode == ThemeMode.light) {
        await prefs.setString(_prefKey, 'light');
      } else {
        await prefs.remove(_prefKey);
      }
    } catch (_) {}
  }

  /// Toggle between Light and Dark mode
  static Future<void> toggle(BuildContext context) async {
    final isCurrentlyDark = isDark(context);
    await setThemeMode(isCurrentlyDark ? ThemeMode.light : ThemeMode.dark);
  }

  /// Check whether the current effective appearance is dark
  static bool isDark(BuildContext context) {
    return themeModeNotifier.value == ThemeMode.dark;
  }
}
