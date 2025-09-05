# Politicas RLS

## Roles y alcance
- **admin**: acceso total a tablas y buckets (gestion y auditoria).
- **supervisor**: acceso a empleados asignados y sus registros.
- **operador**: solo puede ver y editar sus propios registros.

## Politicas por tabla
- `empleados`: admin CRUD completo. Supervisor `SELECT/UPDATE` cuando `supervisor_id = auth.uid()`. Operador solo `SELECT` de su propio registro.
- `registros`: admin sin restricciones. Supervisor puede `SELECT` cuando `empleado.supervisor_id = auth.uid()`. Operador solo `INSERT` y `SELECT` cuando `empleado_id = auth.uid()`.
- `desempeno_semana`: admin full; supervisor limitado a su equipo; operador solo sus filas.
- Storage `registros`: policy usando `storage.foldername(author_uid)` y verificacion contra tabla `registros`.

## Ejemplos de queries
- ✅ Supervisor consulta registros de su equipo: `select * from registros where supervisor_id = auth.uid();`
- ❌ Supervisor intenta ver otro equipo: mismo query con `supervisor_id <> auth.uid()` falla con 401.
- ✅ Operador inserta entrada: `insert into registros ... empleado_id = auth.uid()`.
- ❌ Operador intenta borrar registro: `DELETE` bloqueado por policy.

## Testing RLS
1. Generar JWT simulados usando `supabase tools user impersonate`.
2. Ejecutar scripts `test/rls_policies_test.dart` con `supabase` en modo local.
3. Validar que cada rol pase solo los escenarios permitidos.
4. Automatizar en CI usando `supabase start` + `psql` para asserts.
