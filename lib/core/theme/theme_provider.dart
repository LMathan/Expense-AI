import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  static const _boxName = 'settings';
  static const _key = 'theme_mode';

  void _loadTheme() {
    try {
      final box = Hive.box(_boxName);
      final mode = box.get(_key);
      if (mode == 'light') {
        state = ThemeMode.light;
      } else {
        state = ThemeMode.dark;
      }
    } catch (_) {
      state = ThemeMode.dark;
    }
  }

  void toggleTheme() {
    try {
      final box = Hive.box(_boxName);
      if (state == ThemeMode.dark) {
        state = ThemeMode.light;
        box.put(_key, 'light');
      } else {
        state = ThemeMode.dark;
        box.put(_key, 'dark');
      }
    } catch (_) {
      state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    }
  }
}
