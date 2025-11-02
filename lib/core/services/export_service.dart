import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/user_model.dart';

/// Servicio de exportación de datos sin Edge Functions
///
/// Exporta datos del lado del cliente a CSV y permite compartir
/// los archivos generados usando el sistema nativo de compartir.
///
/// **Ventajas:**
/// - No requiere Supabase CLI
/// - No requiere Edge Functions
/// - Funciona offline
/// - Simple y directo
///
/// **Desventajas:**
/// - Procesa datos en el dispositivo
/// - Límite de registros según memoria
class ExportService {
  /// Exportar lista de usuarios a CSV
  ///
  /// Genera archivo con columnas:
  /// - ID, Nombre, Email, Rol, Teléfono, Activo, Fecha Creación
  ///
  /// Retorna la ruta del archivo generado
  static Future<String> exportUsersToCSV(List<UserModel> users) async {
    try {
      // Preparar filas CSV
      final rows = [
        // Header
        [
          'ID',
          'Nombre Completo',
          'Email',
          'Rol',
          'Activo',
          'Supervisor ID',
          'URL Foto',
          'Fecha Creación',
          'Última Actualización',
        ],
        // Datos
        ...users.map(
          (user) => [
            user.id,
            user.fullName,
            user.email,
            user.role.toUpperCase(),
            user.isActive ? 'Sí' : 'No',
            user.supervisorId ?? '',
            user.photoUrl ?? '',
            user.createdAt?.toIso8601String() ?? '',
            user.updatedAt?.toIso8601String() ?? '',
          ],
        ),
      ];

      // Convertir a CSV
      final csv = const ListToCsvConverter().convert(rows);

      // Obtener directorio de documentos
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'turnotrack_usuarios_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';

      // Guardar archivo
      final file = File(filePath);
      await file.writeAsString(csv, encoding: utf8);

      // Compartir archivo
      await Share.shareXFiles(
        [XFile(filePath)],
        text:
            'Exportación de usuarios - TurnoTrack\n'
            'Total de registros: ${users.length}\n'
            'Generado: ${DateTime.now().toString().split('.')[0]}',
        subject: 'Usuarios TurnoTrack',
      );

      return filePath;
    } catch (e) {
      throw Exception('Error exportando usuarios a CSV: $e');
    }
  }

  /// Exportar asistencias a CSV
  static Future<String> exportAttendanceToCSV(
    List<AttendanceModel> attendances,
  ) async {
    try {
      final rows = [
        // Header
        [
          'ID',
          'Usuario ID',
          'Fecha Entrada',
          'Hora Entrada',
          'Fecha Salida',
          'Hora Salida',
          'Tardanza (min)',
          'Tardío',
          'Dirección Entrada',
          'Dirección Salida',
          'Latitud Entrada',
          'Longitud Entrada',
          'Latitud Salida',
          'Longitud Salida',
        ],
        // Datos
        ...attendances.map(
          (attendance) => [
            attendance.id,
            attendance.userId,
            attendance.checkInTime.toLocal().toString().split(' ')[0],
            attendance.checkInTime
                .toLocal()
                .toString()
                .split(' ')[1]
                .split('.')[0],
            attendance.checkOutTime?.toLocal().toString().split(' ')[0] ??
                'N/A',
            attendance.checkOutTime
                    ?.toLocal()
                    .toString()
                    .split(' ')[1]
                    .split('.')[0] ??
                'N/A',
            attendance.minutesLate.toString(),
            attendance.isLate ? 'Sí' : 'No',
            attendance.checkInAddress ?? '',
            attendance.checkOutAddress ?? '',
            attendance.checkInLatitude.toString(),
            attendance.checkInLongitude.toString(),
            attendance.checkOutLatitude?.toString() ?? '',
            attendance.checkOutLongitude?.toString() ?? '',
          ],
        ),
      ];

      final csv = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'turnotrack_asistencias_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csv, encoding: utf8);

      await Share.shareXFiles(
        [XFile(filePath)],
        text:
            'Exportación de asistencias - TurnoTrack\n'
            'Total de registros: ${attendances.length}\n'
            'Generado: ${DateTime.now().toString().split('.')[0]}',
        subject: 'Asistencias TurnoTrack',
      );

      return filePath;
    } catch (e) {
      throw Exception('Error exportando asistencias a CSV: $e');
    }
  }

