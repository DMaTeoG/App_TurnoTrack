import '../../data/models/user_model.dart';

/// Repository interface for analytics operations
/// Methods throw Exception on failure
abstract class IAnalyticsRepository {
  /// Get performance metrics for a user
  Future<PerformanceMetrics> getPerformanceMetrics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get team performance metrics (for supervisors)
  Future<List<PerformanceMetrics>> getTeamPerformance({
    required String supervisorId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get organization-wide KPIs (for managers)
  Future<Map<String, dynamic>> getOrganizationKPIs({
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Get ranking for a period
  Future<List<PerformanceMetrics>> getRanking({
    required DateTime startDate,
    required DateTime endDate,
    int? limit,
  });

  /// Export attendance report
  Future<String> exportAttendanceReport({
    required DateTime startDate,
    required DateTime endDate,
    String format = 'csv', // csv, pdf, excel
  });
}
