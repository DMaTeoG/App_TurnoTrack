-- Super seed for charts testing
-- Generates synthetic users, attendance and sales data for: year, month, week
-- Purpose: provide distinct shapes for charting (yearly trend, monthly daily series, weekly detail)
-- Run in Supabase SQL editor in the project DB.

DO $$
DECLARE
  base_date DATE := CURRENT_DATE;
  created_user_id UUID;
  loop_user UUID;
  user_count INT := 10;
  i INT;
  j INT;
  day DATE;
  ts TIMESTAMP WITH TIME ZONE;
  checkins INT;
  sales_amt NUMERIC;
  start_period DATE;
  end_period DATE;
  total_checkins INT;
  late_checkins INT;
  avg_checkin_hours NUMERIC;
  punctuality NUMERIC;
  attendance_sc INT;
  seed_users UUID[] := ARRAY[]::UUID[];
BEGIN
  -- 1) Create test users (workers)
  FOR i IN 1..user_count LOOP
    INSERT INTO users (email, full_name, role, is_active)
    VALUES (
      ('worker' || i || '@test.com'),
      ('Worker ' || i),
      'worker',
      true
    )
    ON CONFLICT (email) DO UPDATE SET full_name = EXCLUDED.full_name
    RETURNING id INTO created_user_id;

    seed_users := array_append(seed_users, created_user_id);
  END LOOP;

  -- 2) Generate attendance records for the past 12 months (monthly patterns)
  FOR i IN 0..11 LOOP
    start_period := (date_trunc('month', base_date) - (interval '1 month' * i))::date;
    end_period := (date_trunc('month', base_date) - (interval '1 month' * i) + interval '1 month - 1 day')::date;

    -- For each user, generate a random number of checkins inside the month
    FOREACH loop_user IN ARRAY seed_users LOOP
      checkins := (5 + floor(random() * 15))::int; -- 5..19 checkins per month

      FOR j IN 1..checkins LOOP
        day := (start_period + (floor(random() * (end_period - start_period + 1)))::int);
        ts := (day + (8 + random() * 2) * interval '1 hour' + (random() * 59)::int * interval '1 minute')::timestamp with time zone;

        INSERT INTO attendance (
          user_id, check_in_time, check_in_latitude, check_in_longitude, check_in_photo_url, is_late, minutes_late
        ) VALUES (
          loop_user,
          ts,
          0.0 + random()*0.01,
          0.0 + random()*0.01,
          'https://example.com/checkin.jpg',
          (random() < 0.12), -- ~12% late
          (CASE WHEN random() < 0.12 THEN (1 + floor(random()*30))::int ELSE 0 END)
        );
      END LOOP;
    END LOOP;
  END LOOP;

  -- 3) Generate daily records for current month (to produce daily series)
  start_period := date_trunc('month', base_date)::date;
  FOR day IN SELECT generate_series(start_period, base_date, interval '1 day')::date LOOP
    FOREACH loop_user IN ARRAY seed_users LOOP
      IF random() < 0.95 THEN -- most days users check-in
        ts := (day + (7.5 + (random() * 2)) * interval '1 hour' + (random() * 59)::int * interval '1 minute')::timestamp with time zone;
        INSERT INTO attendance (
          user_id, check_in_time, check_in_latitude, check_in_longitude, check_in_photo_url, is_late, minutes_late
        ) VALUES (
          loop_user,
          ts,
          0.0 + random()*0.01,
          0.0 + random()*0.01,
          'https://example.com/checkin.jpg',
          (random() < 0.08),
          (CASE WHEN random() < 0.08 THEN (1 + floor(random()*20))::int ELSE 0 END)
        );
      END IF;
    END LOOP;
  END LOOP;

  -- 4) Generate detailed last-week data (hourly-like resolution with variability)
  start_period := (base_date - interval '6 days')::date;
  FOR day IN SELECT generate_series(start_period, base_date, interval '1 day')::date LOOP
    FOREACH loop_user IN ARRAY seed_users LOOP
      -- occasionally two checkins (split shift)
      IF random() < 0.9 THEN
        ts := (day + (8 + random() * 1.5) * interval '1 hour' + (random() * 59)::int * interval '1 minute')::timestamp with time zone;
        INSERT INTO attendance (user_id, check_in_time, check_in_latitude, check_in_longitude, check_in_photo_url, is_late, minutes_late)
        VALUES (loop_user, ts, 0.0 + random()*0.01, 0.0 + random()*0.01, 'https://example.com/checkin.jpg', (random() < 0.06), (CASE WHEN random() < 0.06 THEN (1 + floor(random()*10))::int ELSE 0 END));
      END IF;

      IF random() < 0.15 THEN
        -- second checkin (short shift)
        ts := (day + (13 + random() * 2) * interval '1 hour' + (random() * 59)::int * interval '1 minute')::timestamp with time zone;
        INSERT INTO attendance (user_id, check_in_time, check_in_latitude, check_in_longitude, check_in_photo_url, is_late, minutes_late)
        VALUES (loop_user, ts, 0.0 + random()*0.01, 0.0 + random()*0.01, 'https://example.com/checkin.jpg', (random() < 0.04), (CASE WHEN random() < 0.04 THEN (1 + floor(random()*8))::int ELSE 0 END));
      END IF;
    END LOOP;
  END LOOP;

  -- 5) Generate sales data across the year with different intensities to make graphs interesting
  FOR i IN 1..array_length(seed_users,1) LOOP
    -- higher index -> better performer
    FOR j IN 0..364 LOOP
      day := (base_date - (interval '1 day' * j))::date;
      IF random() < (0.15 + (i::numeric / user_count) * 0.5) THEN
        sales_amt := round((10 + random() * (50.0 + i*5))::numeric, 2);
        INSERT INTO sales (user_id, date, amount, quantity, product_category)
        VALUES (seed_users[i], day, sales_amt, (1 + floor(random()*5))::int, 'general')
        ON CONFLICT DO NOTHING;
      END IF;
    END LOOP;
  END LOOP;

  -- 6) Compute simple performance_metrics for last week, current month, last 12 months
  FOR i IN 1..array_length(seed_users,1) LOOP
    -- WEEK
    start_period := (base_date - interval '6 days')::date;
    end_period := base_date;
    SELECT COUNT(*) INTO total_checkins FROM attendance a WHERE a.user_id = seed_users[i] AND a.check_in_time::date BETWEEN start_period AND end_period;
    SELECT COUNT(*) INTO late_checkins FROM attendance a WHERE a.user_id = seed_users[i] AND a.is_late = true AND a.check_in_time::date BETWEEN start_period AND end_period;
    SELECT COALESCE(AVG(EXTRACT(HOUR FROM a.check_in_time) + EXTRACT(MINUTE FROM a.check_in_time)/60.0), 8.0) INTO avg_checkin_hours FROM attendance a WHERE a.user_id = seed_users[i] AND a.check_in_time::date BETWEEN start_period AND end_period;

    IF total_checkins > 0 THEN
      punctuality := ((total_checkins - late_checkins)::numeric / total_checkins) * 100;
    ELSE
      punctuality := 0;
    END IF;
    attendance_sc := greatest(0, LEAST(100, round(punctuality)));

    INSERT INTO performance_metrics (user_id, attendance_score, average_check_in_time, punctuality_rate, total_check_ins, late_check_ins, period_start, period_end, ai_recommendations, ranking)
    VALUES (seed_users[i], attendance_sc, round(avg_checkin_hours::numeric,2), round(punctuality::numeric,2), total_checkins, late_checkins, start_period, end_period, '[]'::jsonb, NULL)
    ON CONFLICT (user_id, period_start, period_end) DO UPDATE SET
      attendance_score = EXCLUDED.attendance_score,
      average_check_in_time = EXCLUDED.average_check_in_time,
      punctuality_rate = EXCLUDED.punctuality_rate,
      total_check_ins = EXCLUDED.total_check_ins,
      late_check_ins = EXCLUDED.late_check_ins,
      updated_at = NOW();

    -- MONTH
    start_period := date_trunc('month', base_date)::date;
    end_period := base_date;
    SELECT COUNT(*) INTO total_checkins FROM attendance a WHERE a.user_id = seed_users[i] AND a.check_in_time::date BETWEEN start_period AND end_period;
    SELECT COUNT(*) INTO late_checkins FROM attendance a WHERE a.user_id = seed_users[i] AND a.is_late = true AND a.check_in_time::date BETWEEN start_period AND end_period;
    SELECT COALESCE(AVG(EXTRACT(HOUR FROM a.check_in_time) + EXTRACT(MINUTE FROM a.check_in_time)/60.0), 8.0) INTO avg_checkin_hours FROM attendance a WHERE a.user_id = seed_users[i] AND a.check_in_time::date BETWEEN start_period AND end_period;
    IF total_checkins > 0 THEN
      punctuality := ((total_checkins - late_checkins)::numeric / total_checkins) * 100;
    ELSE
      punctuality := 0;
    END IF;
    attendance_sc := greatest(0, LEAST(100, round(punctuality)));

    INSERT INTO performance_metrics (user_id, attendance_score, average_check_in_time, punctuality_rate, total_check_ins, late_check_ins, period_start, period_end, ai_recommendations, ranking)
    VALUES (seed_users[i], attendance_sc, round(avg_checkin_hours::numeric,2), round(punctuality::numeric,2), total_checkins, late_checkins, start_period, end_period, '[]'::jsonb, NULL)
    ON CONFLICT (user_id, period_start, period_end) DO UPDATE SET
      attendance_score = EXCLUDED.attendance_score,
      average_check_in_time = EXCLUDED.average_check_in_time,
      punctuality_rate = EXCLUDED.punctuality_rate,
      total_check_ins = EXCLUDED.total_check_ins,
      late_check_ins = EXCLUDED.late_check_ins,
      updated_at = NOW();

    -- YEAR
    start_period := (date_trunc('month', base_date) - interval '11 months')::date;
    end_period := base_date;
    SELECT COUNT(*) INTO total_checkins FROM attendance a WHERE a.user_id = seed_users[i] AND a.check_in_time::date BETWEEN start_period AND end_period;
    SELECT COUNT(*) INTO late_checkins FROM attendance a WHERE a.user_id = seed_users[i] AND a.is_late = true AND a.check_in_time::date BETWEEN start_period AND end_period;
    SELECT COALESCE(AVG(EXTRACT(HOUR FROM a.check_in_time) + EXTRACT(MINUTE FROM a.check_in_time)/60.0), 8.0) INTO avg_checkin_hours FROM attendance a WHERE a.user_id = seed_users[i] AND a.check_in_time::date BETWEEN start_period AND end_period;
    IF total_checkins > 0 THEN
      punctuality := ((total_checkins - late_checkins)::numeric / total_checkins) * 100;
    ELSE
      punctuality := 0;
    END IF;
    attendance_sc := greatest(0, LEAST(100, round(punctuality)));

    INSERT INTO performance_metrics (user_id, attendance_score, average_check_in_time, punctuality_rate, total_check_ins, late_check_ins, period_start, period_end, ai_recommendations, ranking)
    VALUES (seed_users[i], attendance_sc, round(avg_checkin_hours::numeric,2), round(punctuality::numeric,2), total_checkins, late_checkins, start_period, end_period, '[]'::jsonb, NULL)
    ON CONFLICT (user_id, period_start, period_end) DO UPDATE SET
      attendance_score = EXCLUDED.attendance_score,
      average_check_in_time = EXCLUDED.average_check_in_time,
      punctuality_rate = EXCLUDED.punctuality_rate,
      total_check_ins = EXCLUDED.total_check_ins,
      late_check_ins = EXCLUDED.late_check_ins,
      updated_at = NOW();
  END LOOP;

  RAISE NOTICE '✅ Super seed complete: % users seeded', array_length(seed_users,1);
END $$;

-- End of seed
