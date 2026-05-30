class LineupPlayer {
  const LineupPlayer({
    required this.id,
    required this.nombre,
    this.posicionFutsal = 'ALA',
    this.ordenPortero = 0,
    this.fotoUrl = '',
  });

  final String id;
  final String nombre;
  final String posicionFutsal;
  final int ordenPortero;
  final String fotoUrl;

  factory LineupPlayer.fromMap(Map<String, dynamic> data) {
    return LineupPlayer(
      id: (data['id'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? 'Jugador',
      posicionFutsal: (data['posicionFutsal'] as String?) ?? 'ALA',
      ordenPortero: (data['ordenPortero'] as num?)?.toInt() ?? 0,
      fotoUrl: (data['fotoUrl'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'posicionFutsal': posicionFutsal,
      'ordenPortero': ordenPortero,
      'fotoUrl': fotoUrl,
    };
  }

  LineupPlayer copyWith({String? posicionFutsal, int? ordenPortero}) {
    return LineupPlayer(
      id: id,
      nombre: nombre,
      posicionFutsal: posicionFutsal ?? this.posicionFutsal,
      ordenPortero: ordenPortero ?? this.ordenPortero,
      fotoUrl: fotoUrl,
    );
  }
}
