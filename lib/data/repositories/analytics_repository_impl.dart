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
      // Query a workers del supervisor con timeout

      final workers = await _datasource.client
          .from('users')
          .select('id')
          .eq('supervisor_id', supervisorId)
          .eq('role', 'worker')
          .eq('is_active', true)
          .timeout(
            const Duration(seconds: 5),

            onTimeout: () => <Map<String, dynamic>>[],
          );

      // Si no hay workers, retornar lista vacía inmediatamente

      if (workers.isEmpty) {
        // Debug: descomentar si necesitas ver en logs

        // print('No hay workers para el supervisor $supervisorId');

        return [];
      }

      // Debug: descomentar si necesitas ver en logs

      // print('Encontrados ${workers.length} workers para supervisor $supervisorId');

      final List<PerformanceMetrics> teamMetrics = [];

      // Procesar workers con límite de tiempo

      for (final worker in workers) {
        try {
          final metrics =
              await getPerformanceMetrics(
                userId: worker['id'],

                startDate: startDate,

                endDate: endDate,
              ).timeout(
                const Duration(seconds: 3),

                onTimeout: () => _createEmptyMetrics(worker['id']),
              );

          teamMetrics.add(metrics);
        } catch (e) {
          // Debug: descomentar si necesitas ver en logs

          // print('Error obteniendo métricas del worker ${worker['id']}: $e');

          // Continuar con el siguiente worker

          continue;
        }
      }

      return teamMetrics;
    } on PostgrestException {
      // Debug: descomentar si necesitas ver en logs

      // print('PostgrestException en getTeamPerformance: ${e.message}');

      return []; // Retornar vacío en lugar de lanzar excepción
    } catch (e) {
      // Debug: descomentar si necesitas ver en logs

      // print('Error inesperado en getTeamPerformance: $e');

      return []; // Retornar vacío en lugar de lanzar excepción
    }
  }

  /// Obtener KPIs organizacionales (managers)

  @override
  Future<Map<String, dynamic>> getOrganizationKPIs({
    required DateTime startDate,

    required DateTime endDate,
  }) async {
    try {
      // Query a funcion SQL que calcula KPIs globales

      final response = await _datasource.client.rpc(
        'get_organization_kpis',

        params: {
          'start_date': startDate.toIso8601String(),

          'end_date': endDate.toIso8601String(),
        },
      );

      final rawData = response == null
          ? _createEmptyKPIs()
          : Map<String, dynamic>.from(response as Map<String, dynamic>);

      return await _normalizeOrganizationKPIs(rawData);
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
      // Prefer the RPC that aggregates and ranks (may include AI fields).
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
      // If the RPC fails due to ambiguous column (or other AI-related join issues),
      // fall back to a fast query on the precomputed `performance_metrics` table
      // which avoids AI joins and returns the top N by score.
      final msg = e.message.toString().toLowerCase();
      if (msg.contains('ai_recommendations') || msg.contains('ambiguous')) {
        try {
          final resp = await _datasource.client
              .from('performance_metrics')
              .select(
                'user_id, attendance_score, average_check_in_time, total_check_ins, late_check_ins, ranking',
              )
              .gte(
                'period_start',
                DateTime(
                  startDate.year,
                  startDate.month,
                  startDate.day,
                ).toIso8601String(),
              )
              .lte(
                'period_end',
                DateTime(
                  endDate.year,
                  endDate.month,
                  endDate.day,
                ).toIso8601String(),
              )
              .order('attendance_score', ascending: false)
              .limit(limit ?? 10);

          if (resp.isEmpty) return [];

          return resp
              .map(
                (json) => PerformanceMetrics(
                  userId: json['user_id'],
                  attendanceScore: json['attendance_score'] ?? 0,
                  averageCheckInTime: (json['average_check_in_time'] ?? 0.0)
                      .toDouble(),
                  totalCheckIns: json['total_check_ins'] ?? 0,
                  lateCheckIns: json['late_check_ins'] ?? 0,
                  periodStart: startDate,
                  periodEnd: endDate,
                  aiRecommendations: null,
                  ranking: json['ranking'],
                ),
              )
              .toList();
        } catch (_) {
          // If fallback fails, rethrow original RPC error for visibility
          throw Exception('Error obteniendo ranking: ${e.message}');
        }
      }

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
      'total_employees': 0,

      'active_today': 0,

      'average_score': 0.0,

      'total_check_ins': 0,

      'late_today': 0,

      'punctuality_rate': 0.0,

      'total_sales': 0.0,

      'supervisors': 0,
    };
  }

  Future<Map<String, dynamic>> _normalizeOrganizationKPIs(
    Map<String, dynamic> data,
  ) async {
    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();

      return 0.0;
    }

    final normalized = Map<String, dynamic>.from(data);

    normalized['total_employees'] =
        data['total_employees'] ?? data['total_workers'] ?? 0;

    normalized['active_today'] =
        data['active_today'] ?? data['active_employees'] ?? 0;

    normalized['average_score'] = asDouble(
      data['average_score'] ??
          data['avg_attendance_score'] ??
          data['avg_attendance_rate'] ??
          0,
    );

    normalized['late_today'] =
        data['late_today'] ?? data['late_check_ins'] ?? 0;

    normalized['punctuality_rate'] = asDouble(
      data['punctuality_rate'] ??
          data['avg_punctuality'] ??
          data['average_punctuality'] ??
          0,
    );

    normalized['supervisors'] =
        data['supervisors'] ?? await _countSupervisors();

    return normalized;
  }

  Future<int> _countSupervisors() async {
    try {
      final List<dynamic> response = await _datasource.client
          .from('users')
          .select('id')
          .eq('role', 'supervisor');

      return response.length;
    } catch (_) {
      // Ignorar errores de conteo y regresar 0
    }

    return 0;
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
