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


Perfecto 💪 Aquí tienes el **README.md completo y profesional** para el proyecto **TurnoTrack**, basado en tu contexto y en la arquitectura que definimos.
Está escrito en formato Markdown y puede usarse directamente en GitHub o en cualquier repositorio técnico.

---

```markdown
# 🕒 TurnoTrack — Sistema Inteligente de Control de Asistencia

TurnoTrack es una aplicación móvil multiplataforma (Flutter + Supabase) para **registro de entradas y salidas de empleados** mediante **foto, ubicación GPS y código de verificación**, con **control de roles, analítica avanzada y módulo IA de desempeño**.  
Diseñada para adaptarse a organizaciones de cualquier tamaño y país (foco inicial: **Colombia**), garantiza **precisión, trazabilidad y privacidad** bajo buenas prácticas de ingeniería y cumplimiento normativo.

---

## 🚀 Objetivo

Digitalizar el control de asistencia con un sistema **seguro, auditable y automatizado**, permitiendo:

- Registro de entrada/salida con **foto** y **geolocalización ≤10 m**.  
- Validación automática de duplicados y precisión.  
- Administración de empleados y supervisores (CRUD + import CSV).  
- Panel de **analítica** con KPIs, gráficas y exportación CSV.  
- **Monitor IA** que evalúa el desempeño semanal y genera consejos personalizados para mejorar hábitos laborales.

---

## 🔑 Arquitectura y principios

**TurnoTrack** está diseñado siguiendo los principios de **Clean Architecture**, garantizando modularidad, mantenibilidad y seguridad:

- **Clean Architecture:** separación domain / data / presentation.  
- **Modular por features:** registro, gestión, analítica, desempeño-IA.  
- **Offline-first:** cache local + cola de sincronización.  
- **Seguridad by design:** RLS, Signed URLs, TLS, principio de mínimo privilegio.  
- **i18n:** Español / Inglés, accesible nivel A/AA.  
- **Escalable:** sobre Supabase (PostgreSQL + Auth + Storage + Edge Functions).  

---

## 🧭 Mapa de módulos

| Módulo | Descripción |
|:--|:--|
| **auth** | Login, sesión y recuperación de contraseña. |
| **registro** | Entrada/Salida con cámara + GPS + validaciones. |
| **gestion** | CRUD de empleados y supervisores, import CSV, picker por cédula. |
| **analitica** | KPIs, gráficas, mapa/heatmap y export CSV. |
| **desempeno** | Ranking semanal + coaching IA (consejos automáticos). |

---

## 📁 Estructura de carpetas (con descripción)

```

