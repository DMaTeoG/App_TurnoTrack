import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notifier para gestionar el estado de notificaciones
class NotificationsEnabledNotifier extends Notifier<bool> {
  @override
  bool build() {
    _loadSavedPreference();
    return true; // Por defecto activadas
  }

  Future<void> _loadSavedPreference() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('notificationsEnabled') ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notificationsEnabled', enabled);
  }

  Future<void> toggle() async {
    await setEnabled(!state);
  }
}

/// Provider para el estado de notificaciones
final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabledNotifier, bool>(() {
      return NotificationsEnabledNotifier();
    });
