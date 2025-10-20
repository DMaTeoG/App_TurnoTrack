-- 04_views.sql
-- Vistas y materialized views

create or replace view v_registros_pareados as
with pares as (
    select
        r1.empleado_id,
        r1.tomado_en as entrada,
        r2.tomado_en as salida,
        r1.lat as lat,
        r1.lng as lng,
        extract(epoch from (r2.tomado_en - r1.tomado_en))/3600 as horas
    from registros r1
    join registros r2
      on r1.empleado_id = r2.empleado_id
     and r1.tipo = 'entrada'
     and r2.tipo = 'salida'
     and r2.tomado_en > r1.tomado_en
)
select p.*, e.supervisor_id
from pares p
join empleados e on e.id = p.empleado_id;

create or replace view v_horas_por_supervisor as
select
    s.id as supervisor_id,
    s.nombre as supervisor,
    date_trunc('week', p.entrada) as semana,
    sum(p.horas) as horas_totales
from v_registros_pareados p
join supervisores s on s.id = p.supervisor_id
group by 1,2,3;

create or replace view v_registros_ultimos_30 as
select
    r.empleado_id,
    e.nombre as empleado,
    s.nombre as supervisor,
    date(r.tomado_en) as fecha,
    r.tipo,
    r.precision_m,
    0::int as incidencias,
    0::numeric as horas
from registros r
join empleados e on e.id = r.empleado_id
left join supervisores s on s.id = e.supervisor_id
where r.tomado_en >= now() - interval '30 days';

create or replace view v_metricas_diarias as
select
    date(r.tomado_en) as fecha,
    count(*) filter (where tipo = 'entrada') as entradas,
    count(*) filter (where tipo = 'salida') as salidas,
    avg(r.precision_m) as precision_promedio
from registros r
where r.tomado_en >= now() - interval '30 days'
group by 1;
