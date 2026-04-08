# Sugerencias de Mejora para Scarpa

## Objetivo
Este documento resume mejoras propuestas para el proyecto, clasificadas por prioridad y por tipo (correcciones, mejoras técnicas y nuevas funcionalidades).

## 1. Prioridad Alta (arreglar primero)

### 1.1 Seguridad y permisos
- Evitar control de admin por email hardcodeado en cliente.
- Definir roles en base de datos (`admin`, `capitan`, `jugador`) y hacer cumplir permisos con reglas de Firestore.
- Mantener ocultación de opciones en UI, pero no depender de eso para seguridad.

### 1.2 Selección de partido pendiente
- La consulta de "siguiente pendiente" debe ser determinista (`orderBy` + índice).
- Evitar que Acta cierre un partido incorrecto cuando hay varios pendientes.

### 1.3 Votaciones y consistencia de datos
- Evitar recrear el estado de votación en cada `build`.
- Usar transacciones/validaciones para impedir votos duplicados o inconsistentes.
- Guardar el estado de "ya votó" con comprobación atómica.

### 1.4 Cierre de acta
- Mover estado editable (goles/estadísticas) fuera del builder reactivo para que no se resetee con snapshots.
- Añadir confirmación antes de cerrar acta (acción crítica).

### 1.5 Reglas de Firestore en repositorio
- Añadir y versionar reglas (`firestore.rules`) e índices (`firestore.indexes.json`).
- Documentar despliegue de reglas en flujo de trabajo.

## 2. Prioridad Media (calidad y mantenibilidad)

### 2.1 Formularios y validaciones
- Registro: validar email, contraseña y formato de fecha.
- Crear partido: validar fecha/hora con pickers nativos en lugar de texto libre.
- Unificar validaciones y mensajes de error.

### 2.2 Router y autenticación
- Añadir refresco reactivo del router con cambios de sesión (`authStateChanges`).
- Revisar redirecciones para evitar estados intermedios inconsistentes.

### 2.3 Tests
- Pasar de test de "sanity" a cobertura real:
  - tests unitarios de servicios (FirestoreService),
  - tests de widget para auth, acta, votaciones,
  - tests de flujos críticos.

### 2.4 Documentación
- Reemplazar README genérico por documentación del proyecto:
  - setup local,
  - estructura y arquitectura,
  - colecciones de Firestore,
  - comandos de desarrollo.

### 2.5 Deuda de lint/analyzer
- Corregir usos de APIs deprecadas (`withOpacity`, etc.).
- Reducir warnings de `flutter analyze` a cero como objetivo de calidad.

## 3. Nuevas funcionalidades recomendadas

### 3.1 Gestión de partidos
- Historial de partidos con filtros por estado y fecha.
- Vista detallada de próximos partidos y resultados pasados.
- Selección explícita de partido para acta y edición.

### 3.2 Convocatorias
- Confirmación de asistencia por jugador.
- Cierre automático de convocatoria a una hora límite.
- Gestión de suplentes y cupos por posición.

### 3.3 Estadísticas avanzadas
- Métricas por temporada y ventanas temporales.
- Rachas, promedio por partido y ranking por rol.
- MVP del partido y evolución del rendimiento.

### 3.4 Módulo de turnos
- Persistencia de configuración de turnos por deporte.
- Duración configurable del turno.
- Integración de turnos con jugadores reales de convocatoria (no solo hardcode).

### 3.5 Administración y auditoría
- Registro de acciones críticas (crear partido, cerrar acta, votar).
- Panel básico de auditoría para admins.

## 4. Plan sugerido por fases

### Fase 1 (1-2 semanas) - Seguridad y consistencia
- Roles y reglas de Firestore.
- Corrección de consulta de partido pendiente.
- Robustecer cierre de acta y votaciones con transacciones.

### Fase 2 (1-2 semanas) - Experiencia y estabilidad
- Validaciones de formularios y pickers.
- Estado más sólido en pantallas críticas.
- Corrección de warnings de analyzer.

### Fase 3 (2-3 semanas) - Funcionalidades de valor
- Historial de partidos y estadísticas avanzadas.
- Convocatorias con confirmación.
- Mejoras del módulo de turnos con persistencia.

## 5. Criterios de éxito
- `flutter analyze` sin incidencias.
- Cobertura mínima de tests en módulos críticos.
- Cero incidencias de seguridad por permisos en cliente.
- Flujos críticos (registro, crear partido, acta, votar) estables y trazables.

## 6. Plan de Iteraciones

Este plan divide las mejoras en iteraciones manejables de 1-2 semanas cada una, permitiendo revisiones y ajustes continuos. Cada iteración incluye tareas específicas, criterios de aceptación y dependencias.

### Iteración 1: Seguridad y Permisos (1 semana) ✅ Completada
**Objetivo:** Establecer una base segura eliminando riesgos de permisos en cliente.

