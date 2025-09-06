# API y Edge Functions

## Edge Function `onNewRegistro`
- **Endpoint**: `POST https://<project>.functions.supabase.co/onNewRegistro`
- **Headers**:
  - `Content-Type: application/json`
  - `X-Signature: <HMAC-SHA256(payload, EDGE_SECRET)>`
- **Payload ejemplo**:
  ```json
  {
    "registro_id": "uuid",
    "empleado_id": "uuid",
    "tipo": "entrada",
    "tomado_en": "2025-01-01T08:00:00Z",
    "gps": {"lat": 4.711, "lng": -74.072, "precision_m": 6.4},
    "evidencia_url": "https://..."
  }
  ```
- **Respuestas**:
  - `200 OK` procesado y ACK.
  - `400 Bad Request` payload invalido.
  - `401 Unauthorized` firma invalida.
  - `500` error temporal → reintentos con backoff exponencial (1,5,15 min).

## Webhooks y reintentos
- Supabase reintenta hasta 7 veces.
- Registrar eventos idempotentes usando `registro_id`.
- Loggear fallos en tabla `webhook_logs`.

## PostgREST paginado
- Endpoint base: `https://<project>.supabase.co/rest/v1/registros`.
- Filtros soportados:
  - `empleado_id=eq.<uuid>`
  - `tipo=eq.entrada`
  - `tomado_en=gte.<ISO>` y `tomado_en=lt.<ISO>`
  - `supervisor_id=eq.<uuid>`
- Paginacion via `?limit=100&offset=200`.
- Orden recomendado: `order=tomado_en.desc`.

## Export CSV
- RPC `rpc_export_registros` (Edge Function opcional).
- Entrada: rango fechas, supervisor opcional, idioma.
- Salida: URL firmada en bucket `exports` con expiracion configurable (default 24h).
