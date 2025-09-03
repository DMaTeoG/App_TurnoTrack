# Arquitectura TurnoTrack

## Principios clave
- Clean Architecture con separacion domain / data / presentation.
- Modular por feature para aislar dependencias y facilitar escalamiento.
- Offline-first con cache local, cola de sincronizacion y reconciliacion.
- Seguridad by design: RLS, TLS, signed URLs y minimo privilegio.
- I18n (ES/EN) y accesibilidad alineada con Material 3.

## Diagrama de capas (ASCII)
```
┌────────────┐   ┌───────────┐   ┌────────────┐
│ Presentation│ ← │ Providers │ → │ Core Svcs  │
└──────┬──────┘   └────┬──────┘   └────┬──────┘
       │               │               │
┌──────▼──────┐  uses  │       exposes ▼
│  Domain     │────────┴────────► Entities/VO
└──────┬──────┘                  ▲
       │                         │ maps
┌──────▼──────┐   maps   ┌───────┴──────┐
│   Data      │────────► │  Supabase    │
└─────────────┘          └──────────────┘
```

## Flujos clave
- **Login**: UI (go_router) → AuthController (presentation) → AuthUseCase (domain) → Supabase Auth (data). Guarda sesion en cache segura, expone estado via Riverpod.
- **Registrar entrada/salida**: CapturaPage → CameraService + GeolocationService → RegistroController valida GPS, precision ≤10 m y consecutivo → RegistroRepo sube imagen (Storage) y crea registro en tabla `registros`.
- **Sincronizacion offline**: Acciones se guardan en cola local (Isar/Drift). Un SyncWorker (core/services) intenta reenviar cuando ConnectivityProvider reporta conectividad. Resolver conflictos con sellos `synced_at`.
- **Export CSV**: AnaliticaController invoca AnalyticsRepo → supabase RPC/edge function que genera CSV. UI descarga usando Signed URL con expiracion corta.

## Limites de modulos
- `auth`: solo maneja login, estado de sesion, refresh tokens.
- `registro`: flujo de marcacion con servicios de camara/gps y validaciones locales.
- `gestion`: CRUD de empleados y supervisores, import CSV y pickers.
- `analitica`: lectura de KPIs, graficos, mapa y exportaciones.
- `desempeno`: ranking semanal, calculo de score e integracion con IA coaching.

## Decisiones destacadas (mini ADR)
- **Riverpod**: estado reactivo con providers escopados y testables.
- **go_router**: navegacion declarativa con deep links y guards.
- **Supabase**: reemplaza backend custom, aprovecha Postgres, Auth, Storage y Edge Functions.
- **Signed URLs**: protegen evidencia fotografica evitando URLs publicas.
- **Isar/Drift**: almacenamiento local optimizado para offline-first y queries reactivas.
