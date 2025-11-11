-- =============================================
-- TURNOTRACK - SCHEMA BASE (Sin Políticas RLS)
-- =============================================
-- Este archivo contiene SOLO la estructura de la base de datos:
-- - Extensiones
-- - Tablas
-- - Índices
-- - Funciones auxiliares
-- - Triggers
-- - Storage buckets
--
-- NO incluye políticas RLS (ver 02_RLS_POLICIES.sql)
--
-- ORDEN DE EJECUCIÓN:
-- 1. Ejecutar este archivo (01_SCHEMA_BASE.sql)
-- 2. Ejecutar las políticas (02_RLS_POLICIES.sql)
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
-- ✅ ACTUALIZADO: Agregada columna average_check_in_time para función de score ponderado
CREATE TABLE IF NOT EXISTS performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    attendance_score INTEGER NOT NULL CHECK (attendance_score >= 0 AND attendance_score <= 100),
    average_check_in_time DECIMAL(5, 2) DEFAULT 0,  -- ✅ NUEVA: Promedio de hora de check-in
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
-- FUNCIÓN PARA CALCULAR SCORE PONDERADO
-- =============================================
-- ✅ INTEGRADO: Función para calcular score con pesos
-- Fórmula: Score = (Ventas * 0.40) + (Puntualidad * 0.35) + (Asistencia * 0.25)

CREATE OR REPLACE FUNCTION calculate_weighted_attendance_score(
  user_uuid UUID,
  start_date DATE,
  end_date DATE
)
RETURNS INTEGER AS $$
DECLARE
  sales_score INTEGER := 0;
  punctuality_score INTEGER := 0;
  attendance_score INTEGER := 0;
  total_score INTEGER := 0;
  
  -- Variables para cálculo de ventas
  user_total_sales DECIMAL(12,2);
  max_sales DECIMAL(12,2);
  
  -- Variables para cálculo de puntualidad
  total_checkins INTEGER;
  late_checkins INTEGER;
  punctuality_rate DECIMAL(5,2);
  
  -- Variables para cálculo de asistencia
  expected_days INTEGER;
  actual_days INTEGER;
  attendance_rate DECIMAL(5,2);
BEGIN
  -- ============================================
  -- 1. CALCULAR SCORE DE VENTAS (40%)
  -- ============================================
  -- Obtener ventas del usuario
  SELECT COALESCE(SUM(amount), 0)
  INTO user_total_sales
  FROM sales
  WHERE user_id = user_uuid
    AND date BETWEEN start_date AND end_date;
  
  -- Obtener máximo de ventas en el período
  SELECT COALESCE(MAX(total), 0)
  INTO max_sales
  FROM (
    SELECT user_id, SUM(amount) as total
    FROM sales
    WHERE date BETWEEN start_date AND end_date
    GROUP BY user_id
  ) as user_sales;
  
  -- Calcular score de ventas (0-100)
  IF max_sales > 0 THEN
    sales_score := ROUND((user_total_sales / max_sales * 100)::NUMERIC);
  ELSE
    sales_score := 0;
  END IF;
  
  -- ============================================
  -- 2. CALCULAR SCORE DE PUNTUALIDAD (35%)
  -- ============================================
  -- Contar check-ins y llegadas tarde
  SELECT 
    COUNT(*),
    COUNT(*) FILTER (WHERE is_late = true)
  INTO total_checkins, late_checkins
  FROM attendance
  WHERE user_id = user_uuid
    AND check_in_time::DATE BETWEEN start_date AND end_date;
  
  -- Calcular tasa de puntualidad
  IF total_checkins > 0 THEN
    punctuality_rate := ((total_checkins - late_checkins)::DECIMAL / total_checkins * 100);
    punctuality_score := ROUND(punctuality_rate);
  ELSE
    punctuality_score := 0;
  END IF;
  
  -- ============================================
  -- 3. CALCULAR SCORE DE ASISTENCIA (25%)
  -- ============================================
  -- Calcular días esperados (excluyendo fines de semana)
  SELECT COUNT(*)
  INTO expected_days
  FROM generate_series(start_date, end_date, '1 day'::interval) d
  WHERE EXTRACT(DOW FROM d) BETWEEN 1 AND 5; -- Lunes a Viernes
  
  -- Contar días con check-in
  SELECT COUNT(DISTINCT check_in_time::DATE)
  INTO actual_days
  FROM attendance
  WHERE user_id = user_uuid
    AND check_in_time::DATE BETWEEN start_date AND end_date
    AND EXTRACT(DOW FROM check_in_time) BETWEEN 1 AND 5;
  
  -- Calcular tasa de asistencia
  IF expected_days > 0 THEN
    attendance_rate := (actual_days::DECIMAL / expected_days * 100);
    attendance_score := ROUND(attendance_rate);
  ELSE
    attendance_score := 0;
  END IF;
  
  -- ============================================
  -- 4. CALCULAR SCORE TOTAL PONDERADO
  -- ============================================
  total_score := ROUND(
    (sales_score * 0.40) + 
    (punctuality_score * 0.35) + 
    (attendance_score * 0.25)
  );
  
  -- Asegurar que esté en rango 0-100
  IF total_score < 0 THEN
    total_score := 0;
  ELSIF total_score > 100 THEN
    total_score := 100;
  END IF;
  
  RETURN total_score;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =============================================
