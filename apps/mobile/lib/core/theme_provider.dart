import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'theme_mode';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final initial = ref.read(initialThemeModeProvider);
    return initial;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, mode.name);
  }
}

/// Synchronously read the persisted theme before the first frame renders.
/// Called once in `mainCommon()` and injected via ProviderScope.
final initialThemeModeProvider = Provider<ThemeMode>((ref) {
  throw UnimplementedError(
    'initialThemeModeProvider must be overridden in ProviderScope',
  );
});

Future<ThemeMode> loadPersistedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final value = prefs.getString(_kThemeKey);
  if (value == 'dark') return ThemeMode.dark;
  return ThemeMode.light;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
