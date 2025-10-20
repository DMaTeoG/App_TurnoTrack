-- 02_rls.sql
-- Politicas Row Level Security

alter table empleados enable row level security;
alter table supervisores enable row level security;
alter table registros enable row level security;
alter table desempeno_semana enable row level security;
alter table coaching_hist enable row level security;

-- Roles esperados: admin, supervisor, operador

create policy "empleados admin acceso total"
  on empleados for all
  using (auth.role() = 'admin');

create policy "empleados supervisor equipo"
  on empleados for select using (
    auth.role() = 'supervisor' and supervisor_id = auth.uid()
  ) with check (auth.role() = 'supervisor');

create policy "empleados propio"
  on empleados for select using (
    auth.role() = 'operador' and id = auth.uid()
  );

create policy "registros admin"
  on registros for all using (auth.role() = 'admin');

create policy "registros supervisor"
  on registros for select using (
    auth.role() = 'supervisor' and
    exists (
      select 1 from empleados e
      where e.id = registros.empleado_id
        and e.supervisor_id = auth.uid()
    )
  );

create policy "registros operador insert"
  on registros for insert with check (
    auth.role() = 'operador' and empleado_id = auth.uid()
  );

create policy "registros operador select"
  on registros for select using (
    auth.role() = 'operador' and empleado_id = auth.uid()
  );

create policy "desempeno admin"
  on desempeno_semana for all using (auth.role() = 'admin');

create policy "desempeno supervisor"
  on desempeno_semana for select using (
    auth.role() = 'supervisor' and supervisor_id = auth.uid()
  );

create policy "desempeno operador"
  on desempeno_semana for select using (
    auth.role() = 'operador' and empleado_id = auth.uid()
  );

create policy "coaching operador"
  on coaching_hist for select using (
    auth.role() = 'operador' and empleado_id = auth.uid()
  );

create policy "coaching supervisor"
  on coaching_hist for select using (
    auth.role() = 'supervisor' and
    exists (
      select 1 from empleados e
      where e.id = coaching_hist.empleado_id
        and e.supervisor_id = auth.uid()
    )
  );

create policy "coaching admin"
  on coaching_hist for all using (auth.role() = 'admin');