turnotrack/
├─ pubspec.yaml                         # Dependencias Flutter/Dart e i18n
├─ analysis_options.yaml                # Reglas de lint (flutter_lints)
├─ .gitignore                           # Ignora builds, .dart_tool, .env, etc.
├─ .editorconfig                        # Estilo consistente en editores
├─ README.md                            # Guía rápida (instalación/uso)
├─ docs/                                # Documentación técnica
│  ├─ ARCHITECTURE.md                   # Diseño de arquitectura (capas/módulos)
│  ├─ DB_SCHEMA.md                      # Tablas, índices, relaciones
│  ├─ RLS_POLICIES.md                   # Políticas RLS y racional
│  ├─ API.md                            # Edge Functions / contratos de integración
│  ├─ ANALYTICS.md                      # KPIs, vistas SQL, refresco MV
│  ├─ AI_COACHING.md                    # Modelo de score + prompt + ética
│  ├─ DEPLOYMENT.md                     # Entornos, variables, builds
│  ├─ TESTING.md                        # Estrategia de pruebas
│  ├─ SECURITY.md                       # Secretos, TLS, hardening
│  ├─ PRIVACY.md                        # Política y cumplimiento (ES/EN)
│  └─ CONTRIBUTING.md                   # Flujo de PRs, estilo, ramas
├─ policies/
│  ├─ privacy_es.md                     # Política ES lista para publicar
│  └─ privacy_en.md                     # Política EN lista para publicar
├─ sql/                                 # Scripts listos para Supabase
│  ├─ 01_schema.sql                     # Tablas e índices
│  ├─ 02_rls.sql                        # Políticas de acceso (RLS)
│  ├─ 03_triggers.sql                   # Validaciones (consecutivo, precisión, código)
│  ├─ 04_views.sql                      # Vistas analíticas
│  └─ README.md                         # Orden de ejecución
├─ edge-functions/
│  └─ onNewRegistro/README.md           # Webhook integración (firma HMAC)
├─ lib/
│  ├─ main.dart                         # Bootstrap app + ProviderScope
│  ├─ app_router.dart                   # Rutas con go_router
│  ├─ core/
│  │  ├─ config/                        # Configuración general
│  │  │  ├─ app_theme.dart              # Material 3, colores
│  │  │  └─ constants.dart              # Bucket, accuracy, retención
│  │  ├─ providers/                     # Inicializadores y globales
│  │  │  ├─ supabase_client_provider.dart
│  │  │  └─ connectivity_provider.dart
│  │  └─ services/                      # Servicios nativos
│  │     ├─ camera_service.dart         # Captura de foto
│  │     └─ geolocation_service.dart    # Ubicación precisa
│  ├─ features/                         # Módulos funcionales
│  │  ├─ auth/
│  │  │  └─ presentation/login_page.dart
│  │  ├─ home/presentation/home_page.dart
│  │  ├─ registro/
│  │  │  ├─ domain/entities.dart
│  │  │  ├─ data/registros_repo.dart
│  │  │  └─ presentation/{captura_page,entrada_page,salida_page}.dart
│  │  ├─ gestion/
│  │  │  ├─ data/{empleados_repo,supervisores_repo}.dart
│  │  │  └─ presentation/{lista,form,picker}.dart
│  │  ├─ analitica/
│  │  │  ├─ data/analytics_repo.dart
│  │  │  └─ presentation/{dashboard,mapa,detalle}.dart
│  │  └─ desempeno/
│  │     ├─ data/desempeno_repo.dart
│  │     └─ presentation/{ranking,mis_consejos}.dart
├─ assets/
│  └─ i18n/{es.arb,en.arb}              # Internacionalización
└─ test/                                # Pruebas unitarias e integración
├─ registro_test.dart
├─ rls_policies_test.dart
├─ analytics_kpis_test.dart
└─ coaching_score_test.dart

````

---

## 🔧 Capa por capa

