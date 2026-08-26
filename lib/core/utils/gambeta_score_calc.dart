double calcularNotaObjetiva({
  required int goles,
  required int asistencias,
  required String posicionFutsal,
  required int golesEquipo,
  required int golesRival,
}) {
  var nota = 5.0;

  final puntosGoles = (goles * 1.0).clamp(0.0, 3.0);
  final puntosAsistencias = asistencias * 0.6;
  nota += puntosGoles + puntosAsistencias;

  final pos =
      posicionFutsal.substring(0, posicionFutsal.length.clamp(0, 3)).toUpperCase();
  if (pos == 'POR' || pos == 'CIE') {
    if (golesRival == 0) {
      nota += 2.0;
    } else if (golesRival >= 1 && golesRival <= 2) {
      nota += 1.0;
    } else if (golesRival >= 6) {
      nota -= 1.0;
    }
  } else {
    if (golesRival == 0) {
      nota += 0.5;
    }
  }

  final diferencia = golesEquipo - golesRival;
  if (diferencia > 0) {
    nota += 0.5;
  } else if (diferencia == 0) {
    nota += 0.2;
  } else if (diferencia <= -3) {
    nota -= 0.5;
  }

  return nota.clamp(1.0, 10.0);
}
