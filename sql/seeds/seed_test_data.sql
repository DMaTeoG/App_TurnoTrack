-- Seed de prueba pulida para TurnoTrack
-- Genera: 1 manager, 3 supervisors, 15 workers (incluye a Natalie)
-- Inserta attendance y sales para últimos 21 días con casos: on-time, late, boundary (08:30, 08:31), ausencias
-- Idempotente: borra registros previos en el rango para los emails listados

BEGIN;

-- 1) Manager y supervisors (upsert por email)
INSERT INTO users (email, full_name, role, is_active, photo_url)
VALUES
  ('manager@example.com', 'Carlos Perez', 'manager', true, 'https://placehold.co/256x256'),
  ('supervisor1@example.com', 'Lucia Fernandez', 'supervisor', true, 'https://placehold.co/256x256'),
  ('supervisor2@example.com', 'Miguel Torres', 'supervisor', true, 'https://placehold.co/256x256'),
  ('supervisor3@example.com', 'Ana Morales', 'supervisor', true, 'https://placehold.co/256x256')
ON CONFLICT (email) DO UPDATE
  SET full_name = EXCLUDED.full_name, is_active = EXCLUDED.is_active, photo_url = EXCLUDED.photo_url;

-- Periodo donde generamos datos
DO $$
DECLARE
  supervisor_ids UUID[];
  mgr_id UUID;
  worker_names TEXT[] := ARRAY[
    'Natalie Gomez', 'Diego Alvarez', 'Sofia Ramirez', 'Javier Diaz', 'Camila Rios',
    'Martin Suarez', 'Valentina Cruz', 'Lucas Medina', 'Mariana Vega', 'Andres Soto',
    'Paula Herrera', 'Sergio Lopez', 'Carla Pinto', 'Bruno Castro', 'Daniela Ortiz'
  ];
  w_email TEXT;
  w_name TEXT;
  w_id UUID;
  rec RECORD;
  start_date DATE := (CURRENT_DATE - INTERVAL '20 days')::DATE;
  end_date DATE := CURRENT_DATE;
  d DATE;
  check_ts TIMESTAMP;
  sale_amt NUMERIC;
  idx INT := 1;
