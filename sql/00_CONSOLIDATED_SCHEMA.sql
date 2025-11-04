-- =============================================
-- TURNOTRACK - SCHEMA CONSOLIDADO COMPLETO
-- =============================================
-- Este archivo consolida TODOS los esquemas y políticas
-- para evitar conflictos y duplicaciones.
--
-- Ejecutar en orden en Supabase SQL Editor:
-- 1. Este archivo completo (00_CONSOLIDATED_SCHEMA.sql)
-- 2. NO ejecutar 01_schema.sql ni 02_rls_policies.sql
--
-- =============================================

-- =============================================
-- STEP 1: EXTENSIONES
-- =============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================
-- STEP 2: CREAR TABLAS
-- =============================================

-- USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('worker', 'supervisor', 'manager')),
    is_active BOOLEAN DEFAULT true,
    photo_url TEXT,
    phone TEXT,
    supervisor_id UUID REFERENCES users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- LOCATIONS TABLE
CREATE TABLE IF NOT EXISTS locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    radius_meters DOUBLE PRECISION DEFAULT 100,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ATTENDANCE TABLE
CREATE TABLE IF NOT EXISTS attendance (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    check_in_time TIMESTAMP WITH TIME ZONE NOT NULL,
    check_out_time TIMESTAMP WITH TIME ZONE,
    check_in_latitude DOUBLE PRECISION NOT NULL,
    check_in_longitude DOUBLE PRECISION NOT NULL,
    check_out_latitude DOUBLE PRECISION,
    check_out_longitude DOUBLE PRECISION,
    check_in_photo_url TEXT NOT NULL,
    check_out_photo_url TEXT,
    check_in_address TEXT,
    check_out_address TEXT,
    is_late BOOLEAN DEFAULT false,
    minutes_late INTEGER DEFAULT 0,
    synced BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SALES TABLE
CREATE TABLE IF NOT EXISTS sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    amount DECIMAL(12, 2) NOT NULL CHECK (amount >= 0),
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    product_category TEXT,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- PERFORMANCE METRICS TABLE
CREATE TABLE IF NOT EXISTS performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    attendance_score INTEGER NOT NULL CHECK (attendance_score >= 0 AND attendance_score <= 100),
    punctuality_rate DECIMAL(5, 2) CHECK (punctuality_rate >= 0 AND punctuality_rate <= 100),
    total_check_ins INTEGER DEFAULT 0 CHECK (total_check_ins >= 0),
    late_check_ins INTEGER DEFAULT 0 CHECK (late_check_ins >= 0),
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    ai_recommendations JSONB DEFAULT '[]'::jsonb,
    ranking INTEGER,
    badges JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, period_start, period_end),
    CHECK (period_end >= period_start)
);

-- RATE LIMIT LOG TABLE
CREATE TABLE IF NOT EXISTS rate_limit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    action_type VARCHAR(50) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    ip_address INET
);

-- AUDIT LOG TABLE
CREATE TABLE IF NOT EXISTS audit_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    table_name TEXT NOT NULL,
    record_id UUID NOT NULL,
    action TEXT NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data JSONB,
    new_data JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =============================================
-- STEP 3: CREAR ÍNDICES
-- =============================================

-- Users indices
CREATE INDEX IF NOT EXISTS idx_users_supervisor ON users(supervisor_id);
CREATE INDEX IF NOT EXISTS idx_users_active ON users(is_active);
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Locations indices
CREATE INDEX IF NOT EXISTS idx_locations_active ON locations(is_active);

-- Attendance indices
CREATE INDEX IF NOT EXISTS idx_attendance_user ON attendance(user_id);
CREATE INDEX IF NOT EXISTS idx_attendance_check_in ON attendance(check_in_time DESC);
CREATE INDEX IF NOT EXISTS idx_attendance_date ON attendance(check_in_time);
CREATE INDEX IF NOT EXISTS idx_attendance_user_date ON attendance(user_id, check_in_time);

-- Sales indices
CREATE INDEX IF NOT EXISTS idx_sales_user ON sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(date DESC);
CREATE INDEX IF NOT EXISTS idx_sales_user_date ON sales(user_id, date);

-- Performance metrics indices
CREATE INDEX IF NOT EXISTS idx_performance_user ON performance_metrics(user_id);
CREATE INDEX IF NOT EXISTS idx_performance_period ON performance_metrics(period_start, period_end);
CREATE INDEX IF NOT EXISTS idx_performance_ranking ON performance_metrics(ranking);

-- Rate limit indices
CREATE INDEX IF NOT EXISTS idx_rate_limit_user_action ON rate_limit_log(user_id, action_type, created_at DESC);

