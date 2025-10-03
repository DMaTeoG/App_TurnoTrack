import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_client_provider.dart';
import '../domain/empleado.dart';

final empleadosRepositoryProvider = Provider<EmpleadosRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return EmpleadosRepository(client);
});

class EmpleadosRepository {
  EmpleadosRepository(this._client);

  final SupabaseClient _client;

  Future<List<EmpleadoModel>> listar({String? filtro}) async {
    final query = _client.from('empleados').select();
    if (filtro != null && filtro.isNotEmpty) {
      query.or('nombre.ilike.%$filtro%,documento.ilike.%$filtro%');
    }
    final response = await query.order('nombre');
    return (response as List<dynamic>)
        .map((row) => EmpleadoModel(
              id: row['id'] as String,
              documento: row['documento'] as String,
              nombre: row['nombre'] as String,
              rol: row['rol'] as String? ?? 'operador',
              supervisorId: row['supervisor_id'] as String?,
              email: row['email'] as String?,
              telefono: row['telefono'] as String?,
              activo: row['activo'] as bool? ?? true,
            ))
        .toList();
  }

  Future<void> guardar(EmpleadoModel empleado) async {
    final payload = {
      'id': empleado.id,
      'documento': empleado.documento,
      'nombre': empleado.nombre,
      'rol': empleado.rol,
      'supervisor_id': empleado.supervisorId,
      'email': empleado.email,
      'telefono': empleado.telefono,
      'activo': empleado.activo,
    };

    await _client.from('empleados').upsert(payload);
  }
}

