class PlayerStat {
  PlayerStat({
    required this.id,
    required this.nombre,
    required this.goles,
    required this.asistencias,
    required this.equipo,
    required this.haJugado,
    this.posicion = 'Sin definir',
    this.puntosDefensivos = 0,
    this.notaObjetiva = 0,
  });

  final String id;
  final String nombre;
  final int goles;
  final int asistencias;
  final int equipo;
  final bool haJugado;
  final String posicion;
  final int puntosDefensivos;
  final double notaObjetiva;

  bool get esInvitado => id.startsWith('invitado_');

  factory PlayerStat.fromMap(Map<String, dynamic> data) {
    return PlayerStat(
      id: (data['id'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? 'Jugador',
      goles: (data['goles'] as num?)?.toInt() ?? 0,
      asistencias: (data['asistencias'] as num?)?.toInt() ?? 0,
      equipo: (data['equipo'] as num?)?.toInt() ?? 1,
      haJugado: (data['haJugado'] as bool?) ?? true,
      posicion: (data['posicionFutsal'] as String?) ?? 'Sin definir',
      puntosDefensivos: (data['puntosDefensivos'] as num?)?.toInt() ?? 0,
      notaObjetiva: (data['notaObjetiva'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'goles': goles,
      'asistencias': asistencias,
      'equipo': equipo,
      'haJugado': haJugado,
      'posicionFutsal': posicion,
      'puntosDefensivos': puntosDefensivos,
      'notaObjetiva': notaObjetiva,
    };
  }

  PlayerStat copyWith({
    int? goles,
    int? asistencias,
    bool? haJugado,
    int? equipo,
    String? posicion,
    int? puntosDefensivos,
    double? notaObjetiva,
  }) {
    return PlayerStat(
      id: id,
      nombre: nombre,
      goles: goles ?? this.goles,
      asistencias: asistencias ?? this.asistencias,
      haJugado: haJugado ?? this.haJugado,
      equipo: equipo ?? this.equipo,
      posicion: posicion ?? this.posicion,
      puntosDefensivos: puntosDefensivos ?? this.puntosDefensivos,
      notaObjetiva: notaObjetiva ?? this.notaObjetiva,
    );
  }
}