**Tareas:**
- ✅ Implementar roles en Firestore (`admin`, `capitan`, `jugador`).
- ✅ Crear y desplegar reglas de Firestore (`firestore.rules`).
- ✅ Remover control de admin hardcodeado en `firestore_service.dart`.
- ✅ Añadir índices necesarios (`firestore.indexes.json`).
- ✅ Corregir consulta de partido pendiente con `orderBy`.

**Criterios de aceptación:**
- ✅ Permisos verificados en servidor, no en cliente.
- ✅ Reglas desplegadas y versionadas en repositorio.
- ✅ Pruebas manuales de acceso restringido.

**Dependencias:** Ninguna.
**Riesgos:** Posibles bloqueos temporales de acceso durante despliegue.

### Iteración 2: Consistencia de Datos (1 semana)
**Objetivo:** Asegurar operaciones deterministas y atómicas en datos críticos.

**Tareas:**
- Corregir consulta de partido pendiente con `orderBy` y índice en `firestore_service.dart`.
- Implementar transacciones para cierre de acta y votaciones.
- Mover estado editable fuera del builder en `acta_screen.dart`.
- Añadir confirmación antes de cerrar acta.

**Criterios de aceptación:**
- Consultas deterministas sin conflictos de partidos.
- Votos y cierres atómicos, sin duplicados.
- Estado persistente en acta sin resets inesperados.

**Dependencias:** Iteración 1 completada.
**Riesgos:** Posibles conflictos de concurrencia durante pruebas.

### Iteración 3: Validaciones y Experiencia de Usuario (1 semana)
**Objetivo:** Mejorar la robustez de formularios y navegación.

**Tareas:**
- Unificar validaciones en formularios (registro, crear partido).
- Reemplazar inputs de texto por pickers nativos para fechas/horas.
- Añadir refresco reactivo del router con `authStateChanges`.
- Corregir warnings de `flutter analyze` (APIs deprecadas).

**Criterios de aceptación:**
- Formularios con validación en tiempo real y mensajes claros.
- Navegación sin estados inconsistentes.
- `flutter analyze` sin warnings.

**Dependencias:** Iteraciones 1-2 completadas.
**Riesgos:** Cambios en UI pueden afectar experiencia existente.

### Iteración 4: Tests y Documentación (1 semana)
**Objetivo:** Establecer base de calidad con cobertura y documentación.

**Tareas:**
- Implementar tests unitarios para `FirestoreService`.
- Añadir tests de widget para pantallas críticas (auth, acta, votaciones).
- Reemplazar README con documentación completa (setup, arquitectura, comandos).
- Alcanzar cobertura mínima del 70% en módulos críticos.

**Criterios de aceptación:**
- Tests pasando en CI/CD.
- Documentación clara y actualizada.
- Cobertura reportada y visible.

**Dependencias:** Iteraciones 1-3 completadas.
**Riesgos:** Curva de aprendizaje en testing para equipo pequeño.

### Iteración 5: Nuevas Funcionalidades - Gestión de Partidos (2 semanas)
**Objetivo:** Añadir valor con historial y estadísticas básicas.

**Tareas:**
- Implementar historial de partidos con filtros.
- Vista detallada de partidos (próximos y pasados).
- Estadísticas avanzadas (rachas, promedios por temporada).
- Selección explícita de partido para acta.

**Criterios de aceptación:**
- Historial navegable y filtrable.
- Estadísticas calculadas correctamente.
- Integración fluida con flujos existentes.

**Dependencias:** Iteraciones 1-4 completadas.
**Riesgos:** Complejidad de queries para estadísticas.

### Iteración 6: Nuevas Funcionalidades - Convocatorias y Turnos (2 semanas)
**Objetivo:** Completar módulo de convocatorias y mejorar turnos.

**Tareas:**
- Sistema de confirmación de asistencia.
- Cierre automático de convocatorias.
- Persistencia de configuración de turnos.
- Integración de turnos con jugadores reales.

**Criterios de aceptación:**
- Convocatorias con estados claros (confirmado, pendiente).
- Turnos configurables y persistentes.
- Integración con gestión de partidos.

**Dependencias:** Iteración 5 completada.
**Riesgos:** Lógica compleja para automatización.

### Iteración 7: Administración y Auditoría (1 semana)
**Objetivo:** Cerrar con herramientas de administración.

**Tareas:**
- Registro de acciones críticas en Firestore.
- Panel básico de auditoría para admins.
- Revisión final de seguridad y rendimiento.

**Criterios de aceptación:**
- Logs de acciones críticas disponibles.
- Panel funcional para admins.
- Rendimiento verificado en flujos críticos.

**Dependencias:** Iteraciones 5-6 completadas.
**Riesgos:** Sobrecarga en base de datos con logs.

**Notas generales del plan:**
- Cada iteración termina con una revisión: ejecutar `flutter analyze`, tests y pruebas manuales.
- Estimaciones son para un desarrollador; ajustar según equipo.
- Priorizar correcciones sobre nuevas features si surgen bugs críticos.
- Usar Git branches por iteración para aislamiento.
