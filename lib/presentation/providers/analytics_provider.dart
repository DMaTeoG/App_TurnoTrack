import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../core/utils/app_logger.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../domain/repositories/i_analytics_repository.dart';
import 'auth_provider.dart';

// Provider del repositorio de analytics
final analyticsRepositoryProvider = Provider<IAnalyticsRepository>((ref) {
  final datasource = ref.read(supabaseDatasourceProvider);
  return AnalyticsRepositoryImpl(datasource);
});

// Provider de métricas de rendimiento del usuario actual
final userPerformanceMetricsProvider = FutureProvider.autoDispose
    .family<PerformanceMetrics, DateRange>((ref, dateRange) async {
      final authState = ref.read(authNotifierProvider);
      final user = authState.value;

      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final repository = ref.read(analyticsRepositoryProvider);
      return await repository.getPerformanceMetrics(
        userId: user.id,
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );
    });

// Provider de métricas del equipo (para supervisores)
final teamPerformanceMetricsProvider = FutureProvider.autoDispose
    .family<List<PerformanceMetrics>, DateRange>((ref, dateRange) async {
      // Usar read en lugar de watch para evitar rebuilds infinitos
      final authState = ref.read(authNotifierProvider);
      final user = authState.value;

      if (user == null) {
        return [];
      }

      // Si no es supervisor ni manager, retornar vacío
      if (user.role != 'supervisor' && user.role != 'manager') {
        return [];
      }

      try {
        final repository = ref.read(analyticsRepositoryProvider);

        // Agregar timeout para evitar espera infinita
        final result = await repository
            .getTeamPerformance(
              supervisorId: user.id,
              startDate: dateRange.startDate,
              endDate: dateRange.endDate,
            )
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                // Si timeout, retornar lista vacía en lugar de error
                return <PerformanceMetrics>[];
              },
            );

        return result;
      } catch (e) {
        // En caso de error, retornar lista vacía
        AppLogger.error('Error loading team performance', e);
        return [];
      }
    });

// Provider de KPIs organizacionales (para managers)
final organizationKPIsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, DateRange>((ref, dateRange) async {
      final authState = ref.read(authNotifierProvider);
      final user = authState.value;

      if (user == null || user.role != 'manager') {
        return {};
      }

      final repository = ref.read(analyticsRepositoryProvider);
      return await repository.getOrganizationKPIs(
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );
    });

// Provider de ranking
final performanceRankingProvider = FutureProvider.autoDispose
    .family<List<PerformanceMetrics>, RankingParams>((ref, params) async {
      debugPrint('🏆 [RANKING] Solicitando ranking...');
      debugPrint('🏆 [RANKING] Fecha inicio: ${params.dateRange.startDate}');
      debugPrint('🏆 [RANKING] Fecha fin: ${params.dateRange.endDate}');
      debugPrint('🏆 [RANKING] Límite: ${params.limit}');

      try {
        final repository = ref.read(analyticsRepositoryProvider);
        final result = await repository.getRanking(
          startDate: params.dateRange.startDate,
          endDate: params.dateRange.endDate,
          limit: params.limit,
        );

        debugPrint('🏆 [RANKING] ✅ Datos recibidos: ${result.length} usuarios');
        return result;
      } catch (e, stack) {
        debugPrint('🏆 [RANKING] ❌ ERROR: $e');
        debugPrint('🏆 [RANKING] Stack: $stack');
        rethrow;
      }
    });

// ============================================
// CLASES AUXILIARES
// ============================================

/// Rango de fechas para filtros
class DateRange {
  final DateTime startDate;
  final DateTime endDate;

  const DateRange({required this.startDate, required this.endDate});

  /// Última semana
  factory DateRange.lastWeek() {
    final now = DateTime.now();
    return DateRange(
      startDate: now.subtract(const Duration(days: 7)),
      endDate: now,
    );
  }

  /// Último mes
  factory DateRange.lastMonth() {
    final now = DateTime.now();
    return DateRange(
      startDate: DateTime(now.year, now.month - 1, now.day),
      endDate: now,
    );
  }

  /// Mes actual
  factory DateRange.currentMonth() {
    final now = DateTime.now();
    return DateRange(
      startDate: DateTime(now.year, now.month, 1),
      endDate: DateTime(now.year, now.month + 1, 0),
    );
  }

