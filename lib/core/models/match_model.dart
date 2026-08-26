import 'lineup_player.dart';
import 'player_stat.dart';

class GuestPlayer {
  const GuestPlayer({required this.id, required this.nombre});

  final String id;
  final String nombre;

  factory GuestPlayer.fromMap(Map<String, dynamic> data) {
    return GuestPlayer(
      id: (data['id'] as String?) ?? '',
      nombre: (data['nombre'] as String?) ?? 'Invitado',
    );
  }

  Map<String, dynamic> toMap() => {'id': id, 'nombre': nombre};
}

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
    required this.alineacionDetallada1,
    required this.alineacionDetallada2,
    required this.formacion1,
    required this.formacion2,
    required this.indiceTurno,
    required this.tiempoSegundos,
    required this.timestampInicio,
    required this.invitados,
    required this.temporada,
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
  final List<LineupPlayer> alineacionDetallada1;
  final List<LineupPlayer> alineacionDetallada2;
  final String formacion1;
  final String formacion2;
  final int indiceTurno;
  final int tiempoSegundos;
  final int timestampInicio;
  final List<GuestPlayer> invitados;
  final String temporada;

  factory MatchModel.fromMap(String id, Map<String, dynamic> data) {
    final rawStats =
        (data['estadisticasJugadores'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PlayerStat.fromMap)
            .toList();
    final rawLineup1 =
        (data['alineacionDetallada1'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(LineupPlayer.fromMap)
            .toList();
    final rawLineup2 =
        (data['alineacionDetallada2'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(LineupPlayer.fromMap)
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
      convocatoria1:
          (data['convocatoria1'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toList(),
      convocatoria2:
          (data['convocatoria2'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toList(),
      adminPartido: (data['adminPartido'] as String?) ?? '',
      timestampCierre: (data['timestampCierre'] as num?)?.toInt() ?? 0,
      estadisticasJugadores: rawStats,
      hanVotado:
          (data['hanVotado'] as List<dynamic>? ?? [])
              .whereType<String>()
              .toList(),
      alineacionDetallada1: rawLineup1,
      alineacionDetallada2: rawLineup2,
      formacion1: (data['formacion1'] as String?) ?? '1-2-1 (Rombo)',
      formacion2: (data['formacion2'] as String?) ?? '1-2-1 (Rombo)',
      indiceTurno: (data['indiceTurno'] as num?)?.toInt() ?? 0,
      tiempoSegundos: (data['tiempoSegundos'] as num?)?.toInt() ?? 360,
      timestampInicio: (data['timestampInicio'] as num?)?.toInt() ?? 0,
      invitados:
          (data['invitados'] as List<dynamic>? ?? [])
              .whereType<Map<String, dynamic>>()
              .map(GuestPlayer.fromMap)
              .toList(),
      temporada: (data['temporada'] as String?) ?? '',
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
      'estadisticasJugadores':
          estadisticasJugadores.map((e) => e.toMap()).toList(),
      'hanVotado': hanVotado,
      'alineacionDetallada1':
          alineacionDetallada1.map((e) => e.toMap()).toList(),
      'alineacionDetallada2':
          alineacionDetallada2.map((e) => e.toMap()).toList(),
      'formacion1': formacion1,
      'formacion2': formacion2,
      'indiceTurno': indiceTurno,
      'tiempoSegundos': tiempoSegundos,
      'timestampInicio': timestampInicio,
      'invitados': invitados.map((e) => e.toMap()).toList(),
      'temporada': temporada,
    };
  }

  factory MatchModel.fromFirestore(Map<String, dynamic> data) {
    return MatchModel.fromMap(data['id'] as String, data);
  }
}
