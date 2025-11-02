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
