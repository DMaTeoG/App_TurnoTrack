# 📋 Schemas SQL - TurnoTrack

## 🆕 NUEVA ESTRUCTURA MODULAR (Noviembre 2025)

### ✅ Archivos del Proyecto

| Archivo | Contenido | Ejecutar |
|---------|-----------|----------|
| **01_SCHEMA_BASE.sql** | Tablas, índices, funciones, triggers, storage | ✅ **1º** |
| **02_RLS_POLICIES.sql** | Políticas de seguridad (RLS) y storage | ✅ **2º** |
| **03_verify_storage_buckets.sql** | Verificación de buckets (opcional) | 🟡 **3º** |
| **performance_indexes.sql** | Índices adicionales (opcional) | 🟡 Opcional |
| **RLS_ANALYSIS.md** | Documentación de políticas | 📖 Referencia |
| **DEPLOYMENT_GUIDE.md** | Guía de instalación | 📖 Referencia |

**Ventajas:**
- ✅ Separación clara entre estructura y seguridad
- ✅ Fácil revisar/modificar políticas sin tocar tablas
- ✅ Incluye función de **score ponderado** (Ventas 40%, Puntualidad 35%, Asistencia 25%)
- ✅ Políticas RLS **auditadas y corregidas** para evitar conflictos
- ✅ Archivos legacy eliminados para evitar confusión

---

## 🚀 Instrucciones de Instalación (Método Modular)

### Paso 1: Acceder a Supabase SQL Editor

