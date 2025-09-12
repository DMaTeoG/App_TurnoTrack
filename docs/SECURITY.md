# Seguridad

## Secretos y llaves
- No almacenar claves en repo. Usar `--dart-define` o gestores seguros (1Password, Vault).
- Rotacion semestral de `EDGE_ONNEWREGISTRO_SECRET`.
- Service role solo en servidores backend protegidos.

## Transporte y cifrado
- Consumir Supabase exclusivamente via HTTPS (TLS 1.2+).
- Firmar URLs de evidencia con expiracion corta (5 min por defecto).
- Encriptar fotos en reposo con configuracion de Storage.

## Retencion y minimizacion
- Retener registros operativos por 24 meses.
- Purgar exportaciones CSV >7 dias.
- Anonimizar datos en ambientes de testing.

## Hardening
- Validar inputs en app y en triggers (precision, rango de horas).
- Limitar tamano maximo de foto (<=1.5 MB) y resolucion.
- Agregar headers de seguridad en panel web (si aplica): CSP, X-Frame-Options.
- Monitorear intentos fallidos de login (rate limiting via Supabase).

## JWT y scopes
- Usar claims personalizados para rol (`role=admin|supervisor|operador`).
- Revocar tokens en cambios de rol.
- Verificar expiracion antes de ejecutar acciones criticas.