BEGIN
  -- Obtener supervisors y manager
  SELECT array_agg(id ORDER BY full_name) INTO supervisor_ids FROM users WHERE role = 'supervisor';
  SELECT id INTO mgr_id FROM users WHERE role = 'manager' LIMIT 1;

  IF supervisor_ids IS NULL OR array_length(supervisor_ids,1) = 0 THEN
    RAISE EXCEPTION 'No hay supervisors presentes. Ejecuta la sección de supervisors primero.';
  END IF;

  -- Upsert workers (15) y asignar supervisor por round-robin
  FOREACH w_name IN ARRAY worker_names LOOP
    w_email := lower(replace(w_name, ' ', '.')) || '@example.com';
    INSERT INTO users (email, full_name, role, is_active, photo_url, phone, supervisor_id)
    VALUES (
      w_email, w_name, 'worker', true,
      'https://placehold.co/256x256',
      NULL,
      supervisor_ids[((idx - 1) % array_length(supervisor_ids,1)) + 1]
    )
    ON CONFLICT (email) DO NOTHING;

    -- Obtener id del worker (si ya existía se respetan sus datos: email, password, supervisor, etc.)
    SELECT id INTO w_id FROM users WHERE email = w_email;

    -- Guardamos el id de Natalie para comportamientos especiales
    IF w_email = 'natalie.gomez@example.com' THEN
      -- darle un alias w_id (ya está en variable) y podemos usarlo luego
      NULL;
    END IF;

    idx := idx + 1;
  END LOOP;

  -- Idempotencia: borrar attendance y sales previos en el periodo para los workers generados
  -- NOTA: no borramos ni modificamos explícitamente al usuario 'natalie.gomez@example.com' si ya existe;
  -- queremos respetar su cuenta y credenciales; solo añadiremos registros para "buffear" sus métricas.
  DELETE FROM attendance
  WHERE check_in_time::date BETWEEN start_date AND end_date
    AND user_id IN (
      SELECT id FROM users WHERE role = 'worker' AND email <> 'natalie.gomez@example.com' AND full_name = ANY(worker_names)
    );

  DELETE FROM sales
  WHERE date BETWEEN start_date AND end_date
    AND user_id IN (
      SELECT id FROM users WHERE role = 'worker' AND email <> 'natalie.gomez@example.com' AND full_name = ANY(worker_names)
    );

  -- Generar attendance y sales para cada worker y cada día
  FOR d IN SELECT generate_series(start_date, end_date, '1 day')::date LOOP
    FOR rec IN SELECT full_name, email FROM users WHERE role='worker' AND is_active=true ORDER BY full_name LOOP
      w_name := rec.full_name;
      w_email := rec.email;
      -- decidir presencia: algunos trabajadores son más consistentes
      IF w_email = 'natalie.gomez@example.com' THEN
        -- Natalie: alta probabilidad de asistir y vender
        IF random() < 0.95 THEN
          -- mayoría llegan entre 08:00 y 08:20, algunos el 08:30, rara vez 08:31
          IF random() < 0.02 THEN
            check_ts := d + time '08:31';
          ELSIF random() < 0.1 THEN
            check_ts := d + time '08:30';
          ELSE
            check_ts := d + (time '08:05' + (floor(random()*15)::int || ' minutes')::interval);
          END IF;
          INSERT INTO attendance (user_id, check_in_time, check_in_latitude, check_in_longitude, check_in_photo_url, check_in_address)
          VALUES ((SELECT id FROM users WHERE email = w_email), check_ts, -34.6037, -58.3816, 'https://placehold.co/640x480', 'Sucursal Central');

          -- ventas frecuentes
          IF random() < 0.6 THEN
            sale_amt := round((random()*250 + 50)::numeric, 2);
            INSERT INTO sales (user_id, date, amount, quantity, product_category)
            VALUES ((SELECT id FROM users WHERE email = w_email), d, sale_amt, (floor(random()*3)+1)::int, 'general');
          END IF;
        END IF;

      ELSE
        -- Otros workers: mezcla de comportamientos
        IF random() < 0.8 THEN -- presencia
          -- casos: 60% on-time (07:00-08:30), 25% late (after 08:30), 15% boundary (08:30 exactly)
          IF random() < 0.6 THEN
            -- on-time entre 07:00 y 08:30 (use earlier hours too)
            check_ts := d + (time '07:00' + ((floor(random()*90))::int || ' minutes')::interval);
          ELSIF random() < 0.15 THEN
            -- exact boundary 08:30
            check_ts := d + time '08:30';
          ELSE
            -- late between 08:31 and 09:30
            check_ts := d + (time '08:31' + ((floor(random()*59))::int || ' minutes')::interval);
          END IF;

          INSERT INTO attendance (user_id, check_in_time, check_in_latitude, check_in_longitude, check_in_photo_url, check_in_address)
          VALUES ((SELECT id FROM users WHERE email = w_email), check_ts, -34.6037, -58.3816, 'https://placehold.co/640x480', 'Sucursal Central');

          -- ventas menores de probabilidad
          IF random() < 0.3 THEN
            sale_amt := round((random()*150 + 5)::numeric, 2);
            INSERT INTO sales (user_id, date, amount, quantity, product_category)
            VALUES ((SELECT id FROM users WHERE email = w_email), d, sale_amt, (floor(random()*2)+1)::int, 'general');
          END IF;
        END IF;
      END IF;
    END LOOP;
  END LOOP;

  -- Normalizar lateness (si tienes el parche/trigger corriendo esto es redundante, pero útil la primera vez)
  PERFORM update_attendance_lateness();

  -- Actualizar performance_metrics: si la columna average_check_in_time existe usamos
  -- la función integrada `update_performance_metrics_with_weighted_score()`, si no
  -- existe (estructura más antigua) calculamos e insertamos métricas sin esa columna.
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public' AND table_name = 'performance_metrics' AND column_name = 'average_check_in_time'
  ) THEN
    PERFORM update_performance_metrics_with_weighted_score();
  ELSE
    -- Fallback: calcular score por usuario y hacer upsert sin average_check_in_time
    DECLARE
      user_record RECORD;
      new_score INTEGER;
      total_checkins INTEGER;
      late_checkins INTEGER;
      punctuality_rate DECIMAL(5,2);
    BEGIN
      FOR user_record IN SELECT id FROM users WHERE is_active = true AND role IN ('worker','supervisor') LOOP
        -- Calcular score usando la función disponible (calculate_weighted_attendance_score)
        BEGIN
          new_score := calculate_weighted_attendance_score(user_record.id, start_date, end_date);
        EXCEPTION WHEN OTHERS THEN
          new_score := 0;
        END;

        SELECT COUNT(*), COUNT(*) FILTER (WHERE is_late = true)
        INTO total_checkins, late_checkins
        FROM attendance a
        WHERE a.user_id = user_record.id AND a.check_in_time::date BETWEEN start_date AND end_date;

        IF total_checkins > 0 THEN
          punctuality_rate := ROUND(((total_checkins - late_checkins)::DECIMAL / total_checkins * 100), 2);
        ELSE
          punctuality_rate := 0;
        END IF;

        INSERT INTO performance_metrics (
          user_id, attendance_score, punctuality_rate, total_check_ins, late_check_ins, period_start, period_end, badges, ai_recommendations
        ) VALUES (
          user_record.id,
          new_score,
          punctuality_rate,
          total_checkins,
          late_checkins,
          start_date,
          end_date,
          '[]'::jsonb,
          '[]'::jsonb
        ) ON CONFLICT (user_id, period_start, period_end) DO UPDATE SET
          attendance_score = EXCLUDED.attendance_score,
          punctuality_rate = EXCLUDED.punctuality_rate,
          total_check_ins = EXCLUDED.total_check_ins,
          late_check_ins = EXCLUDED.late_check_ins,
          updated_at = NOW();
      END LOOP;
    END;
  END IF;

END$$;

COMMIT;

-- Fin seed pulida