  /// Año actual
  factory DateRange.currentYear() {
    final now = DateTime.now();
    return DateRange(
      startDate: DateTime(now.year, 1, 1),
      endDate: DateTime(now.year, 12, 31),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode;
}

/// Parámetros para ranking
class RankingParams {
  final DateRange dateRange;
  final int limit;

  const RankingParams({required this.dateRange, this.limit = 10});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankingParams &&
          runtimeType == other.runtimeType &&
          dateRange == other.dateRange &&
          limit == other.limit;

  @override
  int get hashCode => dateRange.hashCode ^ limit.hashCode;
}

// ============================================
// PROVIDERS PARA GRÁFICAS DEL DASHBOARD
// ============================================

/// Provider de tendencia de asistencia (últimos 6 meses)
final attendanceTrendProvider = FutureProvider.autoDispose
    .family<List<MonthlyAttendance>, DateRange>((ref, dateRange) async {
      final user = ref.watch(authNotifierProvider).value;
      if (user == null || user.role != 'manager') {
        return [];
      }

      final repository = ref.read(analyticsRepositoryProvider);
      final start = DateTime(
        dateRange.startDate.year,
        dateRange.startDate.month,
        dateRange.startDate.day,
      );
      final end = DateTime(
        dateRange.endDate.year,
        dateRange.endDate.month,
        dateRange.endDate.day,
      );
      final diffDays = end.difference(start).inDays.abs() + 1;

      final List<MonthlyAttendance> result = [];

      // Decide granularity: daily for ranges up to 31 days, weekly for <= 120 days, monthly otherwise
      if (diffDays <= 31) {
        // Daily buckets
        for (int i = 0; i < diffDays; i++) {
          final dayStart = start.add(Duration(days: i));
          final dayEnd = dayStart
              .add(const Duration(days: 1))
              .subtract(const Duration(seconds: 1));

          final kpis = await repository.getOrganizationKPIs(
            startDate: dayStart,
            endDate: dayEnd,
          );

          final totalCheckIns = (kpis['total_check_ins'] as int?) ?? 0;
          if (totalCheckIns > 0) {
            result.add(
              MonthlyAttendance(
                month: dayStart,
                attendanceRate:
                    (kpis['avg_attendance_score'] as num?)?.toDouble() ?? 0.0,
                punctualityRate:
                    (kpis['punctuality_rate'] as num?)?.toDouble() ?? 0.0,
              ),
            );
          } else {
            // still add zero entries so the chart shows gaps
            result.add(
              MonthlyAttendance(
                month: dayStart,
                attendanceRate: 0.0,
                punctualityRate: 0.0,
              ),
            );
          }
        }
      } else if (diffDays <= 120) {
        // Weekly buckets
        DateTime cursor = start;
        while (cursor.isBefore(end) || cursor.isAtSameMomentAs(end)) {
          final weekStart = cursor;
          final weekEnd =
              (cursor
                      .add(const Duration(days: 7))
                      .subtract(const Duration(seconds: 1)))
                  .isAfter(end)
              ? end
              : cursor
                    .add(const Duration(days: 7))
                    .subtract(const Duration(seconds: 1));

          final kpis = await repository.getOrganizationKPIs(
            startDate: weekStart,
            endDate: weekEnd,
          );

          result.add(
            MonthlyAttendance(
              month: weekStart,
              attendanceRate:
                  (kpis['avg_attendance_score'] as num?)?.toDouble() ?? 0.0,
              punctualityRate:
                  (kpis['punctuality_rate'] as num?)?.toDouble() ?? 0.0,
            ),
          );

          cursor = cursor.add(const Duration(days: 7));
        }
      } else {
        // Monthly buckets between start and end
        DateTime cursor = DateTime(start.year, start.month, 1);
        while (cursor.isBefore(end) || cursor.isAtSameMomentAs(end)) {
          final nextMonth = DateTime(cursor.year, cursor.month + 1, 1);
          final monthStart = cursor;
          final monthEnd =
              nextMonth.subtract(const Duration(seconds: 1)).isAfter(end)
              ? end
              : nextMonth.subtract(const Duration(seconds: 1));

          final kpis = await repository.getOrganizationKPIs(
            startDate: monthStart,
            endDate: monthEnd,
          );

          result.add(
            MonthlyAttendance(
              month: monthStart,
              attendanceRate:
                  (kpis['avg_attendance_score'] as num?)?.toDouble() ?? 0.0,
              punctualityRate:
                  (kpis['punctuality_rate'] as num?)?.toDouble() ?? 0.0,
            ),
          );

          cursor = DateTime(cursor.year, cursor.month + 1, 1);
        }
      }

      return result;
    });

/// Provider de distribución de desempeño
final performanceDistributionProvider =
    FutureProvider.autoDispose<PerformanceDistribution>((ref) async {
      final user = ref.watch(authNotifierProvider).value;
      if (user == null || user.role != 'manager') {
        return PerformanceDistribution(
          excellent: 0,
          good: 0,
          needsImprovement: 0,
        );
      }

      final repository = ref.read(analyticsRepositoryProvider);
      final dateRange = DateRange.currentMonth();

      // Obtener métricas de todos los empleados
      final allMetrics = await repository.getOrganizationKPIs(
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );

      // Aquí deberías obtener la distribución real de la base de datos
      // Por ahora, retornamos estructura vacía si no hay datos
      final totalEmployees = (allMetrics['active_employees'] as int?) ?? 0;

      if (totalEmployees == 0) {
        return PerformanceDistribution(
          excellent: 0,
          good: 0,
          needsImprovement: 0,
        );
      }

      // Consultar distribución real desde performance_metrics
      final datasource = ref.read(supabaseDatasourceProvider);

      try {
        // Obtener métricas de todos los usuarios activos en el período
        final response = await datasource.client
            .from('performance_metrics')
            .select('attendance_score')
            .gte('period_start', dateRange.startDate.toIso8601String())
            .lte('period_end', dateRange.endDate.toIso8601String());

        if (response.isEmpty) {
          return PerformanceDistribution(
            excellent: 0,
            good: 0,
            needsImprovement: 0,
          );
        }

        int excellent = 0;
        int good = 0;
        int needsImprovement = 0;

        for (final metric in response) {
          final score = (metric['attendance_score'] as num?)?.toDouble() ?? 0;
          if (score >= 90) {
            excellent++;
          } else if (score >= 70) {
            good++;
          } else {
            needsImprovement++;
          }
        }

        return PerformanceDistribution(
          excellent: excellent,
          good: good,
          needsImprovement: needsImprovement,
        );
      } catch (e) {
        AppLogger.error('Error loading performance distribution', e);
        return PerformanceDistribution(
          excellent: 0,
          good: 0,
          needsImprovement: 0,
        );
      }
    });

/// Provider de supervisores y su rendimiento
final supervisorsPerformanceProvider =
    FutureProvider.autoDispose<List<SupervisorStats>>((ref) async {
      final user = ref.watch(authNotifierProvider).value;
      if (user == null || user.role != 'manager') {
        return [];
      }

      // Consulta real a users + performance_metrics
      final datasource = ref.read(supabaseDatasourceProvider);

      try {
        // Obtener todos los supervisores
        final supervisorsResponse = await datasource.client
            .from('users')
            .select('id, full_name')
            .eq('role', 'supervisor')
            .eq('is_active', true);

        if (supervisorsResponse.isEmpty) {
          return [];
        }

        final List<SupervisorStats> supervisorStatsList = [];

        for (final supervisor in supervisorsResponse) {
          final supervisorId = supervisor['id'] as String;
          final supervisorName = supervisor['full_name'] as String;

          // Contar trabajadores asignados
          final workersResponse = await datasource.client
              .from('users')
              .select('id')
              .eq('supervisor_id', supervisorId)
              .eq('is_active', true);

          final teamSize = workersResponse.length;

          // Si no tiene equipo, no agregarlo a la lista
          if (teamSize == 0) {
            continue;
          }

          // Obtener IDs de workers para consultar métricas
          final workerIds = (workersResponse as List)
              .map((w) => w['id'] as String)
              .toList();

          // Obtener promedio de score del equipo
          final metricsResponse = await datasource.client
              .from('performance_metrics')
              .select('attendance_score')
              .inFilter('user_id', workerIds)
              .gte(
                'period_start',
                DateTime.now()
                    .subtract(const Duration(days: 30))
                    .toIso8601String(),
              );

          double avgScore = 0.0;
          if (metricsResponse.isNotEmpty) {
            final scores = (metricsResponse as List)
                .map((m) => (m['attendance_score'] as num?)?.toDouble() ?? 0.0)
                .toList();
            avgScore = scores.reduce((a, b) => a + b) / scores.length;
          }

          supervisorStatsList.add(
            SupervisorStats(
              id: supervisorId,
              name: supervisorName,
              teamSize: teamSize,
              avgScore: avgScore,
            ),
          );
        }

        // Ordenar por score descendente
        supervisorStatsList.sort((a, b) => b.avgScore.compareTo(a.avgScore));

        return supervisorStatsList;
      } catch (e) {
        AppLogger.error('Error loading supervisors performance', e);
        return [];
      }
    });

/// Provider de comparativa por área/departamento
final departmentComparisonProvider =
    FutureProvider.autoDispose<List<DepartmentStats>>((ref) async {
      final user = ref.watch(authNotifierProvider).value;
      if (user == null || user.role != 'manager') {
        return [];
      }

      // Implementación real agrupando por supervisor (como "departamento")
      final datasource = ref.read(supabaseDatasourceProvider);

      try {
        // Obtener todos los supervisores como "departamentos"
        final supervisorsResponse = await datasource.client
            .from('users')
            .select('id, full_name')
            .eq('role', 'supervisor')
            .eq('is_active', true);

        if (supervisorsResponse.isEmpty) {
          return [];
        }

        final List<DepartmentStats> departmentStatsList = [];

        for (final supervisor in supervisorsResponse) {
          final supervisorId = supervisor['id'] as String;
          final supervisorName = supervisor['full_name'] as String;

          // Obtener trabajadores del supervisor
          final workersResponse = await datasource.client
              .from('users')
              .select('id')
              .eq('supervisor_id', supervisorId)
              .eq('is_active', true);

          if (workersResponse.isEmpty) {
            departmentStatsList.add(
              DepartmentStats(department: supervisorName, score: 0),
            );
            continue;
          }

          final workerIds = (workersResponse as List)
              .map((w) => w['id'] as String)
              .toList();

          // Obtener score promedio del "departamento"
          final metricsResponse = await datasource.client
              .from('performance_metrics')
              .select('attendance_score')
              .inFilter('user_id', workerIds)
              .gte(
                'period_start',
                DateTime.now()
                    .subtract(const Duration(days: 30))
                    .toIso8601String(),
              );

          int avgScore = 0;
          if (metricsResponse.isNotEmpty) {
            final scores = (metricsResponse as List)
                .map((m) => (m['attendance_score'] as num?)?.toInt() ?? 0)
                .toList();
            avgScore = (scores.reduce((a, b) => a + b) / scores.length).round();
          }

          departmentStatsList.add(
            DepartmentStats(department: supervisorName, score: avgScore),
          );
        }

        // Ordenar por score descendente
        departmentStatsList.sort((a, b) => b.score.compareTo(a.score));

        return departmentStatsList;
      } catch (e) {
        AppLogger.error('Error loading department comparison', e);
        return [];
      }
    });

/// Provider de alertas críticas
final criticalAlertsProvider = FutureProvider.autoDispose<List<CriticalAlert>>((
  ref,
) async {
  final user = ref.watch(authNotifierProvider).value;
  if (user == null || user.role != 'manager') {
    return [];
  }

  final repository = ref.read(analyticsRepositoryProvider);
  final dateRange = DateRange.lastWeek();

  final kpis = await repository.getOrganizationKPIs(
    startDate: dateRange.startDate,
    endDate: dateRange.endDate,
  );

  final List<CriticalAlert> alerts = [];

  // Alerta si puntualidad es menor al 80%
  final punctualityRate = (kpis['punctuality_rate'] as num?)?.toDouble() ?? 0.0;
  if (punctualityRate < 80) {
    alerts.add(
      CriticalAlert(
        title: 'Baja puntualidad general',
        description:
            'Tasa de puntualidad: ${punctualityRate.toStringAsFixed(1)}%',
        severity: AlertSeverity.high,
      ),
    );
  }

  // Alerta si hay muchos check-ins tardíos
  final lateCheckIns = kpis['late_check_ins'] as int? ?? 0;
  final totalCheckIns = kpis['total_check_ins'] as int? ?? 1;
  if (lateCheckIns > totalCheckIns * 0.2) {
    alerts.add(
      CriticalAlert(
        title: 'Alto número de retrasos',
        description: '$lateCheckIns de $totalCheckIns registros con retraso',
        severity: AlertSeverity.medium,
      ),
    );
  }

  return alerts;
});

// ============================================
// CLASES DE DATOS PARA GRÁFICAS
// ============================================

class MonthlyAttendance {
  final DateTime month;
  final double attendanceRate;
  final double punctualityRate;

  MonthlyAttendance({
    required this.month,
    required this.attendanceRate,
    required this.punctualityRate,
  });
}

class PerformanceDistribution {
  final int excellent;
  final int good;
  final int needsImprovement;

  PerformanceDistribution({
    required this.excellent,
    required this.good,
    required this.needsImprovement,
  });

  int get total => excellent + good + needsImprovement;
}

class SupervisorStats {
  final String id;
  final String name;
  final int teamSize;
  final double avgScore;

  SupervisorStats({
    required this.id,
    required this.name,
    required this.teamSize,
    required this.avgScore,
  });
}

class DepartmentStats {
  final String department;
  final int score;

  DepartmentStats({required this.department, required this.score});
}

class CriticalAlert {
  final String title;
  final String description;
  final AlertSeverity severity;

  CriticalAlert({
    required this.title,
    required this.description,
    required this.severity,
  });
}

enum AlertSeverity { high, medium, low }
