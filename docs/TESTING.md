# Estrategia de pruebas

## Piramide de pruebas
- **Unit**: entidades, use cases, repositorios (mock supabase).
- **Widget**: pantallas principales con estados Riverpod.
- **Integracion**: flujo de registro completo con camara/GPS mock.
- **SQL**: scripts `test/rls_policies_test.dart` y consultas KPIs.

## Casos criticos
- Rechazo cuando `precision_m > 10`.
- Bloqueo de entradas duplicadas consecutivas.
- Validacion RLS por rol (admin, supervisor, operador).
- Export CSV: generacion y acceso via URL firmada.
- KPIs: calculo correcto de horas y puntualidad.
- IA: maximo 3 consejos y tono positivo.

## Cobertura
- Objetivo minimo 75% branches.
- Reporte generado con `flutter test --coverage`.

## Comandos
- `flutter test`
- `dart run build_runner test --delete-conflicting-outputs` (si se usan generadores).
- `psql -f sql/tests/*.sql` para verificaciones RLS.

## Automatizacion
- CI ejecuta lint, tests y build en cada PR.
- Usar mocks para servicios de camara y geolocalizacion.
