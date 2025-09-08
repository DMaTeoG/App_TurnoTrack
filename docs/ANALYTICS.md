# Analitica y KPIs

## KPIs principales
- Horas efectivas trabajadas por empleado (pares entrada-salida).
- Tasa de puntualidad: entradas dentro de ventana de tolerancia.
- Incidencias por semana: registros rechazados o anulados.
- Cobertura de marcacion: % de operadores con al menos 1 registro diario.

## Vistas y materialized views
- `v_registros_pareados`: une entradas y salidas por empleado, fecha y consecutivo.
- `v_horas_por_supervisor`: agrega horas por equipo y semana.
- `v_registros_ultimos_30`: muestra actividad reciente para dashboards.
- `v_metricas_diarias`: KPIs diarios globales.
- Materialized view `mv_resumen_semanal` (opcional) con refresh programado cada hora via cron.

## Programacion de refresh
- Usar `pg_cron` o Supabase Scheduled Functions.
- Comando: `select cron.schedule('refresh_mv', '0 * * * *', $$refresh materialized view concurrently mv_resumen_semanal$$);`

## Filtros y RLS
- Todas las vistas usan `security_invoker`.
- Filtros de supervisor aplicados via `where supervisor_id = auth.uid()`.
- Reportes globales solo disponibles para admin.

## Mapas y heatmaps
- Repositorio `analytics_repo` expone datos agregados por geohash.
- Mapas utilizan centroides y conteo de registros para intensidad.
