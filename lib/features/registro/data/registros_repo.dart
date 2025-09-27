import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/constants.dart';
import '../../../core/providers/supabase_client_provider.dart';
import '../domain/entities.dart';

final registrosRepositoryProvider = Provider<RegistrosRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return RegistrosRepository(client);
});

class RegistrosRepository {
  RegistrosRepository(this._client);

  final SupabaseClient _client;

  Future<void> registrar({
    required Registro registro,
    required XFile foto,
  }) async {
    final storagePath = _buildStoragePath(registro);
    final bytes = await foto.readAsBytes();

    await _client.storage.from(AppConstants.registrosBucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/jpeg',
            upsert: true,
          ),
        );

    final payload = {
      'id': registro.id,
      'empleado_id': registro.empleadoId,
      'tipo': registro.tipo.name,
      'tomado_en': registro.tiempo.toIso8601String(),
      'lat': registro.latitud,
      'lng': registro.longitud,
      'precision_m': registro.precisionMetros,
      'codigo_validacion': registro.codigoVerificacion,
      'evidencia_url': '${AppConstants.registrosBucket}/$storagePath',
      'creado_por': registro.creadoPor,
    };

    await _client.from('registros').insert(payload);
  }

  Future<List<Registro>> obtenerHistorial({
    required String empleadoId,
  }) async {
    final result = await _client
        .from('registros')
        .select()
        .eq('empleado_id', empleadoId)
        .order('tomado_en', ascending: false)
        .limit(100);
    return (result as List<dynamic>).map((row) => _mapRegistro(row)).toList();
  }

  Registro _mapRegistro(Map<String, dynamic> data) {
    return Registro(
      id: data['id'] as String,
      empleadoId: data['empleado_id'] as String,
      tipo: TipoRegistro.values
          .firstWhere((tipo) => tipo.name == data['tipo'] as String),
      tiempo: DateTime.parse(data['tomado_en'] as String),
      latitud: (data['lat'] as num).toDouble(),
      longitud: (data['lng'] as num).toDouble(),
      precisionMetros: (data['precision_m'] as num).toDouble(),
      codigoVerificacion: data['codigo_validacion'] as String,
      evidenciaUrl: data['evidencia_url'] as String?,
      creadoPor: data['creado_por'] as String?,
    );
  }

  String _buildStoragePath(Registro registro) {
    final date = registro.tiempo.toUtc();
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy/$mm/$dd/${registro.id}.jpg';
  }
}

