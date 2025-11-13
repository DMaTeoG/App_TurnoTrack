import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../utils/app_logger.dart';
import '../../data/models/user_model.dart';

/// Service for AI-powered coaching using Google Gemini
/// Model: gemini-1.5-flash (latest stable, fastest, optimized for text)
/// API Version: v1beta (production ready)
class GeminiAIService {
  GenerativeModel? _model;

  // Gemini 1.5 Flash - Optimized for speed and quality
  // Use gemini-1.5-pro for complex reasoning if needed
  static const String _modelName = 'gemini-1.5-flash-latest';

  // Generation config for consistent responses
  static final _generationConfig = GenerationConfig(
    temperature: 0.7, // Balance between creativity and consistency
    topK: 40,
    topP: 0.95,
    maxOutputTokens: 500, // Limit response length
    stopSequences: ['END'],
  );

  bool get isConfigured => _model != null;

  GeminiAIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY']?.trim();

    if (apiKey == null || apiKey.isEmpty) {
      AppLogger.warning(
        'Gemini API key not configured. AI features disabled.',
        'GeminiAI',
      );
      return;
    }

    _model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: _generationConfig,
      safetySettings: [
        SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.high),
        SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
      ],
    );
  }

  void _ensureConfigured() {
    if (_model == null) {
      throw StateError(
        'Funcionalidad de IA no configurada. Agrega GEMINI_API_KEY al archivo .env.',
      );
    }
  }

  /// Generate personalized coaching advice based on performance metrics
  /// [coachingType]: 'competitive' for ranking/comparison focus, 'motivational' for personal growth
  Future<String> generateCoachingAdvice({
    required UserModel user,
    required PerformanceMetrics metrics,
    required String language,
    String coachingType = 'competitive', // 'competitive' or 'motivational'
  }) async {
    _ensureConfigured();

    final prompt = coachingType == 'motivational'
        ? _buildMotivationalPrompt(user, metrics, language)
        : _buildCoachingPrompt(user, metrics, language);

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      return response.text ?? 'No se pudo generar consejo';
    } catch (e) {
      throw Exception('Error generating coaching advice: $e');
    }
  }

  /// Build motivational prompt focused on personal growth (no pressure, no comparison)
  String _buildMotivationalPrompt(
    UserModel user,
    PerformanceMetrics metrics,
    String language,
  ) {
    final isSpanish = language == 'es';
    final firstName = user.fullName.split(' ').first;

    final systemPrompt = isSpanish
        ? 'Eres un mentor personal empático y motivador. Tu objetivo es ayudar a $firstName a crecer profesionalmente de forma positiva, sin presión ni comparaciones con otros. Enfócate en su progreso personal y bienestar.'
        : 'You are an empathetic and motivating personal mentor. Your goal is to help $firstName grow professionally in a positive way, without pressure or comparisons. Focus on personal progress and well-being.';

    final contextPrompt = isSpanish
        ? '''
ANÁLISIS PERSONAL - $firstName:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📈 Tu progreso: ${metrics.attendanceScore}/100 puntos
📅 Registros este período: ${metrics.totalCheckIns}
⏰ Llegadas tarde: ${metrics.lateCheckIns}
💪 Áreas de crecimiento identificadas

TU MISIÓN:
1. Reconoce lo positivo que ha hecho (aunque sea pequeño)
2. Da 2-3 consejos SUAVES y prácticos para mejorar SIN presión
3. Usa un tono amigable, como un amigo que quiere ayudar
4. NO menciones rankings, comparaciones, ni presiones laborales
5. Enfócate en HÁBITOS SALUDABLES y crecimiento personal
6. MÁXIMO 100 palabras - sé cálido y alentador
7. NO uses markdown, asteriscos, ni negritas - solo texto plano

EJEMPLO DE TONO:
Hey $firstName! 👋 Veo que has estado registrando tu asistencia constantemente, eso habla de tu compromiso. 

Para que tu día sea más tranquilo, podrías:
1. Prepara tu ropa y cosas la noche anterior
2. Pon tu alarma 15 minutos antes (te sorprenderá la diferencia)
3. Escucha música motivadora en la mañana

Recuerda, cada pequeño paso cuenta. ¡Vas muy bien! 🌟
'''
        : '''
PERSONAL ANALYSIS - $firstName:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📈 Your progress: ${metrics.attendanceScore}/100 points
📅 Records this period: ${metrics.totalCheckIns}
⏰ Late arrivals: ${metrics.lateCheckIns}
💪 Growth areas identified

YOUR MISSION:
1. Recognize the positive they've done (even if small)
2. Give 2-3 GENTLE and practical tips to improve WITHOUT pressure
3. Use a friendly tone, like a friend who wants to help
4. DON'T mention rankings, comparisons, or work pressure
5. Focus on HEALTHY HABITS and personal growth
6. MAX 100 words - be warm and encouraging
7. NO markdown, asterisks, or bold - plain text only

TONE EXAMPLE:
Hey $firstName! 👋 I see you've been consistently checking in, that shows your commitment.

To make your day smoother:
1. Prepare your clothes and things the night before
2. Set your alarm 15 minutes earlier (you'll be surprised)
3. Listen to motivating music in the morning

Remember, every small step counts. You're doing great! 🌟
''';

    return '$systemPrompt\n\n$contextPrompt';
  }

  /// Build coaching prompt based on user context
  String _buildCoachingPrompt(
    UserModel user,
    PerformanceMetrics metrics,
    String language,
  ) {
    final isSpanish = language == 'es';
    final latePercentage = metrics.totalCheckIns > 0
        ? (metrics.lateCheckIns / metrics.totalCheckIns * 100).toStringAsFixed(
            1,
          )
        : '0.0';

    final systemPrompt = isSpanish
        ? 'Eres un coach de alto rendimiento especializado en análisis competitivo. Tu objetivo es ayudar a ${user.fullName} a alcanzar el TOP 1 del ranking. Sé directo, analítico y enfócate en comparaciones con el resto del equipo. Identifica puntos débiles claramente y da estrategias concretas para superarlos.'
        : 'You are a high-performance coach specialized in competitive analysis. Your goal is to help ${user.fullName} reach TOP 1 in the ranking. Be direct, analytical, and focus on comparisons with the rest of the team. Clearly identify weak points and give concrete strategies to overcome them.';

    final contextPrompt = isSpanish
        ? '''
ANÁLISIS COMPETITIVO - ${user.fullName}:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏆 TU POSICIÓN: #${metrics.ranking ?? 'Sin ranking'} 
📊 Score actual: ${metrics.attendanceScore}/100 puntos
⚠️ PUNTO DÉBIL: Llegadas tarde: ${metrics.lateCheckIns} ($latePercentage%)
⏰ Promedio entrada: ${metrics.averageCheckInTime.toStringAsFixed(2)}:00
✅ Check-ins totales: ${metrics.totalCheckIns}
🎯 META: Alcanzar TOP 1

ANÁLISIS REQUERIDO:
1. Compara su desempeño con el TOP 1 (sé específico con la brecha)
2. Identifica EL punto más débil que está impidiendo subir en el ranking
3. Da 3 acciones CONCRETAS con horarios específicos para mejorar ese punto
4. Menciona cuántos puestos puede subir si mejora
5. MÁXIMO 120 palabras - sé directo y analítico
6. Usa un tono retador pero motivador (tipo "puedes más")
7. NO uses markdown, asteriscos, ni negritas - solo texto plano

EJEMPLO DE TONO:
${user.fullName}, estás en posición #5 cuando podrías estar en el TOP 3. Tu principal obstáculo son las 8 llegadas tarde este mes - eso te resta 15 puntos del ranking.

PLAN DE ACCIÓN:
1. Despierta a las 6:30am (no 7:00am) - necesitas ese colchón de tiempo
2. Sal de casa ANTES de las 7:45am para evitar tráfico pico
3. Registra entrada ANTES de 8:10am todos los días esta semana

Si logras 0 llegadas tarde esta semana, subes mínimo 2 posiciones. El TOP 1 está más cerca de lo que crees, solo necesitas consistencia. 💪

GENERA TU ANÁLISIS:'''
        : '''
COMPETITIVE ANALYSIS - ${user.fullName}:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏆 YOUR POSITION: #${metrics.ranking ?? 'Unranked'}
📊 Current score: ${metrics.attendanceScore}/100 points
⚠️ WEAK POINT: Late arrivals: ${metrics.lateCheckIns} ($latePercentage%)
⏰ Avg entry time: ${metrics.averageCheckInTime.toStringAsFixed(2)}:00
✅ Total check-ins: ${metrics.totalCheckIns}
🎯 GOAL: Reach TOP 1

REQUIRED ANALYSIS:
1. Compare performance with TOP 1 (be specific about the gap)
2. Identify THE weakest point preventing ranking improvement
3. Give 3 CONCRETE actions with specific times
4. Mention how many positions can be gained
5. MAX 120 words - be direct and analytical
6. Use a challenging but motivating tone
7. NO markdown, asterisks, or bold - plain text only

GENERATE YOUR ANALYSIS NOW:''';

    return '$systemPrompt\n\n$contextPrompt';
  }

  /// Generate team analytics summary for supervisors
  Future<String> generateTeamSummary({
    required List<PerformanceMetrics> teamMetrics,
    required String language,
  }) async {
    _ensureConfigured();

    final isSpanish = language == 'es';

    // Calculate team statistics
    final avgScore = teamMetrics.isEmpty
        ? 0.0
        : teamMetrics.map((m) => m.attendanceScore).reduce((a, b) => a + b) /
              teamMetrics.length;
    final totalLate = teamMetrics.fold(0, (sum, m) => sum + m.lateCheckIns);
    final topPerformers = teamMetrics
        .where((m) => m.attendanceScore >= 90)
        .length;
    final needsAttention = teamMetrics
        .where((m) => m.attendanceScore < 70)
        .length;

    final systemPrompt = isSpanish
        ? 'Eres un analista senior de recursos humanos especializado en productividad de equipos. Generas insights accionables para supervisores.'
        : 'You are a senior HR analyst specialized in team productivity. You generate actionable insights for supervisors.';

    final teamData = teamMetrics
        .asMap()
        .entries
        .map((entry) {
          final idx = entry.key + 1;
          final m = entry.value;
          final lateRate = m.totalCheckIns > 0
              ? (m.lateCheckIns / m.totalCheckIns * 100).toStringAsFixed(0)
              : '0';
          return isSpanish
              ? '  $idx. Score ${m.attendanceScore}/100 | Tarde: $lateRate% (${m.lateCheckIns}/${m.totalCheckIns})'
              : '  $idx. Score ${m.attendanceScore}/100 | Late: $lateRate% (${m.lateCheckIns}/${m.totalCheckIns})';
        })
        .join('\n');

    final contextPrompt = isSpanish
        ? '''
ANÁLISIS CONSOLIDADO DE EQUIPO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Tamaño del equipo: ${teamMetrics.length} personas
⭐ Score promedio: ${avgScore.toStringAsFixed(1)}/100
🏆 Alto desempeño (≥90): $topPerformers personas
⚠️ Requieren atención (<70): $needsAttention personas
📉 Total llegadas tarde: $totalLate registros

MÉTRICAS INDIVIDUALES:
$teamData

INSTRUCCIONES PARA EL SUPERVISOR:
1. Identifica el patrón más crítico del equipo (puntualidad, consistencia, etc)
2. Menciona qué está funcionando bien (refuerzo positivo)
3. Sugiere 3 acciones ESPECÍFICAS para mejorar en las próximas 2 semanas
4. Indica si hay casos que requieren seguimiento 1-a-1
5. MÁXIMO 180 palabras - sé estratégico

FORMATO:
- Diagnóstico del equipo (2-3 líneas)
- Lo que está bien (1 línea)
- 3 acciones numeradas concretas
- Recomendación final

GENERA TU ANÁLISIS:'''
        : '''
CONSOLIDATED TEAM ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Team size: ${teamMetrics.length} people
⭐ Average score: ${avgScore.toStringAsFixed(1)}/100
🏆 High performers (≥90): $topPerformers people
⚠️ Need attention (<70): $needsAttention people
📉 Total late arrivals: $totalLate records

INDIVIDUAL METRICS:
$teamData

INSTRUCTIONS FOR SUPERVISOR:
1. Identify the most critical team pattern (punctuality, consistency, etc)
2. Mention what's working well (positive reinforcement)
3. Suggest 3 SPECIFIC actions to improve in the next 2 weeks
4. Indicate if there are cases requiring 1-on-1 follow-up
5. MAX 180 words - be strategic

FORMAT:
- Team diagnosis (2-3 lines)
- What's working (1 line)
- 3 numbered concrete actions
- Final recommendation

GENERATE YOUR ANALYSIS:''';

    final prompt = '$systemPrompt\n\n$contextPrompt';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      return response.text ?? 'No se pudo generar resumen';
    } catch (e) {
      throw Exception('Error generating team summary: $e');
    }
  }

  /// Generate strategic insights for managers (organizational level)
  Future<String> generateManagerInsights({
    required Map<String, dynamic> organizationKPIs,
    required String language,
  }) async {
    _ensureConfigured();

    final isSpanish = language == 'es';

    // Extract KPIs
    final totalCheckIns = organizationKPIs['total_check_ins'] as int? ?? 0;
    final lateCheckIns = organizationKPIs['late_check_ins'] as int? ?? 0;
    final punctualityRate =
        (organizationKPIs['punctuality_rate'] as num?)?.toDouble() ?? 0.0;
    final avgScore =
        (organizationKPIs['avg_attendance_score'] as num?)?.toDouble() ?? 0.0;
    final activeUsers = organizationKPIs['active_users'] as int? ?? 0;

    final latePercentage = totalCheckIns > 0
        ? (lateCheckIns / totalCheckIns * 100).toStringAsFixed(1)
        : '0.0';

    final systemPrompt = isSpanish
        ? 'Eres un consultor estratégico de C-Level con 20 años de experiencia en optimización organizacional y gestión de talento. Tu enfoque es en ROI, eficiencia operacional y cultura organizacional. Das recomendaciones estratégicas basadas en datos para directivos.'
        : 'You are a C-Level strategic consultant with 20 years of experience in organizational optimization and talent management. Your focus is on ROI, operational efficiency, and organizational culture. You provide data-driven strategic recommendations for executives.';

    final contextPrompt = isSpanish
        ? '''
DASHBOARD EJECUTIVO - ANÁLISIS ORGANIZACIONAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 KPIs OPERACIONALES:
  • Usuarios activos: $activeUsers personas
  • Registros totales: $totalCheckIns check-ins
  • Score promedio: ${avgScore.toStringAsFixed(1)}/100 puntos
  • Tasa puntualidad: ${punctualityRate.toStringAsFixed(1)}%
  • Llegadas tarde: $lateCheckIns ($latePercentage% del total)

🎯 TU MISIÓN ESTRATÉGICA:
1. Evalúa la SALUD ORGANIZACIONAL en 2-3 líneas (usa datos duros)
2. Identifica el MAYOR RIESGO operacional (impacto en productividad/costos)
3. Da 3 INICIATIVAS ESTRATÉGICAS priorizadas para implementar
4. Proyecta el IMPACTO esperado de cada iniciativa (cuantificable)
5. Cierra con una RECOMENDACIÓN ejecutiva clara

📋 CRITERIOS DE ANÁLISIS:
• Piensa en costos operacionales (tiempo perdido)
• Considera impacto en clima laboral
• Analiza tendencias (¿va mejorando o empeorando?)
• Enfócate en ROI de las soluciones
• MÁXIMO 200 palabras - sé ejecutivo y preciso

FORMATO ESPERADO:
Diagnóstico ejecutivo (¿qué está pasando?)
Riesgo principal identificado
Iniciativas estratégicas:
1. [Acción] - Impacto esperado: [%]
2. [Acción] - Impacto esperado: [%]
3. [Acción] - Impacto esperado: [%]
Recomendación: [Decisión clave]

GENERA TU ANÁLISIS ESTRATÉGICO:'''
        : '''
EXECUTIVE DASHBOARD - ORGANIZATIONAL ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 OPERATIONAL KPIs:
  • Active users: $activeUsers people
  • Total records: $totalCheckIns check-ins
  • Average score: ${avgScore.toStringAsFixed(1)}/100 points
  • Punctuality rate: ${punctualityRate.toStringAsFixed(1)}%
  • Late arrivals: $lateCheckIns ($latePercentage% of total)

🎯 YOUR STRATEGIC MISSION:
1. Assess ORGANIZATIONAL HEALTH in 2-3 lines (use hard data)
2. Identify the BIGGEST operational RISK (impact on productivity/costs)
3. Provide 3 prioritized STRATEGIC INITIATIVES to implement
4. Project the expected IMPACT of each initiative (quantifiable)
5. Close with a clear executive RECOMMENDATION

📋 ANALYSIS CRITERIA:
• Think about operational costs (lost time)
• Consider impact on work climate
• Analyze trends (improving or worsening?)
• Focus on ROI of solutions
• MAX 200 words - be executive and precise

EXPECTED FORMAT:
Executive diagnosis (what's happening?)
Main risk identified
Strategic initiatives:
1. [Action] - Expected impact: [%]
2. [Action] - Expected impact: [%]
3. [Action] - Expected impact: [%]
Recommendation: [Key decision]

GENERATE YOUR STRATEGIC ANALYSIS:''';

    final prompt = '$systemPrompt\n\n$contextPrompt';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      return response.text ?? 'No se pudo generar análisis';
    } catch (e) {
      throw Exception('Error generating manager insights: $e');
    }
  }

  /// Predict attendance issues (advanced feature)
  Future<String> predictAttendanceIssues({
    required List<AttendanceModel> recentAttendance,
    required String language,
  }) async {
    _ensureConfigured();

    final isSpanish = language == 'es';

    // Analyze attendance patterns
    final checkIns = recentAttendance.toList();
    final checkOuts = recentAttendance
        .where((a) => a.checkOutTime != null)
        .toList();
    final missingCheckOuts = checkIns.length - checkOuts.length;

    // Group by day of week
    final byWeekday = <int, int>{};
    for (var attendance in checkIns) {
      final weekday = attendance.checkInTime.weekday;
      byWeekday[weekday] = (byWeekday[weekday] ?? 0) + 1;
    }

    final systemPrompt = isSpanish
        ? 'Eres un sistema de ML especializado en predicción de patrones laborales. Usas datos históricos para identificar riesgos tempranos.'
        : 'You are an ML system specialized in workplace pattern prediction. You use historical data to identify early risks.';

    final attendanceSummary = checkIns
        .take(10)
        .map((a) {
          final date = a.checkInTime.toString().split(' ')[0];
          final time = a.checkInTime.toString().split(' ')[1].substring(0, 5);
          final weekdayName = isSpanish
              ? [
                  'Lun',
                  'Mar',
                  'Mié',
                  'Jue',
                  'Vie',
                  'Sáb',
                  'Dom',
                ][a.checkInTime.weekday - 1]
              : [
                  'Mon',
                  'Tue',
                  'Wed',
                  'Thu',
                  'Fri',
                  'Sat',
                  'Sun',
                ][a.checkInTime.weekday - 1];
          return '  • $date ($weekdayName) a las $time';
        })
        .join('\n');

    final contextPrompt = isSpanish
        ? '''
ANÁLISIS PREDICTIVO DE ASISTENCIA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Registros analizados: ${recentAttendance.length} (últimos 30 días)
✅ Check-ins: ${checkIns.length}
🚪 Check-outs: ${checkOuts.length}
⚠️ Check-outs faltantes: $missingCheckOuts

ÚLTIMOS 10 CHECK-INS:
$attendanceSummary

DISTRIBUCIÓN POR DÍA:
${byWeekday.entries.map((e) {
            final day = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'][e.key - 1];
            return '  $day: ${e.value} registros';
          }).join('\n')}

INSTRUCCIONES DE PREDICCIÓN:
1. Identifica patrones anómalos (días sin registros, horarios inconsistentes)
2. Calcula nivel de riesgo: 🟢 BAJO / 🟡 MEDIO / 🔴 ALTO
3. Explica QUÉ patrón detectaste y POR QUÉ es riesgoso
4. Sugiere 2 acciones preventivas inmediatas
5. MÁXIMO 130 palabras - sé preciso

FORMATO:
🔍 Riesgo detectado: [BAJO/MEDIO/ALTO]
Patrón: [descripción breve]

Señales de alerta:
- [punto específico]
- [punto específico]

Acciones recomendadas:
1. [acción concreta]
2. [acción concreta]

GENERA TU PREDICCIÓN:'''
        : '''
ATTENDANCE PREDICTIVE ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Records analyzed: ${recentAttendance.length} (last 30 days)
✅ Check-ins: ${checkIns.length}
🚪 Check-outs: ${checkOuts.length}
⚠️ Missing check-outs: $missingCheckOuts

LAST 10 CHECK-INS:
$attendanceSummary

DISTRIBUTION BY DAY:
${byWeekday.entries.map((e) {
            final day = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][e.key - 1];
            return '  $day: ${e.value} records';
          }).join('\n')}

PREDICTION INSTRUCTIONS:
1. Identify anomalous patterns (missing days, inconsistent schedules)
2. Calculate risk level: 🟢 LOW / 🟡 MEDIUM / 🔴 HIGH
3. Explain WHAT pattern you detected and WHY it's risky
4. Suggest 2 immediate preventive actions
5. MAX 130 words - be precise

FORMAT:
🔍 Detected risk: [LOW/MEDIUM/HIGH]
Pattern: [brief description]

Warning signs:
- [specific point]
- [specific point]

Recommended actions:
1. [concrete action]
2. [concrete action]

GENERATE YOUR PREDICTION:''';

    final prompt = '$systemPrompt\n\n$contextPrompt';

    try {
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      return response.text ??
          (isSpanish
              ? 'No se pudo generar predicción'
              : 'Could not generate prediction');
    } catch (e) {
      throw Exception('Error predicting attendance issues: $e');
    }
  }
}