-- FUNCIÓN PARA ACTUALIZAR MÉTRICAS CON NUEVO SCORE
-- =============================================
CREATE OR REPLACE FUNCTION update_performance_metrics_with_weighted_score()
RETURNS void AS $$
DECLARE
  user_record RECORD;
  start_date DATE := DATE_TRUNC('month', CURRENT_DATE)::DATE;
  end_date DATE := CURRENT_DATE;
  new_score INTEGER;
BEGIN
  -- Iterar sobre todos los usuarios activos
  FOR user_record IN 
    SELECT id FROM users 
    WHERE is_active = true AND role IN ('worker', 'supervisor')
  LOOP
    -- Calcular nuevo score ponderado
    new_score := calculate_weighted_attendance_score(
      user_record.id,
      start_date,
      end_date
    );
    
    -- Actualizar o insertar en performance_metrics
    INSERT INTO performance_metrics (
      user_id,
      attendance_score,
      average_check_in_time,
      punctuality_rate,
      total_check_ins,
      late_check_ins,
      period_start,
      period_end
    )
    SELECT 
      user_record.id,
      new_score,
      COALESCE(AVG(EXTRACT(HOUR FROM check_in_time) + EXTRACT(MINUTE FROM check_in_time) / 60.0), 0),
      CASE 
        WHEN COUNT(*) > 0 
        THEN ((COUNT(*) - COUNT(*) FILTER (WHERE is_late = true))::DECIMAL / COUNT(*) * 100)
        ELSE 0 
      END,
      COUNT(*),
      COUNT(*) FILTER (WHERE is_late = true),
      start_date,
      end_date
    FROM attendance
    WHERE user_id = user_record.id
      AND check_in_time::DATE BETWEEN start_date AND end_date
    ON CONFLICT (user_id, period_start, period_end) 
    DO UPDATE SET
      attendance_score = EXCLUDED.attendance_score,
      average_check_in_time = EXCLUDED.average_check_in_time,
      punctuality_rate = EXCLUDED.punctuality_rate,
      total_check_ins = EXCLUDED.total_check_ins,
      late_check_ins = EXCLUDED.late_check_ins,
      updated_at = NOW();
  END LOOP;
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
-- STEP 6: STORAGE BUCKETS
-- =============================================

-- Crear buckets si no existen
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('attendance-photos', 'attendance-photos', true),
    ('profile-photos', 'profile-photos', true)
ON CONFLICT (id) DO NOTHING;

-- =============================================
-- ✅ SCHEMA BASE COMPLETO
-- =============================================
-- 
-- Este archivo incluye:
-- ✅ Extensiones necesarias
-- ✅ Todas las tablas (incluyendo columna average_check_in_time)
-- ✅ Índices optimizados
-- ✅ Funciones auxiliares
-- ✅ Función de score ponderado integrada
-- ✅ Triggers automáticos
-- ✅ Storage buckets
--
-- SIGUIENTE PASO:
-- Ejecutar 02_RLS_POLICIES.sql para aplicar políticas de seguridad
--
-- NOTAS IMPORTANTES:
-- - Las funciones con SECURITY DEFINER se ejecutan con privilegios del owner
-- - Para automatizar: crear cron job que ejecute update_performance_metrics_with_weighted_score()
-- - Ejemplo cron: SELECT cron.schedule('update-metrics', '59 23 * * *', 'SELECT update_performance_metrics_with_weighted_score();');
--
-- =============================================
