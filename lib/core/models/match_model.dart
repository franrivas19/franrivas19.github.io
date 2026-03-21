import 'player_stat.dart';

class MatchModel {
  MatchModel({
    required this.id,
    required this.equipo1,
    required this.equipo2,
    required this.color1,
    required this.color2,
    required this.fecha,
    required this.hora,
    required this.ubicacion,
    required this.estado,
    required this.goles1,
    required this.goles2,
    required this.convocatoria1,
    required this.convocatoria2,
    required this.adminPartido,
    required this.timestampCierre,
    required this.estadisticasJugadores,
    required this.hanVotado,
  });

  final String id;
  final String equipo1;
  final String equipo2;
  final String color1;
  final String color2;
  final String fecha;
  final String hora;
  final String ubicacion;
  final String estado;
  final int goles1;
  final int goles2;
  final List<String> convocatoria1;
  final List<String> convocatoria2;
  final String adminPartido;
  final int timestampCierre;
  final List<PlayerStat> estadisticasJugadores;
  final List<String> hanVotado;

  factory MatchModel.fromMap(String id, Map<String, dynamic> data) {
    final rawStats = (data['estadisticasJugadores'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(PlayerStat.fromMap)
        .toList();

    return MatchModel(
      id: id,
      equipo1: (data['equipo1'] as String?) ?? 'Local',
      equipo2: (data['equipo2'] as String?) ?? 'Visitante',
      color1: (data['color1'] as String?) ?? 'Blanco',
      color2: (data['color2'] as String?) ?? 'Negro',
      fecha: (data['fecha'] as String?) ?? '',
      hora: (data['hora'] as String?) ?? '',
      ubicacion: (data['ubicacion'] as String?) ?? '',
      estado: (data['estado'] as String?) ?? 'Pendiente',
      goles1: (data['goles1'] as num?)?.toInt() ?? 0,
      goles2: (data['goles2'] as num?)?.toInt() ?? 0,
      convocatoria1: (data['convocatoria1'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      convocatoria2: (data['convocatoria2'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      adminPartido: (data['adminPartido'] as String?) ?? '',
      timestampCierre: (data['timestampCierre'] as num?)?.toInt() ?? 0,
      estadisticasJugadores: rawStats,
      hanVotado: (data['hanVotado'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'equipo1': equipo1,
      'equipo2': equipo2,
      'color1': color1,
      'color2': color2,
      'fecha': fecha,
      'hora': hora,
      'ubicacion': ubicacion,
      'estado': estado,
      'goles1': goles1,
      'goles2': goles2,
      'convocatoria1': convocatoria1,
      'convocatoria2': convocatoria2,
      'adminPartido': adminPartido,
      'timestampCierre': timestampCierre,
      'estadisticasJugadores': estadisticasJugadores.map((e) => e.toMap()).toList(),
      'hanVotado': hanVotado,
    };
  }
}
