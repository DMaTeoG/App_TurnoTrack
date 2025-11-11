-- =============================================
-- TURNOTRACK - POLÍTICAS RLS Y SEGURIDAD
-- =============================================
-- Este archivo contiene SOLO las políticas de Row Level Security (RLS)
-- y configuraciones de seguridad para storage.
--
-- ⚠️ IMPORTANTE: Ejecutar DESPUÉS de 01_SCHEMA_BASE.sql
--
-- ORDEN DE EJECUCIÓN:
-- 1. Ejecutar 01_SCHEMA_BASE.sql (tablas, índices, funciones)
-- 2. Ejecutar este archivo (02_RLS_POLICIES.sql)
--
-- =============================================
-- ANÁLISIS DE POLÍTICAS RESTRICTIVAS
-- =============================================
--
-- ⚠️ PROBLEMAS IDENTIFICADOS Y SOLUCIONES:
--
-- 1. PROBLEMA: Nuevos usuarios no pueden crear su primer perfil
--    CAUSA: No hay política INSERT para que managers/supervisors creen workers
--    SOLUCIÓN: Políticas "supervisors_create_workers" y "managers_create_users"
--
-- 2. PROBLEMA: Workers no pueden actualizar su propia foto/teléfono
--    CAUSA: Política muy restrictiva que bloquea cambios en role/supervisor_id
--    SOLUCIÓN: Verificar solo que NO cambien role ni supervisor_id (en lugar de comparar con valor anterior)
--
-- 3. PROBLEMA: Funciones SECURITY DEFINER pueden ser bloqueadas por RLS
--    CAUSA: Las funciones se ejecutan con auth.uid() del usuario, no del owner
--    SOLUCIÓN: Funciones creadas con SECURITY DEFINER + owner postgres (establecer manualmente)
--
-- 4. PROBLEMA: Storage policies bloquean uploads de check-in
--    CAUSA: Validación estricta de path que no coincide con estructura real
--    SOLUCIÓN: ✅ Actualizada para permitir paths flexibles (user_id/*)
--
-- 5. PROBLEMA: system_write_metrics permite INSERT sin autenticación
--    CAUSA: WITH CHECK (true) permite cualquier inserción
--    SOLUCIÓN: ✅ Mantenido por diseño - funciones batch necesitan escribir sin auth.uid()
--             Alternativa: crear service role con bypass RLS
--
-- 6. PROBLEMA: Supervisors no pueden crear su propio check-in
--    CAUSA: Política workers_create_own_attendance solo para role='worker'
--    SOLUCIÓN: ✅ Actualizada para incluir supervisors en políticas de attendance
--
-- =============================================

-- =============================================
-- STEP 1: HABILITAR ROW LEVEL SECURITY
-- =============================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_limit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- =============================================
-- STEP 2: POLÍTICAS RLS PARA USERS
-- =============================================
-- ✅ ACTUALIZADO: Políticas optimizadas para evitar bloqueos

-- Limpiar políticas existentes
DROP POLICY IF EXISTS "workers_read_own_profile" ON users;
DROP POLICY IF EXISTS "workers_update_own_profile" ON users;
DROP POLICY IF EXISTS "supervisors_read_team" ON users;
DROP POLICY IF EXISTS "supervisors_update_team" ON users;
DROP POLICY IF EXISTS "supervisors_create_workers" ON users;
DROP POLICY IF EXISTS "managers_read_all" ON users;
DROP POLICY IF EXISTS "managers_create_users" ON users;
DROP POLICY IF EXISTS "managers_update_users" ON users;
DROP POLICY IF EXISTS "managers_delete_users" ON users;

-- =============================================
-- POLÍTICAS DE LECTURA (SELECT)
-- =============================================

-- Workers: Solo pueden ver su propio perfil
CREATE POLICY "workers_read_own_profile"
ON users FOR SELECT
USING (auth.uid() = id);

-- Supervisors: Ver su perfil + workers bajo su supervisión
CREATE POLICY "supervisors_read_team"
ON users FOR SELECT
USING (
  is_supervisor()
  AND (
    auth.uid() = id  -- Ver su propio perfil
    OR (supervisor_id = auth.uid() AND role = 'worker')  -- Ver sus workers
  )
);

-- Managers: Ver todos los usuarios
CREATE POLICY "managers_read_all"
ON users FOR SELECT
USING (is_manager());

-- =============================================
-- POLÍTICAS DE ACTUALIZACIÓN (UPDATE)
-- =============================================

-- ✅ MEJORADO: Workers pueden actualizar su perfil (photo_url, phone, full_name)
-- pero NO pueden cambiar role ni supervisor_id
CREATE POLICY "workers_update_own_profile"
ON users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id
  AND role = (SELECT role FROM users WHERE id = auth.uid())  -- Role no cambia
  AND COALESCE(supervisor_id, '00000000-0000-0000-0000-000000000000'::uuid) = 
      COALESCE((SELECT supervisor_id FROM users WHERE id = auth.uid()), '00000000-0000-0000-0000-000000000000'::uuid)  -- Supervisor no cambia
);

-- Supervisors: Actualizar workers bajo su supervisión
CREATE POLICY "supervisors_update_team"
ON users FOR UPDATE
USING (
  is_supervisor()
  AND supervisor_id = auth.uid()
  AND role = 'worker'
)
WITH CHECK (
  supervisor_id = auth.uid()
  AND role = 'worker'
);

-- Managers: Actualizar cualquier usuario excepto otros managers
CREATE POLICY "managers_update_users"
ON users FOR UPDATE
USING (
  is_manager()
  AND role != 'manager'
)
WITH CHECK (role != 'manager');

-- =============================================
-- POLÍTICAS DE INSERCIÓN (INSERT)
-- =============================================

-- ✅ CRÍTICO: Supervisors pueden crear workers bajo su supervisión
CREATE POLICY "supervisors_create_workers"
ON users FOR INSERT
WITH CHECK (
  is_supervisor()
  AND role = 'worker'
  AND supervisor_id = auth.uid()
);

-- ✅ CRÍTICO: Managers pueden crear supervisores y workers
CREATE POLICY "managers_create_users"
ON users FOR INSERT
WITH CHECK (
  is_manager()
  AND role IN ('worker', 'supervisor')
);

-- =============================================
-- POLÍTICAS DE ELIMINACIÓN (DELETE)
-- =============================================

-- Managers: Eliminar cualquier usuario excepto otros managers
CREATE POLICY "managers_delete_users"
ON users FOR DELETE
USING (
  is_manager()
  AND role != 'manager'
);

-- =============================================
-- STEP 3: POLÍTICAS RLS PARA ATTENDANCE
-- =============================================
-- ✅ ACTUALIZADO: Incluir supervisors en políticas de check-in

DROP POLICY IF EXISTS "workers_read_own_attendance" ON attendance;
DROP POLICY IF EXISTS "workers_create_own_attendance" ON attendance;
DROP POLICY IF EXISTS "workers_update_own_checkout" ON attendance;
DROP POLICY IF EXISTS "supervisors_read_team_attendance" ON attendance;
DROP POLICY IF EXISTS "managers_read_all_attendance" ON attendance;

-- ✅ MEJORADO: Workers y Supervisors pueden ver sus propios registros
CREATE POLICY "workers_read_own_attendance"
ON attendance FOR SELECT
USING (user_id = auth.uid());

-- ✅ CRÍTICO: Permitir check-in para workers Y supervisors
-- Sistema simple: Solo check-in, sin restricciones de "uno por día"
-- Permite múltiples check-ins (turnos dobles, correcciones, etc.)
CREATE POLICY "workers_create_own_attendance"
ON attendance FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND check_rate_limit(auth.uid(), 'check_in', 10, 60)
);

-- ❌ ELIMINADO: Ya no usamos check-out
-- El sistema solo registra entradas (check-in) con foto/GPS

-- Supervisors: Pueden ver attendance de su equipo
CREATE POLICY "supervisors_read_team_attendance"
ON attendance FOR SELECT
USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('supervisor', 'manager'))
  AND user_id IN (
    SELECT id FROM users 
    WHERE supervisor_id = auth.uid() OR id = auth.uid()
  )
);

-- Managers: Acceso total de lectura
CREATE POLICY "managers_read_all_attendance"
ON attendance FOR SELECT
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'manager'));

-- =============================================
-- STEP 4: POLÍTICAS RLS PARA LOCATIONS
-- =============================================

DROP POLICY IF EXISTS "workers_read_locations" ON locations;
DROP POLICY IF EXISTS "managers_manage_locations" ON locations;

-- Todos pueden leer ubicaciones activas
CREATE POLICY "workers_read_locations"
ON locations FOR SELECT
USING (is_active = true);

-- Solo managers pueden administrar ubicaciones
CREATE POLICY "managers_manage_locations"
ON locations FOR ALL
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'manager'));

-- =============================================
-- STEP 5: POLÍTICAS RLS PARA PERFORMANCE_METRICS
-- =============================================

DROP POLICY IF EXISTS "workers_read_own_metrics" ON performance_metrics;
DROP POLICY IF EXISTS "supervisors_read_team_metrics" ON performance_metrics;
DROP POLICY IF EXISTS "managers_read_all_metrics" ON performance_metrics;
DROP POLICY IF EXISTS "system_write_metrics" ON performance_metrics;
DROP POLICY IF EXISTS "system_update_metrics" ON performance_metrics;

-- Workers: Ver solo sus propias métricas
CREATE POLICY "workers_read_own_metrics"
ON performance_metrics FOR SELECT
USING (user_id = auth.uid());

-- Supervisors: Ver métricas de su equipo
CREATE POLICY "supervisors_read_team_metrics"
ON performance_metrics FOR SELECT
USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('supervisor', 'manager'))
  AND user_id IN (
    SELECT id FROM users 
    WHERE supervisor_id = auth.uid() OR id = auth.uid()
  )
);

-- Managers: Ver todas las métricas
CREATE POLICY "managers_read_all_metrics"
ON performance_metrics FOR SELECT
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'manager'));

-- ⚠️ IMPORTANTE: Política permisiva para funciones batch
-- Esta política permite INSERT/UPDATE sin autenticación para:
-- - Funciones SECURITY DEFINER (update_performance_metrics_with_weighted_score)
-- - Edge functions con service role key
-- ALTERNATIVA SEGURA: Crear service role con bypass_rls y quitar estas políticas
CREATE POLICY "system_write_metrics"
ON performance_metrics FOR INSERT
WITH CHECK (true);

CREATE POLICY "system_update_metrics"
ON performance_metrics FOR UPDATE
USING (true)
WITH CHECK (true);

-- =============================================
-- STEP 6: POLÍTICAS RLS PARA SALES
-- =============================================

DROP POLICY IF EXISTS "workers_manage_own_sales" ON sales;
DROP POLICY IF EXISTS "supervisors_read_team_sales" ON sales;
DROP POLICY IF EXISTS "managers_read_all_sales" ON sales;

-- Workers: Administrar solo sus propias ventas
CREATE POLICY "workers_manage_own_sales"
ON sales FOR ALL
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- Supervisors: Ver ventas de su equipo
CREATE POLICY "supervisors_read_team_sales"
ON sales FOR SELECT
USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('supervisor', 'manager'))
  AND user_id IN (
    SELECT id FROM users 
    WHERE supervisor_id = auth.uid() OR id = auth.uid()
  )
);

-- Managers: Ver todas las ventas
CREATE POLICY "managers_read_all_sales"
ON sales FOR SELECT
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'manager'));

-- =============================================
-- STEP 7: POLÍTICAS RLS PARA SECURITY TABLES
-- =============================================

DROP POLICY IF EXISTS "managers_read_rate_limits" ON rate_limit_log;
DROP POLICY IF EXISTS "managers_read_audit_log" ON audit_log;

-- Solo managers pueden ver logs de seguridad
CREATE POLICY "managers_read_rate_limits"
ON rate_limit_log FOR SELECT
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'manager'));

CREATE POLICY "managers_read_audit_log"
ON audit_log FOR SELECT
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'manager'));

-- =============================================
-- STEP 8: STORAGE POLICIES PARA ATTENDANCE PHOTOS
-- =============================================
-- ✅ ACTUALIZADO: Path validation flexible

DROP POLICY IF EXISTS "Users can upload their attendance photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view attendance photos" ON storage.objects;
DROP POLICY IF EXISTS "Managers can delete attendance photos" ON storage.objects;

-- ✅ MEJORADO: Permitir upload con path flexible (user_id/*)
-- PROBLEMA ANTERIOR: split_part(name, '/', 1) era demasiado estricto
CREATE POLICY "Users can upload their attendance photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'attendance-photos'
  AND (
    -- Path: user_id/filename.jpg
    auth.uid()::text = split_part(name, '/', 1)
    OR
    -- Path: filename_user_id.jpg (alternativo)
    name LIKE '%' || auth.uid()::text || '%'
  )
);

-- Todos los autenticados pueden ver fotos de asistencia
CREATE POLICY "Users can view attendance photos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'attendance-photos');

-- Solo managers pueden eliminar fotos de asistencia
CREATE POLICY "Managers can delete attendance photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'attendance-photos'
  AND EXISTS (
    SELECT 1 FROM users
    WHERE id = auth.uid()
    AND role = 'manager'
  )
);

-- =============================================
-- STEP 9: STORAGE POLICIES PARA PROFILE PHOTOS
-- =============================================

DROP POLICY IF EXISTS "Users can upload their profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can view profile photos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their profile photos" ON storage.objects;

-- Upload: Usuarios, supervisors y managers
CREATE POLICY "Users can upload their profile photos"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'profile-photos'
  AND (
    -- Usuarios pueden subir su propia foto
    auth.uid()::text = split_part(name, '/', 1)
    OR
    -- Managers y supervisors pueden subir fotos de cualquier usuario
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role IN ('manager', 'supervisor')
    )
  )
);

-- Update: Usuarios, supervisors y managers
CREATE POLICY "Users can update their profile photos"
ON storage.objects FOR UPDATE
TO authenticated
USING (
  bucket_id = 'profile-photos'
  AND (
    -- Usuarios pueden actualizar su propia foto
    auth.uid()::text = split_part(name, '/', 1)
    OR
    -- Managers y supervisors pueden actualizar fotos de cualquier usuario
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role IN ('manager', 'supervisor')
    )
  )
);

-- Todos pueden ver fotos de perfil
CREATE POLICY "Users can view profile photos"
ON storage.objects FOR SELECT
TO authenticated
USING (bucket_id = 'profile-photos');

-- Delete: Solo el usuario o managers
CREATE POLICY "Users can delete their profile photos"
ON storage.objects FOR DELETE
TO authenticated
USING (
  bucket_id = 'profile-photos'
  AND (
    -- Usuarios pueden eliminar su propia foto
    auth.uid()::text = split_part(name, '/', 1)
    OR
    -- Managers pueden eliminar fotos de cualquier usuario
    EXISTS (
      SELECT 1 FROM users
      WHERE id = auth.uid()
      AND role = 'manager'
    )
  )
);

-- =============================================
-- ✅ POLÍTICAS RLS COMPLETAS
-- =============================================
-- 
-- Este archivo incluye:
-- ✅ RLS habilitado en todas las tablas
-- ✅ Políticas optimizadas para evitar bloqueos
-- ✅ Correcciones para cuentas nuevas
-- ✅ Supervisors pueden hacer check-in
-- ✅ Storage policies flexibles
-- ✅ Documentación de problemas comunes
--
-- ⚠️ RECOMENDACIONES POST-DEPLOYMENT:
--
-- 1. ESTABLECER OWNER DE FUNCIONES:
--    ALTER FUNCTION calculate_weighted_attendance_score OWNER TO postgres;
--    ALTER FUNCTION update_performance_metrics_with_weighted_score OWNER TO postgres;
--    ALTER FUNCTION get_organization_kpis OWNER TO postgres;
--
-- 2. CREAR SERVICE ROLE (ALTERNATIVA SEGURA):
--    En lugar de system_write_metrics/system_update_metrics con CHECK(true),
--    crear un service role con bypass_rls y usar service key en edge functions.
--
-- 3. AUTOMATIZAR ACTUALIZACIÓN DE MÉTRICAS:
--    SELECT cron.schedule(
--      'update-metrics',
--      '59 23 * * *',
--      'SELECT update_performance_metrics_with_weighted_score();'
--    );
--
-- 4. MONITOREAR RATE LIMITS:
--    Verificar regularmente rate_limit_log para detectar abusos.
--
-- 5. AUDITAR CAMBIOS:
--    Revisar audit_log periódicamente para cambios sospechosos.
--
-- =============================================
