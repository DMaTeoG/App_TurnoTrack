import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_client_provider.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AnalyticsRepository(client);
});

class AnalyticsRepository {
  AnalyticsRepository(this._client);

  final SupabaseClient _client;

  Future<List<KpiSnapshot>> obtenerKpis({DateTime? fecha}) async {
    final response = await _client.rpc('kpis_resumen', params: {
      'fecha_base': (fecha ?? DateTime.now()).toIso8601String(),
    });
    final datos = (response as List<dynamic>? ?? [])
        .map((row) => KpiSnapshot(
              titulo: row['titulo'] as String,
              valor: row['valor'] as num,
              variacion: row['variacion'] as num?,
            ))
        .toList();
    return datos;
  }

  Future<List<SerieTiempo>> seriesHoras({required DateTime desde}) async {
    final response = await _client
        .from('v_metricas_diarias')
        .select()
        .gte('fecha', desde.toIso8601String())
        .order('fecha');

    return (response as List<dynamic>)
        .map((row) => SerieTiempo(
              fecha: DateTime.parse(row['fecha'] as String),
              valor: (row['horas_efectivas'] as num).toDouble(),
            ))
        .toList();
  }

  Future<List<PuntoMapa>> heatmap({required DateTime dia}) async {
    final response = await _client
        .from('v_registros_pareados')
        .select('lat,lng,conteo')
        .gte('fecha', dia.toIso8601String())
        .lt('fecha', dia.add(const Duration(days: 1)).toIso8601String());

    return (response as List<dynamic>)
        .map((row) => PuntoMapa(
              latitud: (row['lat'] as num).toDouble(),
              longitud: (row['lng'] as num).toDouble(),
              conteo: row['conteo'] as int? ?? 0,
            ))
        .toList();
  }

  Future<List<DetalleRegistro>> detalleRegistros({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final response = await _client
        .from('v_registros_ultimos_30')
        .select()
        .gte('fecha', desde.toIso8601String())
        .lte('fecha', hasta.toIso8601String())
        .order('fecha', ascending: false);

    return (response as List<dynamic>)
        .map((row) => DetalleRegistro(
              fecha: DateTime.parse(row['fecha'] as String),
              empleado: row['empleado'] as String,
              supervisor: row['supervisor'] as String?,
              horas: (row['horas'] as num).toDouble(),
              incidencias: row['incidencias'] as int? ?? 0,
            ))
        .toList();
  }

  Future<String?> exportCsv({
    required DateTime desde,
    required DateTime hasta,
  }) async {
    final response = await _client.rpc('export_registros_csv', params: {
      'fecha_desde': desde.toIso8601String(),
      'fecha_hasta': hasta.toIso8601String(),
    });

    return response as String?;
  }
}

class KpiSnapshot {
  const KpiSnapshot({
    required this.titulo,
    required this.valor,
    this.variacion,
  });

  final String titulo;
  final num valor;
  final num? variacion;
}

class SerieTiempo {
  const SerieTiempo({
    required this.fecha,
    required this.valor,
  });

  final DateTime fecha;
  final double valor;
}

class PuntoMapa {
  const PuntoMapa({
    required this.latitud,
    required this.longitud,
    required this.conteo,
  });

  final double latitud;
  final double longitud;
  final int conteo;
}

class DetalleRegistro {
  const DetalleRegistro({
    required this.fecha,
    required this.empleado,
    required this.supervisor,
    required this.horas,
    required this.incidencias,
  });

  final DateTime fecha;
  final String empleado;
  final String? supervisor;
  final double horas;
  final int incidencias;
}
