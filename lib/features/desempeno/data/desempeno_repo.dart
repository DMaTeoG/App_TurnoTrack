import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_client_provider.dart';

final desempenoRepositoryProvider = Provider<DesempenoRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return DesempenoRepository(client);
});

class DesempenoRepository {
  DesempenoRepository(this._client);

  final SupabaseClient _client;

  Future<List<RankingItem>> rankingSemanal({required DateTime semana}) async {
    final response = await _client
        .from('desempeno_semana')
        .select()
        .eq('semana_iso', _formatSemana(semana))
        .order('score', ascending: false)
        .limit(50);

    return (response as List<dynamic>)
        .map((row) => RankingItem(
              empleadoId: row['empleado_id'] as String,
              empleado: row['empleado'] as String? ?? 'Empleado',
              supervisor: row['supervisor'] as String?,
              score: (row['score'] as num).toDouble(),
              horas: (row['horas_efectivas'] as num?)?.toDouble() ?? 0,
              puntualidad: (row['puntualidad_pct'] as num?)?.toDouble() ?? 0,
            ))
        .toList();
  }

  Future<List<ConsejoIA>> consejosUsuario({required String empleadoId}) async {
    final respuesta = await _client
        .from('coaching_hist')
        .select()
        .eq('empleado_id', empleadoId)
        .order('semana_iso', ascending: false)
        .limit(8);

    return (respuesta as List<dynamic>)
        .map((row) => ConsejoIA(
              semana: row['semana_iso'] as String,
              mensajeEs: row['consejo_es'] as String,
              mensajeEn: row['consejo_en'] as String?,
            ))
        .toList();
  }

  String _formatSemana(DateTime date) {
    final week = _weekNumber(date);
    return '${date.year}W${week.toString().padLeft(2, '0')}';
  }

  int _weekNumber(DateTime date) {
    final firstDay = DateTime(date.year, 1, 4);
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final week = ((dayOfYear + firstDay.weekday - 1) / 7).ceil();
    return week;
  }
}

class RankingItem {
  const RankingItem({
    required this.empleadoId,
    required this.empleado,
    required this.supervisor,
    required this.score,
    required this.horas,
    required this.puntualidad,
  });

  final String empleadoId;
  final String empleado;
  final String? supervisor;
  final double score;
  final double horas;
  final double puntualidad;
}

class ConsejoIA {
  const ConsejoIA({
    required this.semana,
    required this.mensajeEs,
    this.mensajeEn,
  });

  final String semana;
  final String mensajeEs;
  final String? mensajeEn;
}
