# Despliegue y entornos

## Entornos
- **Dev**: Supabase project aislado, datos sinteticos, feature flags activos.
- **Stage**: replica de produccion, pruebas QA, accesos limitados.
- **Prod**: datos reales, monitoreo 24/7, backups diarios.

## Variables requeridas
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE` (solo en servidores seguros)
- `EDGE_ONNEWREGISTRO_SECRET`
- `STORAGE_BUCKET_REGISTROS`
- `STORAGE_BUCKET_EXPORTS`

## Configuracion de Storage
1. Crear bucket `registros` privado.
2. Crear bucket `exports` privado.
3. Aplicar policies definidas en `sql/02_rls.sql`.

## Pipeline de build
- Ejecutar `flutter pub get`, `flutter analyze`, `flutter test`.
- Android:
  - Configurar `android/key.properties` y keystore.
  - `flutter build appbundle --dart-define=...`
- iOS:
  - `flutter build ipa --dart-define=...`
  - Firmas gestionadas via Xcode y App Store Connect.

## Edge Functions
- `supabase functions deploy onNewRegistro --env-file supabase/.env`.
- Registrar webhook en tabla `webhook_subscribers`.
- Monitorear logs con `supabase functions logs`.

## Versionado y rollout
- Usa build numbers incrementales.
- Estrategia staged rollout (Play Store, TestFlight).
- Feature flags via tabla `feature_flags`.
