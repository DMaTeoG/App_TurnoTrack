import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../data/models/user_model.dart';

/// Service for AI-powered coaching using Google Gemini
/// Model: gemini-1.5-flash (latest stable, fastest, optimized for text)
/// API Version: v1beta (production ready)
class GeminiAIService {
  late final GenerativeModel _model;

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

  GeminiAIService() {
    final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

    if (apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY not found in .env file');
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

  /// Generate personalized coaching advice based on performance metrics
  Future<String> generateCoachingAdvice({
    required UserModel user,
    required PerformanceMetrics metrics,
    required String language,
  }) async {
    final prompt = _buildCoachingPrompt(user, metrics, language);

    try {
      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? 'No se pudo generar consejo';
    } catch (e) {
      throw Exception('Error generating coaching advice: $e');
    }
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
        ? 'Eres un coach laboral experto en México/Latinoamérica con 15 años de experiencia. Tu misión es ayudar a trabajadores a mejorar su puntualidad y desempeño con consejos prácticos y motivadores.'
        : 'You are an expert workplace coach with 15 years of experience. Your mission is to help workers improve their punctuality and performance with practical, motivating advice.';

    final contextPrompt = isSpanish
        ? '''
ANÁLISIS DE DESEMPEÑO - ${user.fullName} (${user.role}):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Score General: ${metrics.attendanceScore}/100 puntos
📅 Período: ${metrics.periodStart.toString().split(' ')[0]} → ${metrics.periodEnd.toString().split(' ')[0]}
✅ Registros totales: ${metrics.totalCheckIns}
⚠️ Llegadas tarde: ${metrics.lateCheckIns} ($latePercentage%)
⏰ Hora promedio entrada: ${metrics.averageCheckInTime.toStringAsFixed(2)}:00
🏆 Posición ranking: #${metrics.ranking ?? 'Sin posición'}

INSTRUCCIONES ESPECÍFICAS:
1. Evalúa el desempeño en 1-2 oraciones (usa emojis si es apropiado)
2. Da 2-3 consejos ACCIONABLES numerados que el trabajador pueda aplicar HOY
3. Sé específico con horarios y técnicas concretas
4. Cierra con una frase motivadora personalizada
5. MÁXIMO 120 palabras - sé directo y valioso
6. NO uses markdown, asteriscos, ni negritas - solo texto plano con números

EJEMPLO DE FORMATO:
Tu score de 78/100 es bueno pero tienes potencial para más. Tus 5 llegadas tarde impactan tu ranking.

1. Configura alarma 30 min antes de tu hora habitual
2. Prepara ropa y desayuno la noche anterior  
3. Usa apps de tráfico para rutas alternas

${user.fullName}, con pequeños ajustes puedes estar en el top 10 del próximo mes.

GENERA TU RESPUESTA AHORA:'''
        : '''
PERFORMANCE ANALYSIS - ${user.fullName} (${user.role}):
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Overall Score: ${metrics.attendanceScore}/100 points
📅 Period: ${metrics.periodStart.toString().split(' ')[0]} → ${metrics.periodEnd.toString().split(' ')[0]}
✅ Total check-ins: ${metrics.totalCheckIns}
⚠️ Late arrivals: ${metrics.lateCheckIns} ($latePercentage%)
⏰ Avg check-in time: ${metrics.averageCheckInTime.toStringAsFixed(2)}:00
🏆 Ranking position: #${metrics.ranking ?? 'Unranked'}

SPECIFIC INSTRUCTIONS:
1. Evaluate performance in 1-2 sentences (use emojis if appropriate)
2. Provide 2-3 ACTIONABLE numbered tips the worker can apply TODAY
3. Be specific with schedules and concrete techniques
4. Close with a personalized motivating phrase
5. MAX 120 words - be direct and valuable
6. NO markdown, asterisks, or bold - just plain text with numbers

GENERATE YOUR RESPONSE NOW:''';

    return '$systemPrompt\n\n$contextPrompt';
  }

  /// Generate team analytics summary for supervisors
  Future<String> generateTeamSummary({
    required List<PerformanceMetrics> teamMetrics,
    required String language,
  }) async {
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
      final response = await _model.generateContent(content);

      return response.text ?? 'No se pudo generar resumen';
    } catch (e) {
      throw Exception('Error generating team summary: $e');
    }
  }

  /// Predict attendance issues (advanced feature)
  Future<String> predictAttendanceIssues({
    required List<AttendanceModel> recentAttendance,
    required String language,
  }) async {
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
      final response = await _model.generateContent(content);

      return response.text ??
          (isSpanish
              ? 'No se pudo generar predicción'
              : 'Could not generate prediction');
    } catch (e) {
      throw Exception('Error predicting attendance issues: $e');
    }
  }
}
