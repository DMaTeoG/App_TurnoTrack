import 'dart:math';

/// Preloaded fallback tips per role to avoid blank states when AI fails.
class AIFallbackAdvice {
  static final _random = Random();

  static const Map<String, List<String>> _roleAdvice = {
    'worker': [
      'Respira profundo al iniciar, revisa tus prioridades y arranca con la tarea mas sencilla.',
      'Llega con diez minutos de margen para acomodar tu equipo y evitar contratiempos.',
      'Celebra cada registro puntual: esa constancia abre puertas para nuevos retos.',
      'Si notas retrasos, avisa temprano y retoma el ritmo con una actividad corta para tomar impulso.',
      'Al cerrar el turno, anota que funciono hoy para repetirlo mañana con confianza.'
    ],
    'supervisor': [
      'Detecta quien destaco esta semana y envia un mensaje corto de reconocimiento.',
      'Comparte un recordatorio amable antes del primer check in para alinear al equipo.',
      'Identifica al colaborador con mas retrasos y ofrece apoyo en privado con accion concreta.',
      'Comparte una metrica positiva cada lunes para iniciar con energia.',
      'Define una mini meta diaria para el equipo y revisa el avance al final de la tarde.'
    ],
    'manager': [
      'Revisa tus KPIs clave y elige uno con mayor impacto para enfocarte hoy.',
      'Comparte una victoria reciente de la organizacion para reforzar la cultura.',
      'Agenda diez minutos con los supervisores para desbloquear obstaculos criticos.',
      'Analiza la tendencia de puntualidad y planifica un incentivo concreto para la semana.',
      'Prioriza una accion estrategica por dia y delega el resto con claridad y seguimiento.'
    ],
  };

  static String getRandomAdvice(String role) {
    final normalizedRole = role.toLowerCase();
    final options = _roleAdvice[normalizedRole];
    if (options == null || options.isEmpty) {
      return 'Mantente constante con tus registros y comunica cualquier bloqueo a tu supervisor.';
    }
    return options[_random.nextInt(options.length)];
  }
}
