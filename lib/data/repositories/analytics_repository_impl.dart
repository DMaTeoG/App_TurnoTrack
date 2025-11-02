import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_datasource.dart';
import '../models/user_model.dart';
import '../../domain/repositories/i_analytics_repository.dart';

/// Implementación de IAnalyticsRepository
class AnalyticsRepositoryImpl implements IAnalyticsRepository {
  final SupabaseDatasource _datasource;

  AnalyticsRepositoryImpl(this._datasource);

  /// Obtener métricas de rendimiento de un usuario
  @override
  Future<PerformanceMetrics> getPerformanceMetrics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Query a registros agrupados por día
      final response = await _datasource.client.rpc(
        'get_user_performance',
        params: {
          'user_id': userId,
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );

      if (response == null || response.isEmpty) {
        return _createEmptyMetrics(userId);
      }

      final data = response as Map<String, dynamic>;

      return PerformanceMetrics(
        userId: userId,
        attendanceScore: data['attendance_score'] ?? 0,
        averageCheckInTime: (data['avg_checkin_time'] ?? 0.0).toDouble(),
        totalCheckIns: data['total_checkins'] ?? 0,
        lateCheckIns: data['late_checkins'] ?? 0,
        periodStart: startDate,
        periodEnd: endDate,
        aiRecommendations: data['ai_recommendations'],
        ranking: data['ranking'],
      );
    } on PostgrestException catch (e) {
      throw Exception('Error obteniendo métricas: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtener métricas de rendimiento del equipo (supervisores)
  @override
  Future<List<PerformanceMetrics>> getTeamPerformance({
    required String supervisorId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Query a workers del supervisor
      final workers = await _datasource.client
          .from('users')
          .select('id')
          .eq('supervisor_id', supervisorId)
          .eq('role', 'worker')
          .eq('is_active', true);

      final List<PerformanceMetrics> teamMetrics = [];

      for (final worker in workers) {
        final metrics = await getPerformanceMetrics(
          userId: worker['id'],
          startDate: startDate,
          endDate: endDate,
        );
        teamMetrics.add(metrics);
      }

      return teamMetrics;
    } on PostgrestException catch (e) {
      throw Exception('Error obteniendo métricas del equipo: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtener KPIs organizacionales (managers)
  @override
  Future<Map<String, dynamic>> getOrganizationKPIs({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Query a función SQL que calcula KPIs globales
      final response = await _datasource.client.rpc(
        'get_organization_kpis',
        params: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
        },
      );

      if (response == null) {
        return _createEmptyKPIs();
      }

      return response as Map<String, dynamic>;
    } on PostgrestException catch (e) {
      throw Exception('Error obteniendo KPIs: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Obtener ranking de rendimiento
  @override
  Future<List<PerformanceMetrics>> getRanking({
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
  }) async {
    try {
      // Query SQL para ranking ordenado por punctuality_score
      final response = await _datasource.client.rpc(
        'get_performance_ranking',
        params: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'limit_count': limit ?? 10,
        },
      );

      if (response == null || response.isEmpty) {
        return [];
      }

      return response
          .map(
            (json) => PerformanceMetrics(
              userId: json['user_id'],
              attendanceScore: json['attendance_score'] ?? 0,
              averageCheckInTime: (json['avg_checkin_time'] ?? 0.0).toDouble(),
              totalCheckIns: json['total_checkins'] ?? 0,
              lateCheckIns: json['late_checkins'] ?? 0,
              periodStart: startDate,
              periodEnd: endDate,
              aiRecommendations: json['ai_recommendations'],
              ranking: json['ranking'],
            ),
          )
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Error obteniendo ranking: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  /// Exportar reporte de asistencias
  @override
  Future<String> exportAttendanceReport({
    required DateTime startDate,
    required DateTime endDate,
    String format = 'csv',
  }) async {
    try {
      // Query attendance records for the period
      final response = await _datasource.client
          .from('attendance')
          .select('*, users!inner(full_name, email)')
          .gte('check_in_time', startDate.toIso8601String())
          .lte('check_in_time', endDate.toIso8601String())
          .order('check_in_time', ascending: false);

      if (format == 'csv') {
        return _generateCSV(response);
      } else if (format == 'json') {
        return _generateJSON(response);
      } else {
        throw Exception('Formato no soportado: $format');
      }
    } on PostgrestException catch (e) {
      throw Exception('Error exportando reporte: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado: $e');
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  PerformanceMetrics _createEmptyMetrics(String userId) {
    return PerformanceMetrics(
      userId: userId,
      attendanceScore: 0,
      averageCheckInTime: 0.0,
      totalCheckIns: 0,
      lateCheckIns: 0,
      periodStart: DateTime.now(),
      periodEnd: DateTime.now(),
    );
  }

  Map<String, dynamic> _createEmptyKPIs() {
    return {
      'total_workers': 0,
      'active_today': 0,
      'avg_attendance_rate': 0.0,
      'avg_punctuality': 0.0,
      'total_work_hours': 0.0,
    };
  }

  String _generateCSV(List<dynamic> data) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln('Fecha,Hora,Usuario,Email,Tipo,Latitud,Longitud,Dirección');

    // Rows
    for (final row in data) {
      final timestamp = DateTime.parse(row['timestamp']);
      final date =
          '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';
      final time =
          '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';

      buffer.writeln(
        '$date,$time,${row['users']['full_name']},${row['users']['email']},${row['type']},${row['latitude']},${row['longitude']},"${row['address'] ?? ''}"',
      );
    }

    return buffer.toString();
  }

  String _generateJSON(List<dynamic> data) {
    return data.toString();
  }
}
