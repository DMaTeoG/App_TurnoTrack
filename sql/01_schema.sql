-- 01_schema.sql
-- Tablas principales para TurnoTrack

create extension if not exists "uuid-ossp";

create table if not exists supervisores (
    id uuid primary key default uuid_generate_v4(),
    documento text not null unique,
    nombre text not null,
    email text not null,
    telefono text,
    activo boolean not null default true,
    creado_en timestamp with time zone not null default now()
);

create table if not exists empleados (
    id uuid primary key default uuid_generate_v4(),
    documento text not null unique,
    nombre text not null,
    rol text not null default 'operador',
    supervisor_id uuid references supervisores(id),
    email text,
    telefono text,
    activo boolean not null default true,
    creado_en timestamp with time zone not null default now()
);

create table if not exists registros (
    id uuid primary key,
    empleado_id uuid not null references empleados(id),
    tipo text not null check (tipo in ('entrada','salida')),
    tomado_en timestamp with time zone not null,
    lat double precision not null,
    lng double precision not null,
    precision_m numeric not null,
    evidencia_url text,
    codigo_validacion text not null,
    creado_por text,
    creado_en timestamp with time zone not null default now()
);

create table if not exists desempeno_semana (
    empleado_id uuid not null references empleados(id),
    supervisor_id uuid references supervisores(id),
    semana_iso text not null,
    score numeric not null,
    horas_efectivas numeric not null,
    puntualidad_pct numeric not null,
    incidencias integer not null default 0,
    primary key (empleado_id, semana_iso)
);

create table if not exists coaching_hist (
    id uuid primary key default uuid_generate_v4(),
    empleado_id uuid not null references empleados(id),
    semana_iso text not null,
    consejo_es text not null,
    consejo_en text,
    generado_el timestamp with time zone not null default now()
);

create index if not exists idx_registros_empleado_fecha
    on registros (empleado_id, tomado_en desc);

create index if not exists idx_desempeno_semana_supervisor
    on desempeno_semana (semana_iso, supervisor_id);
