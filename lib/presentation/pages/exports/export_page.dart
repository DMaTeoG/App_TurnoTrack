import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/export_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/users_provider.dart';

/// Página de exportación de datos
///
/// Permite exportar usuarios a CSV y compartir el archivo
/// Usa ExportService (sin Edge Functions, simple)
class ExportPage extends ConsumerWidget {
  const ExportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exportar Datos'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.info_outline, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Text(
                          'Exportar Datos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Los datos se exportarán en formato CSV y podrás '
                      'compartirlos usando WhatsApp, Email, Drive, etc.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Card de exportación de usuarios
            _ExportCard(
              title: 'Usuarios',
              subtitle: 'Exportar lista completa de usuarios',
              icon: Icons.people,
              color: Colors.blue,
              itemCount: usersAsync.maybeWhen(
                data: (users) => users.length,
                orElse: () => 0,
              ),
              onExport: () async {
                final users = await ref.read(allUsersListProvider.future);
                await _exportUsers(context, users);
              },
              isLoading: usersAsync.isLoading,
            ),

            const SizedBox(height: 12),

            // Card de asistencias (TODO)
            _ExportCard(
              title: 'Asistencias',
              subtitle: 'Próximamente',
              icon: Icons.access_time,
              color: Colors.green,
              itemCount: 0,
              onExport: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente disponible')),
                );
              },
              isLoading: false,
            ),

            const SizedBox(height: 12),

            // Card de métricas (TODO)
            _ExportCard(
              title: 'Métricas de Rendimiento',
              subtitle: 'Próximamente',
              icon: Icons.bar_chart,
              color: Colors.orange,
              itemCount: 0,
              onExport: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Próximamente disponible')),
                );
              },
              isLoading: false,
            ),

            const Spacer(),

            // Botón de limpiar archivos antiguos
            OutlinedButton.icon(
              onPressed: () async {
                await _cleanOldExports(context);
              },
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Limpiar exportaciones antiguas (>7 días)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportUsers(BuildContext context, List<dynamic> users) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Exportar (casting a List<UserModel>)
      final filePath = await ExportService.exportUsersToCSV(users.cast());
      final fileInfo = await ExportService.getFileInfo(filePath);

      // Cerrar loading
      if (context.mounted) {
        Navigator.of(context).pop();

        // Mostrar éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Exportado exitosamente\n'
              'Archivo: ${fileInfo.name}\n'
              'Tamaño: ${fileInfo.sizeFormatted}\n'
              'Registros: ${users.length}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      // Cerrar loading si está abierto
      if (context.mounted) {
        Navigator.of(context).pop();

        // Mostrar error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _cleanOldExports(BuildContext context) async {
    try {
      await ExportService.cleanOldExports();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Archivos antiguos eliminados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error limpiando archivos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Widget de card de exportación
class _ExportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final int itemCount;
  final VoidCallback onExport;
  final bool isLoading;

  const _ExportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.itemCount,
    required this.onExport,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: isLoading ? null : onExport,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),

              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (itemCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$itemCount registros',
                        style: TextStyle(
                          fontSize: 12,
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Botón o loading
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.file_download, color: color, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
