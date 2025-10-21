# Edge Function: onNewRegistro

## Contrato
- Metodo: `POST`
- Cabeceras obligatorias:
  - `Content-Type: application/json`
  - `X-Signature`: HMAC SHA-256 con secreto `EDGE_ONNEWREGISTRO_SECRET`
- Body JSON:
  - `registro_id` (uuid)
  - `empleado_id` (uuid)
  - `tipo` (`entrada`|`salida`)
  - `tomado_en` (ISO8601)
  - `gps.lat`, `gps.lng`, `gps.precision_m`
  - `evidencia_url`

## Flujo
1. Verificar firma HMAC.
2. Validar payload y buscar registro en Postgres.
3. Invocar integraciones externas (webhooks, planillas, BI).
4. Registrar estado en `webhook_logs` y responder 200.

## Errores y reintentos
- 401 firma invalida -> no reintentar.
- 400 payload invalido -> no reintentar.
- 500 error temporal -> Supabase reintenta 7 veces con backoff exponencial.

## Desarrollo local
```
supabase functions serve onNewRegistro --env-file supabase/.env
```

## Despliegue
```
supabase functions deploy onNewRegistro --env-file supabase/.env
```