-- Audit log indices
CREATE INDEX IF NOT EXISTS idx_audit_log_user ON audit_log(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_log_table ON audit_log(table_name, record_id);

-- =============================================
-- STEP 4: FUNCIONES AUXILIARES
-- =============================================

-- Función para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Función para verificar si un usuario es manager
CREATE OR REPLACE FUNCTION is_manager()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role = 'manager'
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar si un usuario es supervisor
CREATE OR REPLACE FUNCTION is_supervisor()
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('supervisor', 'manager')
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para obtener workers de un supervisor
CREATE OR REPLACE FUNCTION get_supervisor_team(supervisor_uuid UUID)
RETURNS SETOF users AS $$
BEGIN
  RETURN QUERY
  SELECT * FROM users
  WHERE supervisor_id = supervisor_uuid AND role = 'worker' AND is_active = true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para verificar rate limit
CREATE OR REPLACE FUNCTION check_rate_limit(
  p_user_id UUID,
  p_action VARCHAR,
  p_max_requests INT DEFAULT 10,
  p_window_minutes INT DEFAULT 60
)
RETURNS BOOLEAN AS $$
DECLARE
  request_count INT;
BEGIN
  SELECT COUNT(*) INTO request_count
  FROM rate_limit_log
  WHERE user_id = p_user_id
    AND action_type = p_action
    AND created_at > NOW() - (p_window_minutes || ' minutes')::INTERVAL;
  
  IF request_count >= p_max_requests THEN 
    RETURN FALSE; 
  END IF;
  
  INSERT INTO rate_limit_log (user_id, action_type) 
  VALUES (p_user_id, p_action);
  
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Función para registrar cambios en audit log
CREATE OR REPLACE FUNCTION audit_users_changes()
RETURNS TRIGGER AS $$
BEGIN
  IF (TG_OP = 'UPDATE') THEN
    INSERT INTO audit_log (user_id, table_name, record_id, action, old_data, new_data)
    VALUES (
      auth.uid(),
      TG_TABLE_NAME,
      OLD.id,
      'UPDATE',
      to_jsonb(OLD),
      to_jsonb(NEW)
    );
    RETURN NEW;
  ELSIF (TG_OP = 'DELETE') THEN
    INSERT INTO audit_log (user_id, table_name, record_id, action, old_data)
    VALUES (
      auth.uid(),
      TG_TABLE_NAME,
      OLD.id,
      'DELETE',
      to_jsonb(OLD)
    );
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- Función para obtener KPIs organizacionales (Managers)
-- =============================================
CREATE OR REPLACE FUNCTION get_organization_kpis(
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE
)
RETURNS JSON AS $$
DECLARE
  result JSON;
  total_employees INT;
  active_employees INT;
  total_check_ins INT;
  on_time_check_ins INT;
  late_check_ins INT;
  punctuality_rate DECIMAL(5,2);
  avg_attendance_score DECIMAL(5,2);
  total_sales_amount DECIMAL(12,2);
BEGIN
  -- Verificar que el usuario sea manager
  IF NOT is_manager() THEN
    RAISE EXCEPTION 'Solo managers pueden acceder a KPIs organizacionales';
  END IF;

  -- Calcular métricas de empleados
  SELECT 
    COUNT(DISTINCT id),
    COUNT(DISTINCT id) FILTER (WHERE is_active = true)
  INTO total_employees, active_employees
  FROM users
  WHERE role IN ('worker', 'supervisor');

  -- Calcular métricas de asistencia
  SELECT 
    COUNT(a.id),
    COUNT(a.id) FILTER (WHERE a.is_late = false),
    COUNT(a.id) FILTER (WHERE a.is_late = true)
  INTO total_check_ins, on_time_check_ins, late_check_ins
  FROM attendance a
  WHERE a.check_in_time BETWEEN start_date AND end_date;

  -- Calcular tasa de puntualidad
  IF total_check_ins > 0 THEN
    punctuality_rate := ROUND((on_time_check_ins::DECIMAL / total_check_ins * 100), 2);
  ELSE
    punctuality_rate := 0;
  END IF;

  -- Calcular promedio de score de asistencia
  SELECT ROUND(COALESCE(AVG(pm.attendance_score), 0), 2)
  INTO avg_attendance_score
  FROM performance_metrics pm
  WHERE pm.period_start >= start_date::DATE 
    AND pm.period_end <= end_date::DATE;

  -- Calcular ventas totales
  SELECT COALESCE(SUM(s.amount), 0)
  INTO total_sales_amount
  FROM sales s
  WHERE s.date BETWEEN start_date::DATE AND end_date::DATE;

  -- Construir JSON con todos los KPIs
  result := json_build_object(
    'total_employees', total_employees,
    'active_employees', active_employees,
    'total_check_ins', total_check_ins,
    'on_time_check_ins', on_time_check_ins,
    'late_check_ins', late_check_ins,
    'punctuality_rate', punctuality_rate,
    'avg_attendance_score', avg_attendance_score,
    'total_sales', total_sales_amount,
    'period_start', start_date,
    'period_end', end_date,
    'generated_at', NOW()
  );

  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- STEP 5: TRIGGERS
-- =============================================

-- Trigger para updated_at en users
DROP TRIGGER IF EXISTS users_updated_at ON users;
CREATE TRIGGER users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Trigger para updated_at en performance_metrics
DROP TRIGGER IF EXISTS performance_updated_at ON performance_metrics;
CREATE TRIGGER performance_updated_at
    BEFORE UPDATE ON performance_metrics
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- Trigger para auditoría en users
DROP TRIGGER IF EXISTS audit_users_trigger ON users;
CREATE TRIGGER audit_users_trigger
    AFTER UPDATE OR DELETE ON users
    FOR EACH ROW
    EXECUTE FUNCTION audit_users_changes();

-- =============================================
-- STEP 6: HABILITAR ROW LEVEL SECURITY
-- =============================================
-- 
-- ✅ ACTUALIZADO: RLS habilitado con políticas sin recursión
-- Fecha: 3 de noviembre, 2025

ALTER TABLE users ENABLE ROW LEVEL SECURITY;  -- ✅ HABILITADO
ALTER TABLE attendance ENABLE ROW LEVEL SECURITY;
ALTER TABLE locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE performance_metrics ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE rate_limit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_log ENABLE ROW LEVEL SECURITY;

-- =============================================
-- STEP 7: POLÍTICAS RLS PARA USERS (SIN RECURSIÓN)
-- =============================================
-- ✅ ACTUALIZADO: Políticas optimizadas usando funciones SECURITY DEFINER
-- para evitar recursión infinita

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

-- Workers: Actualizar solo su propio perfil (no pueden cambiar role ni supervisor_id)
CREATE POLICY "workers_update_own_profile"
ON users FOR UPDATE
USING (auth.uid() = id)
WITH CHECK (
  auth.uid() = id
  AND role = (SELECT role FROM users WHERE id = auth.uid())  -- Role no cambia
  AND supervisor_id = (SELECT supervisor_id FROM users WHERE id = auth.uid())  -- Supervisor no cambia
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

-- Supervisors: Crear workers bajo su supervisión
CREATE POLICY "supervisors_create_workers"
ON users FOR INSERT
WITH CHECK (
  is_supervisor()
  AND role = 'worker'
  AND supervisor_id = auth.uid()
);

-- Managers: Crear supervisores y workers
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
-- STEP 8: POLÍTICAS RLS PARA ATTENDANCE
-- =============================================

DROP POLICY IF EXISTS "workers_read_own_attendance" ON attendance;
DROP POLICY IF EXISTS "workers_create_own_attendance" ON attendance;
DROP POLICY IF EXISTS "workers_update_own_checkout" ON attendance;
DROP POLICY IF EXISTS "supervisors_read_team_attendance" ON attendance;
DROP POLICY IF EXISTS "managers_read_all_attendance" ON attendance;

-- Workers: Solo pueden ver sus propios registros
CREATE POLICY "workers_read_own_attendance"
ON attendance FOR SELECT
USING (user_id = auth.uid());

-- Workers: Solo pueden crear sus propios registros
CREATE POLICY "workers_create_own_attendance"
ON attendance FOR INSERT
WITH CHECK (
  user_id = auth.uid()
  AND check_rate_limit(auth.uid(), 'check_in', 10, 60)
  AND NOT EXISTS (
    SELECT 1 FROM attendance 
    WHERE user_id = auth.uid() 
    AND (check_in_time::DATE) = CURRENT_DATE
    AND check_out_time IS NULL
  )
);

-- Workers: Solo pueden actualizar sus propios check-outs
CREATE POLICY "workers_update_own_checkout"
ON attendance FOR UPDATE
USING (
  user_id = auth.uid()
  AND check_out_time IS NULL
)
WITH CHECK (
  user_id = auth.uid()
  AND check_out_time IS NOT NULL
  AND check_in_time = (SELECT check_in_time FROM attendance WHERE id = attendance.id)
);

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
-- STEP 9: POLÍTICAS RLS PARA LOCATIONS
-- =============================================

DROP POLICY IF EXISTS "workers_read_locations" ON locations;
DROP POLICY IF EXISTS "managers_manage_locations" ON locations;

CREATE POLICY "workers_read_locations"
ON locations FOR SELECT
USING (is_active = true);

CREATE POLICY "managers_manage_locations"
ON locations FOR ALL
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'manager'));

