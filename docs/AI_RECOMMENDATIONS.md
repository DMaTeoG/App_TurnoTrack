# 🤖 Sistema de Recomendaciones IA Personalizadas

## Descripción

Sistema inteligente que genera consejos y tips personalizados basados en:
- ✅ **Nombre del usuario** (saludo personalizado)
- ✅ **Rol** (worker, supervisor, manager)
- ✅ **Día de la semana** (tips contextuales)
- ✅ **Métricas reales** (ventas, asistencia, puntualidad)
- ✅ **Tendencias** (mejoras o alertas)

---

## 🎯 Ejemplos de Consejos por Rol

### 👷 **Workers (Vendedores)**

#### Basado en Ventas
```
Natalie, llevas 5 días sin registrar ventas. Los viernes son ideales para 
ventas altas, la gente busca celebrar. ¡Aprovecha! ¡Es tu momento de brillar! 💫
```

```
Carlos, tu ticket promedio es $85. Intenta ofrecer productos complementarios 
para aumentarlo. Días ideales para promociones y ofertas especiales.
```

```
María, ¡excelente trabajo! Llevas 15 ventas este mes con un promedio de $120. 
Viernes para cerrar con broche de oro. ¡Sigue así, vas por buen camino! 🌟
```

#### Basado en Puntualidad
```
Juan, tu puntualidad es del 65%. Intenta salir 10 minutos antes de casa. 
Llegar temprano mejora tu ranking y da buena impresión. ⏰
```

```
Andrea, ¡tu puntualidad es del 95%! Sigue así y pronto estarás en el 
top 3 del ranking. 🏆
```

#### Por Día de la Semana
```
Pablo, los lunes son para arrancar con energía. Aprovecha que los clientes 
planean su semana y necesitan productos.
```

```
Sofía, mitad de semana, ¡no aflojes! Días ideales para promociones y 
ofertas especiales.
```

---

### 👔 **Supervisores**

#### Basado en Equipo
```
Laura, 4 de 10 miembros tienen puntualidad baja. Considera una reunión 1-on-1 
para entender sus desafíos. La empatía construye equipos fuertes. 💪
```

```
Roberto, ¡tu equipo brilla! 8 de 10 miembros tienen excelente puntualidad. 
Celebra sus logros y mantén el momentum. 🌟
```

#### Por Día de la Semana
```
Elena, establece objetivos claros para la semana con tu equipo. 
Tu actitud define la del equipo.
```

```
Diego, da feedback constructivo a medio camino. Tu liderazgo impacta 
directamente en el éxito del equipo.
```

---

### 🏢 **Managers**

#### Basado en KPIs
```
Ana, la asistencia promedio es 75%. Considera implementar incentivos o 
revisar políticas. Un equipo presente es un equipo productivo. 🎯
```

```
Fernando, ¡números extraordinarios! Asistencia: 92%, Puntualidad: 88%. 
Tu estrategia está funcionando. 🚀
```

#### Por Día de la Semana
```
Patricia, revisa las métricas de la semana pasada y ajusta estrategia. 
Los datos guían, pero la intuición decide.
```

```
Miguel, reúnete con supervisores para alinear objetivos. Las decisiones 
de hoy construyen el éxito de mañana.
```

---

## 🎨 Sistema de Prioridades Visuales

### 🔴 **Alta Prioridad** (Rojo/Naranja)
- Puntualidad < 70%
- Días sin ventas > 3
- Asistencia del equipo < 80%
- Badge: "Urgente"

### 🟡 **Media Prioridad** (Morado/Azul)
- Consejos normales
- Tips por día de la semana
- Mejoras incrementales

### 🟢 **Baja Prioridad** (Verde/Turquesa)
- Celebraciones
- Reconocimientos
- Motivación positiva

---

## 📊 Flujo de Decisión

```
Usuario entra al Home
    ↓
Sistema detecta:
    - Nombre: "Natalie"
    - Rol: "worker"
    - Día: "Viernes"
    ↓
Obtiene métricas:
    - Ventas: 5 este mes, última venta hace 6 días
    - Puntualidad: 82%
    ↓
Analiza prioridad:
    1. ¿Lleva días sin vender? → SÍ (6 días) ← ALTA PRIORIDAD
    2. ¿Puntualidad baja? → NO (82% es aceptable)
    3. ¿Rendimiento bueno? → Parcial
    ↓
Genera consejo:
    "Natalie, llevas 6 días sin registrar ventas. Viernes de ventas altas, 
    la gente busca celebrar. ¡Aprovecha! ¡Es tu momento de brillar! 💫"
    
Color: 🔴 Rojo/Naranja (Alta prioridad)
Ícono: 📈 trending_up (Ventas)
Badge: "Urgente"
```

---

## 🔄 Tips por Día de la Semana

### Para Workers
- **Lunes**: "Aprovecha que los clientes planean su semana"
- **Martes/Miércoles**: "Días ideales para promociones"
- **Jueves**: "Los clientes preparan su fin de semana"
- **Viernes**: "Viernes de ventas altas, ¡aprovecha!"
- **Sábado**: "Para ventas en volumen"
- **Domingo**: "Los clientes tienen tiempo, atención personalizada"

### Para Supervisores
- **Lunes**: "Establece objetivos claros para la semana"
- **Martes/Miércoles**: "Da feedback constructivo"
- **Jueves**: "Prepara cierre fuerte de semana"
- **Viernes**: "Reconoce los logros semanales"

### Para Managers
- **Lunes**: "Revisa métricas y ajusta estrategia"
- **Martes/Miércoles**: "Reúnete con supervisores"
- **Jueves**: "Analiza tendencias y proyecta resultados"
- **Viernes**: "Celebra wins y planifica mejoras"

---

## 🛠️ Implementación Técnica

### Provider
```dart
final aiRecommendationsProvider = FutureProvider.autoDispose<AIRecommendation>((ref) async {
  // 1. Obtiene usuario actual
  // 2. Extrae nombre y día de la semana
  // 3. Según rol, ejecuta análisis específico
  // 4. Prioriza: ventas > asistencia > general
  // 5. Retorna consejo personalizado
});
```

### Widget en Home
```dart
recommendationAsync.when(
  data: (rec) => _buildRecommendationCard(rec),
  loading: () => "Generando consejo personalizado...",
  error: () => "¡Hoy es un buen día para dar lo mejor de ti! 💫",
)
```

---

## ✨ Características Clave

1. **100% Personalizado**: Usa el nombre real del usuario
2. **100% Dinámico**: Basado en datos reales de Supabase
3. **Contextual**: Adapta consejos al día de la semana
4. **Multi-rol**: Workers, Supervisores, Managers
5. **Prioridades**: Urgente → Normal → Celebración
6. **Graceful Fallback**: Si no hay datos, da consejo general
7. **Visual**: Colores e íconos según tipo y prioridad

---

## 🚀 Mejoras Futuras

- [ ] Aprendizaje de patrones (ML)
- [ ] Consejos basados en clima/temporada
- [ ] Comparación con período anterior
- [ ] Sugerencias de productos específicos
- [ ] Alertas de oportunidades en tiempo real
- [ ] Gamificación con badges por seguir consejos
