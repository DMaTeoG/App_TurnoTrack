import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../domain/supervisor.dart';

final supervisoresRepositoryProvider = Provider<SupervisoresRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupervisoresRepository(client);
});

class SupervisoresRepository {
  SupervisoresRepository(this._client);

  final SupabaseClient _client;

  Future<List<SupervisorModel>> listar({String? filtro}) async {
    final query = _client.from('supervisores').select();
    if (filtro != null && filtro.isNotEmpty) {
      query.or('nombre.ilike.%$filtro%,documento.ilike.%$filtro%');
    }
    final response = await query.order('nombre');
    return (response as List<dynamic>)
        .map((row) => SupervisorModel(
              id: row['id'] as String,
              documento: row['documento'] as String,
              nombre: row['nombre'] as String,
              email: row['email'] as String,
              telefono: row['telefono'] as String?,
              activo: row['activo'] as bool? ?? true,
            ))
        .toList();
  }

  Future<void> guardar(SupervisorModel supervisor) async {
    final payload = {
      'id': supervisor.id,
      'documento': supervisor.documento,
      'nombre': supervisor.nombre,
      'email': supervisor.email,
      'telefono': supervisor.telefono,
      'activo': supervisor.activo,
    };
    await _client.from('supervisores').upsert(payload);
  }
}

