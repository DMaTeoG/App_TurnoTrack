import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/user_model.dart';
import 'auth_provider.dart';
import 'sales_provider.dart';
import 'analytics_provider.dart';

/// Provider que genera recomendaciones IA personalizadas basadas en:
/// - Rol del usuario
/// - Rendimiento reciente
/// - Día de la semana
/// - Estadísticas de ventas
/// - Tendencias de asistencia
final aiRecommendationsProvider = FutureProvider.autoDispose<AIRecommendation>((
  ref,
) async {
  final user = ref.watch(currentUserProvider).value;

  if (user == null) {
    return const AIRecommendation(
      message: 'Bienvenido a TurnoTrack',
      type: RecommendationType.general,
    );
  }

  // Obtener datos del usuario
  final firstName = user.fullName.split(' ').first;
  final today = DateTime.now();
  final dayOfWeek = DateFormat('EEEE', 'es').format(today);

  // Intentar obtener métricas (pueden fallar si no hay datos)
  final dateRange = DateRange(
    startDate: DateTime(today.year, today.month, 1),
    endDate: today,
  );

  try {
    switch (user.role) {
      case 'worker':
        return await _getWorkerRecommendation(
          ref,
          user,
          firstName,
          dayOfWeek,
          dateRange,
        );

      case 'supervisor':
        return await _getSupervisorRecommendation(
          ref,
          user,
          firstName,
          dayOfWeek,
          dateRange,
        );

      case 'manager':
        return await _getManagerRecommendation(
          ref,
          user,
          firstName,
          dayOfWeek,
          dateRange,
        );

      default:
        return AIRecommendation(
          message: '$firstName, empieza tu día con energía. ¡Vamos!',
          type: RecommendationType.general,
        );
    }
  } catch (e) {
    // Si falla obtener métricas, dar consejo general
    return _getFallbackRecommendation(firstName, user.role, dayOfWeek);
  }
});

/// Recomendaciones para Workers
Future<AIRecommendation> _getWorkerRecommendation(
  Ref ref,
  UserModel user,
  String firstName,
  String dayOfWeek,
  DateRange dateRange,
) async {
  // Obtener estadísticas de ventas
  final salesStats = await ref.watch(salesStatisticsProvider(user.id).future);

  // Obtener métricas de rendimiento
  PerformanceMetrics? performance;
  try {
    performance = await ref.watch(
      userPerformanceMetricsProvider(dateRange).future,
    );
  } catch (_) {
    performance = null;
  }

  // 1. Consejos basados en ventas
  if (salesStats.totalSales > 0) {
    final avgSale = salesStats.averageSale;
    final lastSale = salesStats.lastSaleDate;

    // Si lleva días sin vender
    if (lastSale != null) {
      final daysSinceLastSale = DateTime.now().difference(lastSale).inDays;

      if (daysSinceLastSale >= 3) {
        return AIRecommendation(
          message:
              '$firstName, llevas $daysSinceLastSale días sin registrar ventas. '
              '${_getSalesTipByDay(dayOfWeek)} ¡Es tu momento de brillar! 💫',
          type: RecommendationType.sales,
          priority: RecommendationPriority.high,
        );
      }
    }

    // Consejo para mejorar ticket promedio
    if (avgSale < 100) {
      return AIRecommendation(
        message:
            '$firstName, tu ticket promedio es \$${avgSale.toStringAsFixed(0)}. '
            'Intenta ofrecer productos complementarios para aumentarlo. ${_getSalesTipByDay(dayOfWeek)}',
        type: RecommendationType.sales,
        priority: RecommendationPriority.medium,
      );
    }

    // Reconocimiento por buen desempeño
    if (salesStats.totalSales >= 10 && avgSale >= 100) {
      return AIRecommendation(
        message:
            '$firstName, ¡excelente trabajo! Llevas ${salesStats.totalSales} ventas este mes '
            'con un promedio de \$${avgSale.toStringAsFixed(0)}. ${_getMotivationalTip(dayOfWeek)}',
        type: RecommendationType.motivation,
        priority: RecommendationPriority.low,
      );
    }
  }

  // 2. Consejos basados en asistencia/puntualidad
  if (performance != null) {
    final punctualityRate = (performance.totalCheckIns > 0)
        ? ((performance.totalCheckIns - performance.lateCheckIns) /
              performance.totalCheckIns *
              100)
        : 0.0;

    // Puntualidad baja
    if (punctualityRate < 70 && performance.totalCheckIns >= 5) {
      return AIRecommendation(
        message:
            '$firstName, tu puntualidad es del ${punctualityRate.toStringAsFixed(0)}%. '
            'Intenta salir 10 minutos antes de casa. Llegar temprano mejora tu ranking y da buena impresión. ⏰',
        type: RecommendationType.attendance,
        priority: RecommendationPriority.high,
      );
    }

    // Puntualidad mejorada
    if (punctualityRate >= 90 && performance.totalCheckIns >= 10) {
      return AIRecommendation(
        message:
            '$firstName, ¡tu puntualidad es del ${punctualityRate.toStringAsFixed(0)}%! '
            'Sigue así y pronto estarás en el top 3 del ranking. 🏆',
        type: RecommendationType.motivation,
        priority: RecommendationPriority.low,
      );
    }
  }

  // 3. Consejos por día de la semana (fallback)
  return AIRecommendation(
    message:
        '$firstName, ${_getGeneralTipByDay(dayOfWeek)} ${_getSalesTipByDay(dayOfWeek)}',
    type: RecommendationType.general,
    priority: RecommendationPriority.medium,
  );
}

