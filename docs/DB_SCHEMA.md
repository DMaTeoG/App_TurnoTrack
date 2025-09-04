# Esquema de base de datos

## Tablas principales (resumen)
- `empleados`: id (uuid), documento, nombre, foto_url, supervisor_id, estado.
- `supervisores`: id (uuid), documento, nombre, email, telefono, activo.
- `registros`: id (uuid), empleado_id, tipo (`entrada`/`salida`), tomado_en (timestamp tz), lat, lng, precision_m, evidencia_url, codigo_validacion, creado_por, synced_at.
- `sesiones_operador`: empleado_id, inicio_turno, fin_turno, metadata_dispositivo.
- `desempeno_semana`: empleado_id, semana_iso, score, horas_efectivas, puntualidad_pct, incidencias.
- `coaching_hist`: id, empleado_id, semana_iso, consejo_es, consejo_en, generado_el.

## Indices y racional
- `empleados(documento)` unico para validar duplicados y facilitar busquedas.
- `registros(empleado_id, tomado_en)` compuesta para reportes por rango.
- `registros(tomado_en desc)` para dashboards cronologicos.
- `desempeno_semana(semana_iso, supervisor_id)` index para ranking por equipo.
- Uso de extensiones: `earthdistance` o `cube` opcional para calculos geograficos.

## Triggers y validaciones
- Trigger `trg_registros_consecutivo`: asegura alternancia entrada/salida y evita duplicados.
- Trigger `trg_registros_precision`: rechaza registros con precision_m > 10.
- Trigger `trg_registros_codigo`: autogenera codigo de verificacion (hash random 6 caracteres).
- Trigger `trg_desempeno_hist`: al insertar score dispara registro en `coaching_hist` con edge function.

## Storage y archivos
- Bucket `registros`: evidencia fotografica. Estructura `registros/YYYY/MM/DD/<uuid>.jpg`.
- Bucket `exports`: CSV generados. Estructura `exports/<yyyy-mm-dd>/<org>-<timestamp>.csv` con expiracion 24 h.
- Metadata de archivos almacena lat/lng, precision y hash de dispositivo.
