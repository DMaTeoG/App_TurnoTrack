# TurnoTrack

TurnoTrack digitaliza el control de asistencia operacional combinando verificación fotográfica, geolocalización precisa y reglas automáticas para prevenir fraudes. La solución ofrece paneles de analítica, ranking de desempeño impulsado por IA y herramientas de gestión de personal, todo respaldado por Supabase con políticas RLS y sincronización offline-first.

## Prerrequisitos
- Flutter 3.19 o superior (`flutter doctor` sin issues).
- Cuenta Supabase con proyecto configurado.
- Acceso a las claves `SUPABASE_URL` y `SUPABASE_ANON_KEY`.
- (Opcional) SDK de plataformas: Android Studio, Xcode, Visual Studio (Windows).

## Configuración rápida
1. Clonar el repositorio y entrar en la carpeta `turnotrack/`.
2. Ejecutar `flutter pub get`.
3. Crear las tablas y políticas: ejecutar los scripts `sql/01_schema.sql` → `sql/04_views.sql` en Supabase.
4. Crear el bucket de Storage `registros` con políticas RLS según `sql/02_rls.sql`.
5. Lanzar la app con:
   ```bash
   flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<anon>
   ```

## Comandos útiles
- `flutter analyze` — linting con `flutter_lints`.
- `flutter test` — ejecuta la pirámide de pruebas.
- `flutter run -d device_id --dart-define=SUPABASE_URL=...` — arranca en un dispositivo específico.
- `flutter test --coverage` — genera reporte de cobertura para CI.

## Módulos y rutas principales
- `auth`: flujo de inicio de sesión (`/login`).
- `home`: menú principal con accesos rápidos (`/home`).
- `registro`: entrada/salida con captura de foto y GPS (`/registro/entrada`, `/registro/salida`).
- `gestion`: administración de empleados y supervisores (`/gestion` y subrutas `empleados`, `supervisores`).
- `analitica`: dashboard de KPIs, mapas y exportaciones (`/analitica`).
- `desempeno`: ranking semanal e IA coaching (`/desempeno`).

## Troubleshooting
- **Permisos cámara/GPS**: revisar permisos en el dispositivo o emulador y reiniciar la app; en iOS agregar descripciones en `Info.plist`.
- **Errores RLS (401/403)**: confirmar que el perfil y el rol tengan las políticas definidas en `sql/02_rls.sql`.
- **Precisión GPS insuficiente**: validar que el dispositivo tenga ubicación activada y cielo abierto; el requisito es ≤10 m.
- **Fotos no suben**: revisar la política de Storage y que el bucket acepte `image/jpeg` con URL firmadas.
