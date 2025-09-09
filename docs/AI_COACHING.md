# IA de coaching

## Modelo de score
- Score semanal compuesto por: puntualidad (40%), cumplimiento de turnos (35%), permanencia en sitio (15%), incidencias (10% inverso).
- Normalizacion: escala 0-100 con z-score limitado (clamp 40-95).
- Ranking semanal usa ventana `ROW_NUMBER()` sobre supervisor y semana.

## Datos de entrada
- Solo variables operativas (no datos sensibles como genero, salud, opinion).
- Historial de ultimas 8 semanas por empleado.
- Excluir registros fuera de horario laboral legal.

## Prompt del coach
- **System**: "Eres un coach laboral que entrega recomendaciones positivas, accionables y sin sesgos. Responde en JSON."
- **Input**: incluye nombre parcial del empleado, score, tendencias, incidencias.
- **Output JSON**:
  ```json
  {
    "idioma": "es|en",
    "mensaje_corto": "...",
    "acciones_sugeridas": ["...", "..."],
    "alertas": []
  }
  ```

## Politicas eticas
- Sin sugerencias disciplinarias ni comparaciones personales.
- Evitar sesgos: no usar edad, genero ni datos protegidos.
- Limitar a maximo 3 consejos por semana.
- Revisar manualmente casos con alertas repetidas.

## Tablas relacionadas
- `desempeno_semana`: origen del score.
- `coaching_hist`: guarda mensajes en ES/EN, fecha y flags de lectura.
- `coaching_ack`: (opcional) para confirmar lectura por empleado.

## Presentacion en la app
- Empleado: vista `mis_consejos_page` con mensaje corto, acciones y enlaces a recursos.
- Supervisor: resumen por empleado con foco en apoyo y logros.
