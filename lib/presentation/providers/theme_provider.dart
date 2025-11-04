import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ✅ ACTUALIZADO: AsyncNotifier para cargar tema correctamente antes de build
class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    // Cargar tema guardado de forma asíncrona ANTES de retornar
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Cambiar el tema y persistirlo
  Future<void> setThemeMode(ThemeMode mode) async {
    // Actualizar estado inmediatamente (optimistic update)
    state = AsyncData(mode);

    // Persistir en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', mode == ThemeMode.dark);
  }

  /// Alternar entre claro y oscuro
  Future<void> toggleTheme() async {
    final currentMode = state.value ?? ThemeMode.light;
    final newMode = currentMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }
}

/// Provider para el modo de tema (AsyncNotifier)
final themeModeProvider = AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(
  () {
    return ThemeModeNotifier();
  },
);
