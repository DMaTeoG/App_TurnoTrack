# Contribuir a TurnoTrack

## Flujo de ramas
- `main`: estable, despliegue a produccion.
- `develop`: integracion continua.
- `feature/<topic>`: trabajo aislado por funcionalidad.
- Merge de feature → develop via Pull Request.

## Estilo de commits
- Convencional (Conventional Commits):
  - `feat: agregar flujo de registro`
  - `fix: corregir precision gps`
  - `docs: actualizar privacy`
- Incluir referencia a issue cuando aplique.

## Requerimientos de PR
- Lint (`flutter analyze`) y tests (`flutter test`) pasan.
- Cobertura no disminuye.
- Docs actualizados (README, docs/).
- Checklist:
  - [ ] Tests agregados/actualizados.
  - [ ] Variables de entorno documentadas.
  - [ ] Screenshots adjuntos (si UI).

## Revision
- Al menos una aprobacion de mantenedor.
- Comentarios resueltos antes del merge.
- Squash merge recomendado.