/// Recomendaciones para Supervisores
Future<AIRecommendation> _getSupervisorRecommendation(
  Ref ref,
  UserModel user,
  String firstName,
  String dayOfWeek,
  DateRange dateRange,
) async {
  // Obtener métricas del equipo
  List<PerformanceMetrics> teamPerformance = [];
  try {
    teamPerformance = await ref.watch(
      teamPerformanceMetricsProvider(dateRange).future,
    );
  } catch (_) {
    teamPerformance = [];
  }

  if (teamPerformance.isEmpty) {
    return AIRecommendation(
      message:
          '$firstName, revisa el estado de tu equipo hoy. '
          'Un check-in rápido con cada miembro puede marcar la diferencia. 👥',
      type: RecommendationType.leadership,
      priority: RecommendationPriority.medium,
    );
  }

  // Analizar equipo
  final totalMembers = teamPerformance.length;
  final lowPerformers = teamPerformance.where((m) {
    final punctuality = m.totalCheckIns > 0
        ? (m.totalCheckIns - m.lateCheckIns) / m.totalCheckIns * 100
        : 0;
    return punctuality < 70;
  }).length;

  // Alerta de bajo rendimiento en el equipo
  if (lowPerformers > totalMembers / 3) {
    return AIRecommendation(
      message:
          '$firstName, $lowPerformers de $totalMembers miembros tienen puntualidad baja. '
          'Considera una reunión 1-on-1 para entender sus desafíos. La empatía construye equipos fuertes. 💪',
      type: RecommendationType.leadership,
      priority: RecommendationPriority.high,
    );
  }

  // Reconocimiento de buen liderazgo
  final highPerformers = teamPerformance.where((m) {
    final punctuality = m.totalCheckIns > 0
        ? (m.totalCheckIns - m.lateCheckIns) / m.totalCheckIns * 100
        : 100;
    return punctuality >= 90;
  }).length;

  if (highPerformers > totalMembers * 0.7) {
    return AIRecommendation(
      message:
          '$firstName, ¡tu equipo brilla! $highPerformers de $totalMembers miembros '
          'tienen excelente puntualidad. Celebra sus logros y mantén el momentum. 🌟',
      type: RecommendationType.motivation,
      priority: RecommendationPriority.low,
    );
  }

  // Consejo general para supervisores
  return AIRecommendation(
    message:
        '$firstName, ${_getSupervisorTipByDay(dayOfWeek)} '
        'Tu liderazgo impacta directamente en el éxito del equipo.',
    type: RecommendationType.leadership,
    priority: RecommendationPriority.medium,
  );
}

/// Recomendaciones para Managers
Future<AIRecommendation> _getManagerRecommendation(
  Ref ref,
  UserModel user,
  String firstName,
  String dayOfWeek,
  DateRange dateRange,
) async {
  // Obtener KPIs organizacionales
  Map<String, dynamic> kpis = {};
  try {
    kpis = await ref.watch(organizationKPIsProvider(dateRange).future);
  } catch (_) {
    kpis = {};
  }

  if (kpis.isEmpty) {
    return AIRecommendation(
      message:
          '$firstName, revisa los dashboards estratégicos hoy. '
          'Los datos te ayudarán a tomar decisiones informadas para el crecimiento. 📊',
      type: RecommendationType.strategy,
      priority: RecommendationPriority.medium,
    );
  }

  // Analizar tendencias
  final avgAttendance = kpis['average_attendance_rate'] as double? ?? 0;
  final avgPunctuality = kpis['average_punctuality_rate'] as double? ?? 0;

  // Alerta de asistencia baja
  if (avgAttendance < 80) {
    return AIRecommendation(
      message:
          '$firstName, la asistencia promedio es ${avgAttendance.toStringAsFixed(0)}%. '
          'Considera implementar incentivos o revisar políticas. Un equipo presente es un equipo productivo. 🎯',
      type: RecommendationType.strategy,
      priority: RecommendationPriority.high,
    );
  }

  // Reconocimiento de buena gestión
  if (avgAttendance >= 90 && avgPunctuality >= 85) {
    return AIRecommendation(
      message:
          '$firstName, ¡números extraordinarios! Asistencia: ${avgAttendance.toStringAsFixed(0)}%, '
          'Puntualidad: ${avgPunctuality.toStringAsFixed(0)}%. Tu estrategia está funcionando. 🚀',
      type: RecommendationType.motivation,
      priority: RecommendationPriority.low,
    );
  }

  // Consejo estratégico por día
  return AIRecommendation(
    message:
        '$firstName, ${_getManagerTipByDay(dayOfWeek)} '
        'Las decisiones de hoy construyen el éxito de mañana.',
    type: RecommendationType.strategy,
    priority: RecommendationPriority.medium,
  );
}