1. Ve a [Supabase Dashboard](https://app.supabase.com/)
2. Selecciona tu proyecto TurnoTrack
3. Ve a la sección **SQL Editor** (icono de base de datos)

### Paso 2: Ejecutar Schema Base

1. Crea una nueva query (botón "New query")
2. Copia TODO el contenido de **`01_SCHEMA_BASE.sql`**
3. Pega en el editor SQL
4. Click en **"Run"** o presiona `Ctrl+Enter`
5. Espera mensaje: "✅ SCHEMA BASE COMPLETO"

**Contenido:**
- ✅ Extensiones (uuid-ossp, pgcrypto)
- ✅ 7 tablas con columna `average_check_in_time` agregada
- ✅ Índices optimizados
- ✅ Funciones: is_manager, is_supervisor, check_rate_limit, get_organization_kpis
- ✅ **Función de score ponderado**: calculate_weighted_attendance_score
- ✅ **Función batch**: update_performance_metrics_with_weighted_score
- ✅ Triggers (updated_at, audit)
- ✅ Storage buckets creados

### Paso 3: Aplicar Políticas de Seguridad

1. Abre una nueva query
2. Copia TODO el contenido de **`02_RLS_POLICIES.sql`**
3. Pega y ejecuta
4. Espera mensaje: "✅ POLÍTICAS RLS COMPLETAS"

**Contenido:**
- ✅ RLS habilitado en todas las tablas
- ✅ Políticas para users (con correcciones para supervisors)
- ✅ Políticas para attendance (supervisors pueden hacer check-in)
- ✅ Políticas para sales y performance_metrics
- ✅ Storage policies **corregidas** (paths flexibles)
- ✅ Documentación de **problemas comunes y soluciones**

### Paso 4: Verificar Instalación

Ejecuta en SQL Editor:

```sql
-- Verificar tablas
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' ORDER BY table_name;

-- Verificar políticas RLS
SELECT schemaname, tablename, policyname FROM pg_policies 
WHERE schemaname = 'public' ORDER BY tablename, policyname;

-- Verificar funciones
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';

-- Verificar columna nueva
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'performance_metrics' AND column_name = 'average_check_in_time';
```

**Resultado Esperado:**
- ✅ 7 tablas: users, attendance, locations, sales, performance_metrics, rate_limit_log, audit_log
- ✅ ~35 políticas RLS (incluye system_update_metrics nueva)
- ✅ 8 funciones (incluyendo calculate_weighted_attendance_score y update_performance_metrics_with_weighted_score)
- ✅ Columna `average_check_in_time` presente en performance_metrics

### Paso 5: Configurar Owner de Funciones (Importante)

```sql
-- Establecer owner correcto para funciones SECURITY DEFINER
ALTER FUNCTION calculate_weighted_attendance_score OWNER TO postgres;
ALTER FUNCTION update_performance_metrics_with_weighted_score OWNER TO postgres;
ALTER FUNCTION get_organization_kpis OWNER TO postgres;
ALTER FUNCTION is_manager OWNER TO postgres;
ALTER FUNCTION is_supervisor OWNER TO postgres;
```

### Paso 6: (Opcional) Automatizar Actualización de Métricas

```sql
-- Crear cron job para actualizar métricas diariamente
SELECT cron.schedule(
  'update-performance-metrics',
  '59 23 * * *',  -- 23:59 todos los días
  'SELECT update_performance_metrics_with_weighted_score();'
);
```

---

## 📁 Archivos del Proyecto

| Archivo | Propósito | Estado |
|---------|-----------|--------|
| **01_SCHEMA_BASE.sql** | Estructura completa (tablas, funciones, triggers) | ✅ Principal |
| **02_RLS_POLICIES.sql** | Políticas de seguridad y storage | ✅ Principal |
| **03_verify_storage_buckets.sql** | Verificación de buckets | 🟡 Opcional |
| **performance_indexes.sql** | Índices adicionales | 🟡 Opcional |
| **RLS_ANALYSIS.md** | Documentación detallada de políticas | 📖 Referencia |
| **DEPLOYMENT_GUIDE.md** | Guía de instalación paso a paso | � Referencia |

---

## ⚠️ Problemas Comunes Resueltos

### 1. ❌ "new row violates row-level security policy"
**Causa:** Políticas muy restrictivas  
**Solución:** ✅ Aplicada en `02_RLS_POLICIES.sql`
- Política `system_write_metrics` con CHECK(true) para funciones batch
- Storage policies con paths flexibles

### 2. ❌ Supervisor no puede hacer check-in
**Causa:** Política solo permitía role='worker'  
**Solución:** ✅ Política `workers_create_own_attendance` ahora incluye supervisors

### 3. ❌ No se puede crear usuario nuevo
**Causa:** Faltaban políticas INSERT  
**Solución:** ✅ Políticas `supervisors_create_workers` y `managers_create_users` agregadas

### 4. ❌ Worker no puede cambiar foto/teléfono
**Causa:** Validación demasiado estricta  
**Solución:** ✅ Política `workers_update_own_profile` mejorada

### 5. ❌ Columna `average_check_in_time` no existe
**Causa:** Faltaba en schema original  
**Solución:** ✅ Columna agregada en `01_SCHEMA_BASE.sql`

---

## 📊 Función de Score Ponderado

### Fórmula
```
Score Total = (Ventas × 0.40) + (Puntualidad × 0.35) + (Asistencia × 0.25)
```

### Uso Manual
```sql
-- Calcular score de un usuario específico
SELECT calculate_weighted_attendance_score(
  'UUID_DEL_USUARIO',
  '2025-11-01'::DATE,
  '2025-11-30'::DATE
);

-- Actualizar todas las métricas
SELECT update_performance_metrics_with_weighted_score();
```

---

## 🌱 Seed Data para Testing

Para probar la aplicación con datos de ejemplo, ejecuta este script en SQL Editor:

```sql
-- ⚠️ IMPORTANTE: Primero debes crear estos usuarios en Supabase Auth
-- Ve a Authentication > Users > Add User y crea:
-- 1. manager@test.com (password: Test123!)
-- 2. supervisor@test.com (password: Test123!)
-- 3. worker@test.com (password: Test123!)

-- Luego copia sus UUIDs y reemplázalos aquí:

-- Insertar Manager
INSERT INTO public.users (
  id, 
  email, 
  full_name, 
  role, 
  is_active
) VALUES (
  'UUID_DEL_MANAGER',  -- Reemplaza con el UUID real
  'manager@test.com',
  'Nicolás García (Manager)',
  'manager',
  true
);

-- Insertar Supervisor
INSERT INTO public.users (
  id, 
  email, 
  full_name, 
  role, 
  is_active
) VALUES (
  'UUID_DEL_SUPERVISOR',  -- Reemplaza con el UUID real
  'supervisor@test.com',
  'Vanessa Burbano (Supervisor)',
  'supervisor',
  true
);

-- Insertar Worker
INSERT INTO public.users (
  id, 
  email, 
  full_name, 
  role, 
  supervisor_id,
  is_active
) VALUES (
  'UUID_DEL_WORKER',  -- Reemplaza con el UUID real
  'worker@test.com',
  'Natalie Gomez (Worker)',
  'worker',
  'UUID_DEL_SUPERVISOR',  -- Asignar al supervisor
  true
);

-- ⚠️ IMPORTANTE: Creación de Usuarios desde la App
-- =====================================================
-- Cuando creas usuarios desde Flutter, el sistema ahora:
-- 1️⃣ Crea el usuario en Supabase Auth (con password temporal)
-- 2️⃣ Crea el registro en la tabla users
-- 3️⃣ El usuario aparecerá en Authentication > Users
-- 
-- Password temporal: Se genera automáticamente (8 caracteres)
-- El usuario debe cambiar su password en el primer login
-- =====================================================

-- Insertar datos de asistencia de ejemplo (últimos 7 días)
INSERT INTO public.attendance (
  user_id,
  date,
  check_in_time,
  check_out_time,
  check_in_photo_url,
  check_out_photo_url,
  check_in_latitude,
  check_in_longitude,
  check_in_address,
  is_late,
  minutes_late
) VALUES 
  -- Worker asistencia de la semana
  ('UUID_DEL_WORKER', CURRENT_DATE - INTERVAL '1 day', '08:00:00', '17:00:00', 'https://via.placeholder.com/150', 'https://via.placeholder.com/150', 19.4326, -99.1332, 'Ciudad de México', false, 0),
  ('UUID_DEL_WORKER', CURRENT_DATE - INTERVAL '2 days', '08:15:00', '17:05:00', 'https://via.placeholder.com/150', 'https://via.placeholder.com/150', 19.4326, -99.1332, 'Ciudad de México', true, 15),
  ('UUID_DEL_WORKER', CURRENT_DATE - INTERVAL '3 days', '07:55:00', '17:00:00', 'https://via.placeholder.com/150', 'https://via.placeholder.com/150', 19.4326, -99.1332, 'Ciudad de México', false, 0),
  ('UUID_DEL_WORKER', CURRENT_DATE - INTERVAL '4 days', '08:00:00', '17:10:00', 'https://via.placeholder.com/150', 'https://via.placeholder.com/150', 19.4326, -99.1332, 'Ciudad de México', false, 0),
  ('UUID_DEL_WORKER', CURRENT_DATE - INTERVAL '5 days', '08:30:00', '17:00:00', 'https://via.placeholder.com/150', 'https://via.placeholder.com/150', 19.4326, -99.1332, 'Ciudad de México', true, 30);

-- Insertar métricas de performance
INSERT INTO public.performance_metrics (
  user_id,
  date,
  attendance_score,
  punctuality_percentage,
  total_check_ins,
  late_check_ins
) VALUES 
  ('UUID_DEL_WORKER', CURRENT_DATE - INTERVAL '1 day', 95, 80, 5, 2);

-- Verificar que los datos se insertaron correctamente
SELECT 
  u.full_name,
  u.email,
  u.role,
  COUNT(a.id) as total_asistencias
FROM users u
LEFT JOIN attendance a ON u.id = a.user_id
GROUP BY u.id, u.full_name, u.email, u.role
ORDER BY u.role DESC;
```

**Notas:**
- ✅ Los UUIDs deben ser copiados desde Supabase Auth después de crear los usuarios
- ✅ Las fotos usan placeholders (https://via.placeholder.com/150)
- ✅ En producción, las fotos deben subirse a los buckets de Storage
- ✅ Puedes agregar más workers modificando el script

---

## 🔒 Seguridad Implementada

### Row Level Security (RLS)

Las políticas implementadas garantizan:

| Tabla | Worker | Supervisor | Manager |
|-------|--------|------------|---------|
| `users` | Solo su perfil | Su equipo + su perfil | Todos |
| `attendance` | Solo sus registros | Su equipo | Todos |
| `locations` | Solo lectura | Solo lectura | CRUD completo |
| `performance_metrics` | Solo sus métricas | Su equipo | Todos |
| `sales` | CRUD propias | Lectura de equipo | Todos |
| `rate_limit_log` | ❌ No acceso | ❌ No acceso | Solo lectura |
| `audit_log` | ❌ No acceso | ❌ No acceso | Solo lectura |

### Rate Limiting

```sql
-- Límite: 10 check-ins por hora
SELECT check_rate_limit(
  auth.uid(),        -- ID del usuario
  'check_in',        -- Tipo de acción
  10,                -- Máximo de requests
  60                 -- Ventana en minutos
);
```

### Audit Trail

Todos los cambios en la tabla `users` se registran automáticamente en `audit_log` con:
- ✅ Usuario que hizo el cambio
- ✅ Acción realizada (INSERT, UPDATE, DELETE)
- ✅ Datos anteriores (old_data)
- ✅ Datos nuevos (new_data)
- ✅ Timestamp

---

## 🗑️ Reiniciar Base de Datos (Si hay problemas)

Si algo sale mal y necesitas empezar de cero:

```sql
-- ⚠️ PELIGRO: Esto borra TODO
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- Luego ejecuta nuevamente 00_CONSOLIDATED_SCHEMA.sql
```

---

## 📝 Notas Importantes

### Sobre Firebase

**Firebase NO es necesario** para este proyecto. Todas las notificaciones se manejan con:
- **flutter_local_notifications** (notificaciones locales)
- **Supabase Edge Functions** (notificaciones push futuras)
- **timezone** (notificaciones programadas)

El archivo `lib/firebase_options.dart` está vacío intencionalmente.

### Sobre los Esquemas Antiguos

Los archivos `01_schema.sql` y `02_rls_policies.sql` se mantienen para referencia histórica, pero **NO deben ser ejecutados**. Si los ejecutas junto con el consolidado, causarán errores como:

```
ERROR: policy "workers_read_own_profile" for table "users" already exists
```

### Cambios en el Esquema Consolidado

El esquema consolidado mejora el original con:

1. **Tabla `attendance` mejorada:**
   - Campos separados para check-in y check-out
   - Constraint para evitar duplicados por día
   - Campos `is_late` y `minutes_late`

2. **Validaciones adicionales:**
   - CHECK constraints en cantidades y porcentajes
   - ON DELETE CASCADE/SET NULL apropiados
   - UNIQUE constraints donde corresponde

3. **Índices optimizados:**
   - Índices parciales (WHERE clauses)
   - Índices compuestos para queries comunes
   - Índices descendentes para ordenamiento

---

## 🆘 Troubleshooting

### Error: "policy already exists"

**Causa:** Ejecutaste múltiples archivos SQL que definen las mismas políticas.

**Solución:**
```sql
-- Eliminar todas las políticas de una tabla
DROP POLICY IF EXISTS "nombre_politica" ON tabla_nombre;

-- O reiniciar todo (ver sección anterior)
```

### Error: "relation already exists"

**Causa:** Ejecutaste el script múltiples veces.

**Solución:** El script usa `CREATE TABLE IF NOT EXISTS`, así que es seguro re-ejecutarlo. Si hay problemas, reinicia la base de datos.

### No puedo crear usuarios

**Causa:** Las políticas RLS están bloqueando la creación.

**Solución:**
1. Verifica que estés autenticado (`auth.uid()` no es null)
2. Verifica tu rol en la tabla `users`
3. Los supervisors solo pueden crear workers
4. Los managers pueden crear workers y supervisors

---

## 📚 Recursos Adicionales

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL Policy Documentation](https://www.postgresql.org/docs/current/sql-createpolicy.html)
- [Supabase Storage Documentation](https://supabase.com/docs/guides/storage)

---

**Última actualización:** 2 de Noviembre, 2025  
**Versión del Schema:** 1.0 (Consolidado)
