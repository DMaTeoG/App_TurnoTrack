-- 03_triggers.sql
-- Validaciones de registros

create or replace function trg_registros_validaciones()
returns trigger as $$
declare
    ultimo_tipo text;
    ultima_fecha timestamp with time zone;
begin
    select tipo, tomado_en
      into ultimo_tipo, ultima_fecha
      from registros
     where empleado_id = new.empleado_id
     order by tomado_en desc
     limit 1;

    if ultimo_tipo = new.tipo then
        raise exception 'No se puede registrar % consecutivo', new.tipo;
    end if;

    if new.precision_m > 10 then
        raise exception 'Precision % excede el maximo permitido', new.precision_m;
    end if;

    if new.codigo_validacion is null or length(new.codigo_validacion) < 4 then
        new.codigo_validacion := substr(md5(random()::text), 1, 6);
    end if;

    return new;
end;
$$ language plpgsql;

create trigger trg_registros_before_insert
before insert on registros
for each row execute procedure trg_registros_validaciones();
