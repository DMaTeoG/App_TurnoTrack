-- =============================================
-- VERIFICACIÓN DE ESTADO DE LA BASE DE DATOS
-- =============================================
-- Ejecuta este script para ver qué tienes instalado
-- =============================================

-- 1. Verificar funciones RPC
SELECT 
  'Funciones RPC' as tipo,
  routine_name as nombre,
  'Existe' as estado
FROM information_schema.routines 
WHERE routine_schema = 'public' 
  AND routine_name IN (
    'get_user_performance', 
    'get_performance_ranking',
    'calculate_weighted_attendance_score',
    'update_performance_metrics_with_weighted_score',
    'get_organization_kpis',
    'update_attendance_lateness'
  )
ORDER BY routine_name;

-- 2. Verificar usuarios de prueba
SELECT 
  'Usuarios' as tipo,
  role,
  COUNT(*) as cantidad
FROM users
GROUP BY role
ORDER BY role;

-- 3. Verificar attendance (últimos 30 días)
SELECT 
  'Attendance' as tipo,
  COUNT(*) as total_registros,
  COUNT(DISTINCT user_id) as usuarios_unicos,
  MIN(check_in_time::date) as fecha_mas_antigua,
  MAX(check_in_time::date) as fecha_mas_reciente
FROM attendance
WHERE check_in_time >= NOW() - INTERVAL '30 days';

-- 4. Verificar performance_metrics
SELECT 
  'Performance Metrics' as tipo,
  COUNT(*) as total_registros,
  COUNT(DISTINCT user_id) as usuarios_unicos,
  MIN(period_start) as periodo_mas_antiguo,
  MAX(period_end) as periodo_mas_reciente
FROM performance_metrics;

-- 5. Verificar si hay rankings calculados
SELECT 
  'Ranking' as tipo,
  COUNT(*) as usuarios_con_ranking,
  MIN(ranking) as ranking_minimo,
  MAX(ranking) as ranking_maximo
FROM performance_metrics
WHERE ranking IS NOT NULL;

-- =============================================
-- DIAGNÓSTICO RÁPIDO
-- =============================================
-- Si ves:
-- ✅ 6 funciones RPC → Base de datos completa
-- ✅ 1+ manager, 3+ supervisors, 15+ workers → Seed ejecutada
-- ✅ 50+ attendance registros → Hay datos de asistencia
-- ✅ 15+ performance_metrics → Métricas calculadas
-- ✅ 1+ usuarios con ranking → Ranking funcionando

-- Si NO ves funciones:
-- ❌ Ejecuta: sql/patches/missing_rpc_functions.sql

-- Si NO ves usuarios:
-- ❌ Ejecuta: sql/seeds/seed_test_data.sql

-- Si NO ves attendance pero sí usuarios:
-- ❌ Re-ejecuta: sql/seeds/seed_test_data.sql

-- Si NO ves performance_metrics:
-- ❌ Ejecuta manualmente: SELECT update_performance_metrics_with_weighted_score();
