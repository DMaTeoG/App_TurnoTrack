import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      final user = ref.watch(authNotifierProvider).value;
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
      final user = ref.watch(authNotifierProvider).value;
      if (user == null || user.role != 'supervisor') {
        return [];
      }

      final repository = ref.read(analyticsRepositoryProvider);
      return await repository.getTeamPerformance(
        supervisorId: user.id,
        startDate: dateRange.startDate,
        endDate: dateRange.endDate,
      );
    });

// Provider de KPIs organizacionales (para managers)
final organizationKPIsProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, DateRange>((ref, dateRange) async {
      final user = ref.watch(authNotifierProvider).value;
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
      final repository = ref.read(analyticsRepositoryProvider);
      return await repository.getRanking(
        startDate: params.dateRange.startDate,
        endDate: params.dateRange.endDate,
        limit: params.limit,
      );
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
final attendanceTrendProvider =
    FutureProvider.autoDispose<List<MonthlyAttendance>>((ref) async {
      final user = ref.watch(authNotifierProvider).value;
      if (user == null || user.role != 'manager') {
        return [];
      }

      final repository = ref.read(analyticsRepositoryProvider);
      final now = DateTime.now();
      final List<MonthlyAttendance> result = [];

      // Obtener datos de los últimos 6 meses
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final nextMonth = DateTime(now.year, now.month - i + 1, 1);

        final kpis = await repository.getOrganizationKPIs(
          startDate: month,
          endDate: nextMonth.subtract(const Duration(days: 1)),
        );

        result.add(
          MonthlyAttendance(
            month: month,
            attendanceRate:
                (kpis['punctuality_rate'] as num?)?.toDouble() ?? 0.0,
            punctualityRate:
                (kpis['punctuality_rate'] as num?)?.toDouble() ?? 0.0,
          ),
        );
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

      // TODO: Implementar consulta real a performance_metrics para obtener distribución
      return PerformanceDistribution(
        excellent: 0,
        good: 0,
        needsImprovement: 0,
      );
    });

/// Provider de supervisores y su rendimiento
final supervisorsPerformanceProvider =
    FutureProvider.autoDispose<List<SupervisorStats>>((ref) async {
      final user = ref.watch(authNotifierProvider).value;
      if (user == null || user.role != 'manager') {
        return [];
      }

      // TODO: Implementar consulta real a users + performance_metrics
      return [];
    });

/// Provider de comparativa por área/departamento
final departmentComparisonProvider =
    FutureProvider.autoDispose<List<DepartmentStats>>((ref) async {
      final user = ref.watch(authNotifierProvider).value;
      if (user == null || user.role != 'manager') {
        return [];
      }

      // TODO: Implementar consulta real agrupando por departamento
      return [];
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