-- =============================================
-- STEP 10: POLÍTICAS RLS PARA PERFORMANCE_METRICS
-- =============================================

DROP POLICY IF EXISTS "workers_read_own_metrics" ON performance_metrics;
DROP POLICY IF EXISTS "supervisors_read_team_metrics" ON performance_metrics;
DROP POLICY IF EXISTS "managers_read_all_metrics" ON performance_metrics;
DROP POLICY IF EXISTS "system_write_metrics" ON performance_metrics;

CREATE POLICY "workers_read_own_metrics"
ON performance_metrics FOR SELECT
USING (user_id = auth.uid());

CREATE POLICY "supervisors_read_team_metrics"
ON performance_metrics FOR SELECT
USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('supervisor', 'manager'))
  AND user_id IN (
    SELECT id FROM users 
    WHERE supervisor_id = auth.uid() OR id = auth.uid()
  )
);

CREATE POLICY "managers_read_all_metrics"
ON performance_metrics FOR SELECT
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'manager'));

CREATE POLICY "system_write_metrics"
ON performance_metrics FOR INSERT
WITH CHECK (true);

-- =============================================
-- STEP 11: POLÍTICAS RLS PARA SALES
-- =============================================

DROP POLICY IF EXISTS "workers_manage_own_sales" ON sales;
DROP POLICY IF EXISTS "supervisors_read_team_sales" ON sales;
DROP POLICY IF EXISTS "managers_read_all_sales" ON sales;

