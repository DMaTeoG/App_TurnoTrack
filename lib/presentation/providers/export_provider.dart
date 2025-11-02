import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/export_service.dart';
import '../../data/models/user_model.dart';

/// Provider para el servicio de exportación
final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService();
});

/// Estados de exportación
sealed class ExportState {
  const ExportState();
}

class ExportInitial extends ExportState {
  const ExportInitial();
}

class ExportLoading extends ExportState {
  const ExportLoading();
}

class ExportSuccess extends ExportState {
  final String filePath;
  final String message;
  const ExportSuccess({required this.filePath, required this.message});
}

class ExportError extends ExportState {
  final String message;
  const ExportError(this.message);
}

/// Notifier para manejar exportaciones
class ExportNotifier extends Notifier<ExportState> {
  @override
  ExportState build() {
    return const ExportInitial();
  }

  /// Exportar usuarios
  Future<void> exportUsers(List<UserModel> users) async {
    state = const ExportLoading();
    try {
      final filePath = await ExportService.exportUsersToCSV(users);
      state = ExportSuccess(
        filePath: filePath,
        message: 'Usuarios exportados exitosamente',
      );
    } catch (e) {
      state = ExportError('Error exportando usuarios: ${e.toString()}');
    }
  }

  /// Exportar asistencias
  Future<void> exportAttendance(List<AttendanceModel> attendances) async {
    state = const ExportLoading();
    try {
      final filePath = await ExportService.exportAttendanceToCSV(attendances);
      state = ExportSuccess(
        filePath: filePath,
        message: 'Asistencias exportadas exitosamente',
      );
    } catch (e) {
      state = ExportError('Error exportando asistencias: ${e.toString()}');
    }
  }

  /// Exportar métricas de rendimiento
  Future<void> exportPerformance(List<PerformanceMetrics> metrics) async {
    state = const ExportLoading();
    try {
      final filePath = await ExportService.exportPerformanceToCSV(metrics);
      state = ExportSuccess(
        filePath: filePath,
        message: 'Métricas exportadas exitosamente',
      );
    } catch (e) {
      state = ExportError('Error exportando métricas: ${e.toString()}');
    }
  }

  /// Resetear estado
  void reset() {
    state = const ExportInitial();
  }
}

/// Provider para el notifier de exportación
final exportNotifierProvider = NotifierProvider<ExportNotifier, ExportState>(
  ExportNotifier.new,
);
