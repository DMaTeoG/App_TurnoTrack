-- =============================================
-- LOGICA DE TARDANZA (CORREGIDA PARA ZONA HORARIA)
-- =============================================
-- Convierte UTC a America/Bogota antes de calcular
-- =============================================

BEGIN;

-- 1) Función para actualizar registros existentes (Reparación masiva)
CREATE OR REPLACE FUNCTION update_attendance_lateness(
  threshold_end TIME DEFAULT '08:30',
  timezone_name TEXT DEFAULT 'America/Bogota'
)
RETURNS VOID AS $$
BEGIN
  UPDATE attendance
  SET
    is_late = ((check_in_time AT TIME ZONE timezone_name)::time > threshold_end),
    minutes_late = CASE
      WHEN ((check_in_time AT TIME ZONE timezone_name)::time > threshold_end)
      THEN 
        -- Calcular diferencia en minutos usando la hora local
        (EXTRACT(EPOCH FROM ((check_in_time AT TIME ZONE timezone_name)::time - threshold_end)) / 60)::INTEGER
      ELSE 0
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2) Trigger function para calcular automáticamente al insertar/actualizar
CREATE OR REPLACE FUNCTION attendance_set_lateness()
RETURNS TRIGGER AS $$
DECLARE
  threshold_end CONSTANT TIME := '08:30';
  timezone_name CONSTANT TEXT := 'America/Bogota'; -- 👈 AQUÍ DEFINIMOS TU ZONA
  local_check_in TIMESTAMP;
  minutes_diff INTEGER;
BEGIN
  -- Si no hay hora de entrada, no hacer nada
  IF NEW.check_in_time IS NULL THEN
    NEW.is_late := false;
    NEW.minutes_late := 0;
    RETURN NEW;
  END IF;

  -- CONVERTIR UTC A HORA COLOMBIA
  local_check_in := NEW.check_in_time AT TIME ZONE timezone_name;

  -- Comparar con el límite (08:30)
  NEW.is_late := (local_check_in::time > threshold_end);

  IF NEW.is_late THEN
    -- Calcular diferencia en minutos (matemática de fechas)
    -- Extraemos los segundos de diferencia y dividimos por 60
    minutes_diff := (EXTRACT(EPOCH FROM (local_check_in::time - threshold_end)) / 60)::INTEGER;
    NEW.minutes_late := GREATEST(minutes_diff, 0);
  ELSE
    NEW.minutes_late := 0;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3) Instalar trigger (Borrando el anterior por si acaso)
DROP TRIGGER IF EXISTS attendance_set_lateness_trigger ON attendance;
CREATE TRIGGER attendance_set_lateness_trigger
  BEFORE INSERT OR UPDATE ON attendance
  FOR EACH ROW
  EXECUTE FUNCTION attendance_set_lateness();

COMMIT;