CREATE POLICY "workers_manage_own_sales"
ON sales FOR ALL
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "supervisors_read_team_sales"
ON sales FOR SELECT
USING (
  auth.uid() IN (SELECT id FROM users WHERE role IN ('supervisor', 'manager'))
  AND user_id IN (
    SELECT id FROM users 
    WHERE supervisor_id = auth.uid() OR id = auth.uid()
  )
);

CREATE POLICY "managers_read_all_sales"
ON sales FOR SELECT
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'manager'));

-- =============================================
-- STEP 12: POLÍTICAS RLS PARA SECURITY TABLES
-- =============================================

DROP POLICY IF EXISTS "managers_read_rate_limits" ON rate_limit_log;
DROP POLICY IF EXISTS "managers_read_audit_log" ON audit_log;

CREATE POLICY "managers_read_rate_limits"
ON rate_limit_log FOR SELECT
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'manager'));

CREATE POLICY "managers_read_audit_log"
ON audit_log FOR SELECT
USING (auth.uid() IN (SELECT id FROM users WHERE role = 'manager'));

-- =============================================
-- STEP 13: STORAGE BUCKETS (SOLO SI NO EXISTEN)
-- =============================================

-- Crear buckets si no existen
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('attendance-photos', 'attendance-photos', true),
    ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

-- Storage policies para attendance photos
DROP POLICY IF EXISTS "Users can upload their attendance photos" ON storage.objects;
CREATE POLICY "Users can upload their attendance photos"
    ON storage.objects FOR INSERT
    TO authenticated
    WITH CHECK (
      bucket_id = 'attendance-photos' 
      AND auth.uid()::text = split_part(name, '/', 1)
    );

DROP POLICY IF EXISTS "Users can view attendance photos" ON storage.objects;
CREATE POLICY "Users can view attendance photos"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'attendance-photos');

-- Storage policies para profile photos
-- Managers y supervisors pueden subir fotos de cualquier usuario
DROP POLICY IF EXISTS "Users can upload their profile photos" ON storage.objects;
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

-- Managers y supervisors pueden actualizar fotos de cualquier usuario
DROP POLICY IF EXISTS "Users can update their profile photos" ON storage.objects;
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

DROP POLICY IF EXISTS "Users can view profile photos" ON storage.objects;
CREATE POLICY "Users can view profile photos"
    ON storage.objects FOR SELECT
    TO authenticated
    USING (bucket_id = 'profile-photos');

-- Managers pueden eliminar fotos de cualquier usuario
DROP POLICY IF EXISTS "Users can delete their profile photos" ON storage.objects;
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
-- ✅ SCHEMA CONSOLIDADO COMPLETO
-- =============================================
-- 
-- Este archivo incluye:
-- ✅ Todas las tablas necesarias
-- ✅ Índices optimizados
-- ✅ Funciones auxiliares
-- ✅ Triggers automáticos
-- ✅ RLS políticas sin duplicaciones
-- ✅ Rate limiting
-- ✅ Audit logging
-- ✅ Storage buckets
--
-- =============================================