/// Recomendación de respaldo cuando no hay datos
AIRecommendation _getFallbackRecommendation(
  String firstName,
  String role,
  String dayOfWeek,
) {
  switch (role) {
    case 'worker':
      return AIRecommendation(
        message:
            '$firstName, ${_getGeneralTipByDay(dayOfWeek)} ${_getSalesTipByDay(dayOfWeek)}',
        type: RecommendationType.general,
      );
    case 'supervisor':
      return AIRecommendation(
        message:
            '$firstName, ${_getSupervisorTipByDay(dayOfWeek)} Tu equipo te necesita liderando con el ejemplo.',
        type: RecommendationType.leadership,
      );
    case 'manager':
      return AIRecommendation(
        message:
            '$firstName, ${_getManagerTipByDay(dayOfWeek)} La visión estratégica es tu superpoder.',
        type: RecommendationType.strategy,
      );
    default:
      return AIRecommendation(
        message:
            '$firstName, que tengas un excelente día. ¡Hagamos que cuente!',
        type: RecommendationType.general,
      );
  }
}

// ============================================
// TIPS POR DÍA DE LA SEMANA
// ============================================

String _getGeneralTipByDay(String day) {
  switch (day.toLowerCase()) {
    case 'lunes':
      return 'los lunes son para arrancar con energía.';
    case 'martes':
      return 'martes de productividad.';
    case 'miércoles':
      return 'mitad de semana, ¡no aflojes!';
    case 'jueves':
      return 'jueves de impulso final.';
    case 'viernes':
      return 'viernes para cerrar con broche de oro.';
    case 'sábado':
      return 'los sábados son oportunidad.';
    case 'domingo':
      return 'domingo para brillar.';
    default:
      return 'hoy es tu día.';
  }
}

String _getSalesTipByDay(String day) {
  switch (day.toLowerCase()) {
    case 'lunes':
      return 'Aprovecha que los clientes planean su semana y necesitan productos.';
    case 'martes':
    case 'miércoles':
      return 'Días ideales para promociones y ofertas especiales.';
    case 'jueves':
      return 'Los clientes preparan su fin de semana, ofrece productos premium.';
    case 'viernes':
      return 'Viernes de ventas altas, la gente busca celebrar. ¡Aprovecha!';
    case 'sábado':
      return 'Sábados son para ventas en volumen, enfócate en cantidad.';
    case 'domingo':
      return 'Los clientes tienen tiempo, brinda atención personalizada.';
    default:
      return 'Escucha al cliente, entiende su necesidad.';
  }
}

String _getSupervisorTipByDay(String day) {
  switch (day.toLowerCase()) {
    case 'lunes':
      return 'Establece objetivos claros para la semana con tu equipo.';
    case 'martes':
    case 'miércoles':
      return 'Da feedback constructivo a medio camino.';
    case 'jueves':
      return 'Prepara a tu equipo para un cierre fuerte de semana.';
    case 'viernes':
      return 'Reconoce los logros semanales de tu equipo.';
    case 'sábado':
      return 'Apoya a tu equipo en el día más demandante.';
    case 'domingo':
      return 'Asegúrate que todos tienen lo necesario para triunfar.';
    default:
      return 'Tu actitud define la del equipo.';
  }
}

String _getManagerTipByDay(String day) {
  switch (day.toLowerCase()) {
    case 'lunes':
      return 'Revisa las métricas de la semana pasada y ajusta estrategia.';
    case 'martes':
    case 'miércoles':
      return 'Reúnete con supervisores para alinear objetivos.';
    case 'jueves':
      return 'Analiza tendencias y proyecta resultados de fin de semana.';
    case 'viernes':
      return 'Celebra wins y planifica mejoras para la próxima semana.';
    case 'sábado':
      return 'Monitorea operaciones en tiempo real.';
    case 'domingo':
      return 'Prepara la visión estratégica de la próxima semana.';
    default:
      return 'Los datos guían, pero la intuición decide.';
  }
}

String _getMotivationalTip(String day) {
  switch (day.toLowerCase()) {
    case 'lunes':
      return 'Arranca la semana como líder de ventas. 💪';
    case 'viernes':
      return 'Termina la semana como campeón. 🏆';
    default:
      return '¡Sigue así, vas por buen camino! 🌟';
  }
}

// ============================================
// MODELOS
// ============================================

class AIRecommendation {
  final String message;
  final RecommendationType type;
  final RecommendationPriority priority;

  const AIRecommendation({
    required this.message,
    required this.type,
    this.priority = RecommendationPriority.medium,
  });
}

enum RecommendationType {
  sales, // Consejos de ventas
  attendance, // Consejos de asistencia
  motivation, // Motivación y reconocimiento
  leadership, // Para supervisores
  strategy, // Para managers
  general, // Consejos generales
}

enum RecommendationPriority {
  high, // Rojo/Urgente
  medium, // Amarillo/Normal
  low, // Verde/Celebración
}
