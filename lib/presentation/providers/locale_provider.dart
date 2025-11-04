import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AsyncNotifier para gestionar el idioma de la app
class LocaleNotifier extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    // Cargar idioma guardado de forma asíncrona
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'es';
    return Locale(languageCode);
  }

  /// Cambiar el idioma y persistirlo
  Future<void> setLocale(Locale locale) async {
    // Actualizar estado inmediatamente
    state = AsyncData(locale);

    // Persistir en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
  }

  /// Alternar entre español e inglés
  Future<void> toggleLocale() async {
    final currentLocale = state.value ?? const Locale('es');
    final newLocale = currentLocale.languageCode == 'es'
        ? const Locale('en')
        : const Locale('es');
    await setLocale(newLocale);
  }
}

/// Provider para el idioma de la app
final localeProvider = AsyncNotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});
