import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notifications_settings_provider.dart';

/// Pantalla de ajustes de la aplicación
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedLanguage = 'es';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final notificationsEnabled = ref.watch(notificationsEnabledProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes'), elevation: 0),
      body: ListView(
        children: [
          // Apariencia
          _buildSection(
            context,
            icon: Icons.palette,
            title: 'Apariencia',
            children: [_buildThemeSwitch(theme, themeMode)],
          ),

          const Divider(height: 1),

          // Notificaciones
          _buildSection(
            context,
            icon: Icons.notifications,
            title: 'Notificaciones',
            children: [_buildNotificationsSwitch(theme, notificationsEnabled)],
          ),

          const Divider(height: 1),

          // Idioma
          _buildSection(
            context,
            icon: Icons.language,
            title: 'Idioma',
            children: [_buildLanguageSelector(theme)],
          ),

          const Divider(height: 1),

          // Sesión
          _buildSection(
            context,
            icon: Icons.logout,
            title: 'Sesión',
            children: [_buildLogoutButton(theme)],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildThemeSwitch(ThemeData theme, ThemeMode themeMode) {
    return SwitchListTile(
      title: const Text('Modo Oscuro'),
      subtitle: Text(themeMode == ThemeMode.dark ? 'Activado' : 'Desactivado'),
      value: themeMode == ThemeMode.dark,
      onChanged: (value) {
        ref
            .read(themeModeProvider.notifier)
            .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
      },
      secondary: Icon(
        themeMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
      ),
    );
  }

  Widget _buildNotificationsSwitch(ThemeData theme, bool enabled) {
    return SwitchListTile(
      title: const Text('Notificaciones'),
      subtitle: Text(
        enabled
            ? 'Recordatorios de entrada/salida activos'
            : 'Todas las notificaciones desactivadas',
      ),
      value: enabled,
      onChanged: (value) async {
        await ref.read(notificationsEnabledProvider.notifier).setEnabled(value);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                value
                    ? 'Notificaciones activadas'
                    : 'Notificaciones desactivadas',
              ),
            ),
          );
        }
      },
      secondary: Icon(
        enabled ? Icons.notifications_active : Icons.notifications_off,
      ),
    );
  }

  Widget _buildLanguageSelector(ThemeData theme) {
    return Column(
      children: [
        RadioListTile<String>(
          title: const Text('Español'),
          value: 'es',
          groupValue: _selectedLanguage,
          onChanged: (value) {
            setState(() => _selectedLanguage = value!);
            // TODO: Implementar cambio de idioma con i18n
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Idioma cambiado a Español')),
            );
          },
        ),
        RadioListTile<String>(
          title: const Text('English'),
          value: 'en',
          groupValue: _selectedLanguage,
          onChanged: (value) {
            setState(() => _selectedLanguage = value!);
            // TODO: Implementar cambio de idioma con i18n
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Language changed to English')),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLogoutButton(ThemeData theme) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: const Text('Cerrar Sesión', style: TextStyle(color: Colors.red)),
      onTap: () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        );

        if (confirm == true && mounted) {
          await ref.read(authNotifierProvider.notifier).signOut();
          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      },
    );
  }
}
