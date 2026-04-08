# Migracion Firebase (Web-First)

Este proyecto ya esta adaptado para usar la estructura de datos de Gambeta en Flutter Web.

## 1) Cambiar proyecto/base de datos Firebase

Actualiza los valores en:
- lib/secret.dart
- android/app/google-services.json

Campos clave:
- projectId
- appId
- apiKey
- messagingSenderId
- authDomain (web)
- storageBucket

Nota: Firestore rules usan wildcard en /databases/{database}, por lo que soportan DB por nombre sin cambios de codigo.

## 2) Desplegar seguridad e indices

Ejecuta:

```bash
firebase use <tu-proyecto>
firebase deploy --only firestore:rules,firestore:indexes
```

## 3) Estructura esperada de colecciones

- usuarios/{uid}
- partidos/{partidoId}
- partidos/{partidoId}/votos/{uid}
- partidos/{partidoId}/eventos_live/{eventoId}

Campos esenciales de partidos:
- equipo1, equipo2, color1, color2
- goles1, goles2
- estado (Pendiente, En Juego, Finalizado)
- fecha, hora
- adminPartido
- convocatoria1, convocatoria2
- estadisticasJugadores
- timestampCierre
- hanVotado

## 4) Pruebas minimas tras cambio

1. Login y lectura de resumen
2. Crear partido
3. Editar convocatoria
4. Cerrar acta
5. Votar partido (una sola vez por usuario)
6. Calendario y mis valoraciones

## 5) Comandos de validacion

```bash
flutter analyze
flutter build web
```
