-- attendance_lateness.sql
-- Funciones y trigger para normalizar la lógica de tardanza
-- Regla: llegada temprana entre 07:00 y 08:30 (inclusive), llegada tarde si check_in_time::time > 08:30

BEGIN;

-- 1) Función para actualizar registros existentes según umbral
CREATE OR REPLACE FUNCTION update_attendance_lateness(
  threshold_end TIME DEFAULT '08:30'
)
RETURNS VOID AS $$
BEGIN
  UPDATE attendance
  SET
    is_late = (check_in_time::time > threshold_end),
    minutes_late = CASE
      WHEN check_in_time::time > threshold_end
      THEN ((EXTRACT(HOUR FROM check_in_time)::int * 60) + EXTRACT(MINUTE FROM check_in_time)::int) - ((EXTRACT(HOUR FROM threshold_end)::int * 60) + EXTRACT(MINUTE FROM threshold_end)::int)
      ELSE 0
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2) Trigger function para calcular is_late y minutes_late en INSERT/UPDATE
CREATE OR REPLACE FUNCTION attendance_set_lateness()
RETURNS TRIGGER AS $$
DECLARE
  threshold_end CONSTANT TIME := '08:30';
  check_time TIME;
  minutes_diff INT;
BEGIN
  IF NEW.check_in_time IS NULL THEN
    NEW.is_late := false;
    NEW.minutes_late := 0;
    RETURN NEW;
  END IF;

  check_time := NEW.check_in_time::time;
  NEW.is_late := (check_time > threshold_end);

  IF NEW.is_late THEN
    minutes_diff := ((EXTRACT(HOUR FROM NEW.check_in_time)::int * 60) + EXTRACT(MINUTE FROM NEW.check_in_time)::int) - ((EXTRACT(HOUR FROM threshold_end)::int * 60) + EXTRACT(MINUTE FROM threshold_end)::int);
    NEW.minutes_late := GREATEST(minutes_diff, 0);
  ELSE
    NEW.minutes_late := 0;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3) Instalar trigger en la tabla attendance (reemplaza si existe)
DROP TRIGGER IF EXISTS attendance_set_lateness_trigger ON attendance;
CREATE TRIGGER attendance_set_lateness_trigger
  BEFORE INSERT OR UPDATE ON attendance
  FOR EACH ROW
  EXECUTE FUNCTION attendance_set_lateness();

COMMIT;

-- USO:
-- 1) Ejecutar este script para crear la función y el trigger.
-- 2) Para normalizar los registros existentes ejecutar:
--    SELECT update_attendance_lateness();
