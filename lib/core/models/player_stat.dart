class PlayerStat {
  PlayerStat({
    required this.id,
    required this.nombre,
    required this.goles,
    required this.asistencias,
    required this.equipo,
    required this.haJugado,
  });

  final String id;
  final String nombre;
  final int goles;
  final int asistencias;
  final int equipo;
  final bool haJugado;

  factory PlayerStat.fromMap(Map<String, dynamic> data) {
    return PlayerStat(
      id: (data['id'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? 'Jugador',
      goles: (data['goles'] as num?)?.toInt() ?? 0,
      asistencias: (data['asistencias'] as num?)?.toInt() ?? 0,
      equipo: (data['equipo'] as num?)?.toInt() ?? 1,
      haJugado: (data['haJugado'] as bool?) ?? true,
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
    };
  }

  PlayerStat copyWith({
    int? goles,
    int? asistencias,
    bool? haJugado,
    int? equipo,
  }) {
    return PlayerStat(
      id: id,
      nombre: nombre,
      goles: goles ?? this.goles,
      asistencias: asistencias ?? this.asistencias,
      haJugado: haJugado ?? this.haJugado,
      equipo: equipo ?? this.equipo,
    );
  }
}