| Capa | Función |
|------|----------|
| **domain/** | Entidades, value objects, casos de uso. |
| **data/** | Repositorios (Supabase + cache local Isar/Drift). |
| **presentation/** | UI, providers Riverpod, estados. |
| **core/services/** | Cámara, GPS, permisos. |
| **core/providers/** | Configuración global, Supabase, conectividad. |
| **sql/** | Migraciones (orden 01→04). |
| **edge-functions/** | Integraciones seguras (webhooks / IA). |

---

## ⚙️ Requisitos

### 📦 Tecnologías principales
- Flutter ≥ 3.22  
- Dart ≥ 3.0  
- Supabase (Auth, Postgres, Storage, Edge Functions)  
- Riverpod, go_router, json_serializable, geolocator, camera, image_picker

### 🔐 Variables necesarias
```bash
SUPABASE_URL=<tu_url>
SUPABASE_ANON_KEY=<tu_clave>
````

### 📍 Configuración por defecto

* Precisión GPS máxima: **10 m**
* Retención de datos: **24 meses**
* Bucket: **fotos-registros**
* País inicial: **Colombia**

---

## 🛠️ Setup rápido

1. Clona el repositorio

   ```bash
   git clone https://github.com/tu-org/turnotrack.git
   cd turnotrack
   ```

2. Instala dependencias

   ```bash
   flutter pub get
   ```

3. Crea un proyecto en [Supabase](https://supabase.com).
   Copia tus credenciales (`SUPABASE_URL`, `SUPABASE_ANON_KEY`).

4. Ejecuta los scripts SQL (en orden 01→04) desde el panel SQL.
   Crea el bucket `fotos-registros`.

5. Ejecuta la app:

   ```bash
   flutter run --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>
   ```

---

## 🧠 Módulos principales

### 🔐 Auth

* Login con email y password (Supabase Auth).
* Roles: admin, supervisor, operador.
* Recuperación de contraseña.

### 🕓 Registro

* Entrada/salida con cámara + ubicación.
* Validación de precisión (≤10 m).
* Generación de código de verificación y subida de foto (Signed URL).
* Sincronización offline.

### 👥 Gestión

* CRUD de empleados y supervisores.
* Importación CSV y picker por cédula.
* RLS por rol.

### 📊 Analítica

* KPIs diarios/semanales.
* Gráficas de entradas/salidas.
* Horas trabajadas, top tardanzas.
* Exportación CSV y mapa de marcaciones.

### 🤖 Desempeño IA

* Cálculo semanal de score (puntualidad, consistencia, jornada, integridad).
* Ranking por equipo o global.
* Coaching IA: hasta 3 consejos positivos por empleado.
* Historial de desempeño y hábitos.

---

## 🧩 Documentación técnica

La carpeta `/docs` incluye toda la documentación para mantenimiento y auditoría:

| Archivo             | Contenido principal                  |
| ------------------- | ------------------------------------ |
| **ARCHITECTURE.md** | Diseño y decisiones de arquitectura. |
| **DB_SCHEMA.md**    | Tablas, índices y triggers.          |
| **RLS_POLICIES.md** | Políticas RLS y ejemplos.            |
| **API.md**          | Edge Functions, payloads, endpoints. |
| **ANALYTICS.md**    | KPIs, vistas y materialized views.   |
| **AI_COACHING.md**  | Modelo de score, prompts, ética.     |
| **DEPLOYMENT.md**   | Guía de despliegue y builds.         |
| **TESTING.md**      | Cobertura y casos clave.             |
| **SECURITY.md**     | Secretos, TLS, hardening.            |
| **PRIVACY.md**      | Cumplimiento normativo.              |
| **CONTRIBUTING.md** | Guía de colaboración.                |

---

## 🧪 Pruebas y calidad

* Linter: `flutter_lints` activo.
* CI opcional: analiza, testea y compila.
* Casos cubiertos:

  * Precisión >10 m → rechazo.
  * Doble entrada/salida → rechazo.
  * RLS (admin/supervisor/operador).
  * Exportación CSV válida.
  * Coaching IA máximo 3 consejos.

Ejecutar:

```bash
flutter test
```

---

## 🧱 Seguridad y privacidad

* RLS habilitado en todas las tablas.
* Fotos con Signed URLs (24 h).
* TLS en tránsito.
* JWT con rol en claims.
* Retención: 24 meses.
* Cumplimiento: Ley 1581 de 2012 (Colombia) + GDPR-compatible.

---

## ⚙️ Troubleshooting

| Problema                      | Solución                                                 |
| ----------------------------- | -------------------------------------------------------- |
| Error de cámara/GPS           | Verificar permisos en dispositivo.                       |
| Falla RLS “permission denied” | Revisar claim de rol en JWT.                             |
| No se muestra foto            | Confirmar bucket `fotos-registros` y signed URL vigente. |
| Supabase Function no responde | Revisar logs de Edge Functions o secret de firma.        |

---

## 🧩 Contribución

1. Crea rama `feature/nueva-funcionalidad`.
2. Realiza commits siguiendo [Conventional Commits](https://www.conventionalcommits.org).
3. Envía PR con checklist: lint, tests, docs.
4. Revisión cruzada por otro desarrollador.

---

## 📄 Licencia

Proyecto privado interno de desarrollo.
Distribución o uso externo requiere autorización del titular.

---

> © 2025 — **TurnoTrack** · Desarrollado con Flutter + Supabase ·
> Arquitectura limpia, analítica avanzada e IA responsable.

