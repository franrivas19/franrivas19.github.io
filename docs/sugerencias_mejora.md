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
