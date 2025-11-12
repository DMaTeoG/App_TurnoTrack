import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/repositories/i_attendance_repository.dart';
import '../../core/services/location_service.dart';
import '../../core/services/camera_service.dart';
import 'auth_provider.dart';
import 'notification_provider.dart';

// Provider de servicios
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

// Provider del repositorio de asistencias
final attendanceRepositoryProvider = Provider<IAttendanceRepository>((ref) {
  final datasource = ref.read(supabaseDatasourceProvider);
  return AttendanceRepositoryImpl(datasource);
});

// Provider de ubicaciones permitidas activas
final allowedLocationsProvider = FutureProvider<List<LocationModel>>((
  ref,
) async {
  final datasource = ref.read(supabaseDatasourceProvider);
  return await datasource.getActiveLocations();
});

// Notifier para gestionar asistencias
class AttendanceNotifier extends AsyncNotifier<List<AttendanceModel>> {
  late IAttendanceRepository _repository;

  @override
  Future<List<AttendanceModel>> build() async {
    _repository = ref.read(attendanceRepositoryProvider);

    final user = ref.read(authNotifierProvider).value;
    if (user == null) return [];

    try {
      return await _repository.getAttendanceByUser(userId: user.id);
    } catch (e) {
      // Supabase maneja offline automáticamente
      return [];
    }
  }

  /// Registrar entrada (check-in) - SIN validación de radio
  Future<void> checkIn({
    required File photoFile,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final user = ref.read(authNotifierProvider).value;
    if (user == null) throw Exception('Usuario no autenticado');

    state = const AsyncValue.loading();

    try {
      // 1. Subir foto a Supabase Storage
      final photoUrl = await _repository.uploadPhoto(photoFile.path);

      // 2. Check-in via repository (sin validación de radio)
      await _repository.checkIn(
        userId: user.id,
        latitude: latitude,
        longitude: longitude,
        photoUrl: photoUrl,
        address: address,
      );

      // Notificar éxito
      ref.read(notificationNotifierProvider.notifier).notifyCheckIn();

      // Recargar lista
      state = await AsyncValue.guard(() => build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Registrar salida (check-out)
  Future<void> checkOut({
    required File photoFile,
    required double latitude,
    required double longitude,
    String? address,
  }) async {
    final user = ref.read(authNotifierProvider).value;
    if (user == null) throw Exception('Usuario no autenticado');

    state = const AsyncValue.loading();

    try {
      // Subir foto y crear check-out via repository
      final photoUrl = await _repository.uploadPhoto(photoFile.path);

      await _repository.checkOut(
        userId: user.id,
        latitude: latitude,
        longitude: longitude,
        photoUrl: photoUrl,
        address: address,
      );

      ref.read(notificationNotifierProvider.notifier).notifyCheckOut();

      state = await AsyncValue.guard(() => build());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Obtener última asistencia del día
  AttendanceModel? get todayLastAttendance {
    final list = state.value ?? [];
    if (list.isEmpty) return null;

    final today = DateTime.now();
    final todayAttendances = list.where((a) {
      return a.checkInTime.year == today.year &&
          a.checkInTime.month == today.month &&
          a.checkInTime.day == today.day;
    }).toList();

    if (todayAttendances.isEmpty) return null;
    todayAttendances.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
    return todayAttendances.first;
  }

  /// Verificar si ya hizo check-in hoy
  bool get hasCheckedInToday {
    final last = todayLastAttendance;
    return last != null && last.checkOutTime == null;
  }

  /// Verificar si ya hizo check-out hoy
  bool get hasCheckedOutToday {
    final last = todayLastAttendance;
    return last != null && last.checkOutTime != null;
  }
}

// Provider del notifier
final attendanceProvider =
    AsyncNotifierProvider<AttendanceNotifier, List<AttendanceModel>>(
      AttendanceNotifier.new,
    );

// Provider de asistencias recientes (últimos 30 días de toda la organización)
// Útil para análisis predictivo de IA y dashboards gerenciales
final recentOrganizationAttendanceProvider =
    FutureProvider.autoDispose<List<AttendanceModel>>((ref) async {
      final now = DateTime.now();
      final thirtyDaysAgo = now.subtract(const Duration(days: 30));

      // Get attendance for all users in last 30 days
      try {
        final datasource = ref.read(supabaseDatasourceProvider);
        final response = await datasource.client
            .from('attendance')
            .select()
            .gte('check_in_time', thirtyDaysAgo.toIso8601String())
            .lte('check_in_time', now.toIso8601String())
            .order('check_in_time', ascending: false)
            .limit(1000); // Limit to avoid performance issues

        return (response as List)
            .map((json) => AttendanceModel.fromJson(json))
            .toList();
      } catch (e) {
        return []; // Return empty list on error
      }
    });

/// Provider para historial de asistencias con filtros de fecha
/// Usado en AttendanceHistoryPage
final userAttendanceHistoryProvider = FutureProvider.autoDispose
    .family<List<AttendanceModel>, AttendanceHistoryParams>((
      ref,
      params,
    ) async {
      try {
        final datasource = ref.read(supabaseDatasourceProvider);

        // Si no se especifica userId, usar el usuario actual
        String? targetUserId = params.userId;
        if (targetUserId == null) {
          final currentUser = ref.read(authNotifierProvider).value;
          if (currentUser == null) throw Exception('Usuario no autenticado');
          targetUserId = currentUser.id;
        }

        final response = await datasource.client
            .from('attendance')
            .select()
            .eq('user_id', targetUserId)
            .gte('check_in_time', params.startDate.toIso8601String())
            .lte('check_in_time', params.endDate.toIso8601String())
            .order('check_in_time', ascending: false);

        return (response as List)
            .map((json) => AttendanceModel.fromJson(json))
            .toList();
      } catch (e) {
        rethrow;
      }
    });

/// Parámetros para el provider de historial
class AttendanceHistoryParams {
  final String? userId;
  final DateTime startDate;
  final DateTime endDate;

  const AttendanceHistoryParams({
    this.userId,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceHistoryParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => userId.hashCode ^ startDate.hashCode ^ endDate.hashCode;
}

// ============================================
// PROVIDER: Asistencias Recientes (últimas 3)
// ============================================
final recentAttendanceProvider = FutureProvider.autoDispose
    .family<List<AttendanceModel>, String>((ref, userId) async {
      final repository = ref.read(attendanceRepositoryProvider);

      // Obtener últimos 30 días para asegurar que tenemos datos
      final endDate = DateTime.now();
      final startDate = endDate.subtract(const Duration(days: 30));

      final allAttendance = await repository.getAttendanceByUser(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      // Ordenar por fecha descendente y tomar las primeras 3
      allAttendance.sort((a, b) => b.checkInTime.compareTo(a.checkInTime));
      return allAttendance.take(3).toList();
    });