  /// Exportar métricas de rendimiento a CSV
  static Future<String> exportPerformanceToCSV(
    List<PerformanceMetrics> metrics,
  ) async {
    try {
      final rows = [
        // Header
        [
          'Usuario ID',
          'Período Inicio',
          'Período Fin',
          'Score de Asistencia',
          'Total Check-ins',
          'Check-ins Tarde',
          'Hora Promedio Entrada',
          'Ranking',
        ],
        // Datos
        ...metrics.map(
          (metric) => [
            metric.userId,
            metric.periodStart.toLocal().toString().split(' ')[0],
            metric.periodEnd.toLocal().toString().split(' ')[0],
            metric.attendanceScore.toString(),
            metric.totalCheckIns.toString(),
            metric.lateCheckIns.toString(),
            metric.averageCheckInTime.toStringAsFixed(2),
            metric.ranking?.toString() ?? 'N/A',
          ],
        ),
      ];

      final csv = const ListToCsvConverter().convert(rows);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'turnotrack_performance_$timestamp.csv';
      final filePath = '${directory.path}/$fileName';

      final file = File(filePath);
      await file.writeAsString(csv, encoding: utf8);

      await Share.shareXFiles(
        [XFile(filePath)],
        text:
            'Exportación de métricas de rendimiento - TurnoTrack\n'
            'Total de registros: ${metrics.length}\n'
            'Generado: ${DateTime.now().toString().split('.')[0]}',
        subject: 'Métricas TurnoTrack',
      );

      return filePath;
    } catch (e) {
      throw Exception('Error exportando métricas a CSV: $e');
    }
  }

  /// Obtener información de un archivo exportado
  static Future<ExportFileInfo> getFileInfo(String filePath) async {
    try {
      final file = File(filePath);
      final exists = await file.exists();

      if (!exists) {
        throw Exception('Archivo no encontrado: $filePath');
      }

      final stat = await file.stat();
      final sizeKB = stat.size / 1024;

      return ExportFileInfo(
        path: filePath,
        name: filePath.split('/').last,
        sizeKB: sizeKB,
        createdAt: stat.modified,
      );
    } catch (e) {
      throw Exception('Error obteniendo información del archivo: $e');
    }
  }

  /// Eliminar archivo exportado
  static Future<void> deleteExportFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      throw Exception('Error eliminando archivo: $e');
    }
  }

  /// Limpiar archivos de exportación antiguos (más de 7 días)
  static Future<void> cleanOldExports() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final files = directory.listSync();
      final now = DateTime.now();

      for (var file in files) {
        if (file.path.contains('turnotrack_') && file.path.endsWith('.csv')) {
          final stat = await file.stat();
          final age = now.difference(stat.modified).inDays;

          if (age > 7) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      // Silencioso, no crítico en producción
      debugPrint('Error limpiando exportaciones antiguas: $e');
    }
  }
}

/// Información de un archivo exportado
class ExportFileInfo {
  final String path;
  final String name;
  final double sizeKB;
  final DateTime createdAt;

  ExportFileInfo({
    required this.path,
    required this.name,
    required this.sizeKB,
    required this.createdAt,
  });

  String get sizeMB => (sizeKB / 1024).toStringAsFixed(2);
  String get sizeFormatted =>
      sizeKB < 1024 ? '${sizeKB.toStringAsFixed(2)} KB' : '$sizeMB MB';

  @override
  String toString() {
    return 'ExportFileInfo(name: $name, size: $sizeFormatted, created: $createdAt)';
  }
}
