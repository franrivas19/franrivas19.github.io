import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/lineup_player.dart';
import '../models/match_model.dart';
import '../models/player_stat.dart';
import '../utils/date_utils.dart';
import '../utils/gambeta_score_calc.dart';

const String temporadaActual = '26/27';
const String _guestGlobalId = 'invitado_global';

/// Convierte una etiqueta de temporada "26/27" en un id de documento válido
/// para Firestore (que no admite "/"), p. ej. "2026-2027".
String archivedSeasonId(String temporada) {
  final parts = temporada.split('/');
  if (parts.length != 2) {
    return temporada.replaceAll('/', '-');
  }
  int fullYear(String twoDigits) {
    final n = int.tryParse(twoDigits) ?? 0;
    return 2000 + n;
  }

  return '${fullYear(parts[0])}-${fullYear(parts[1])}';
}

class MonthlySummary {
  const MonthlySummary({
    required this.partidos,
    required this.goles,
    this.socioNombre,
  });

  final int partidos;
  final int goles;
  final String? socioNombre;
}

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _db = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get currentUid => _auth.currentUser?.uid ?? '';

  Stream<bool> isAdminStream() {
    final uid = currentUid;
    if (uid.isEmpty) {
      return Stream.value(false);
    }
    return _db.collection('usuarios').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return false;
      }
      return AppUser.fromMap(snap.id, snap.data()!).isAdmin;
    });
  }

  Stream<AppUser?> currentUserProfile() {
    final uid = currentUid;
    if (uid.isEmpty) {
      return Stream.value(null);
    }
    return _db.collection('usuarios').doc(uid).snapshots().map((snap) {
      if (!snap.exists || snap.data() == null) {
        return null;
      }
      return AppUser.fromMap(snap.id, snap.data()!);
    });
  }

  Stream<List<AppUser>> allUsers() {
    return _db
        .collection('usuarios')
        .snapshots()
        .map(
          (query) =>
              query.docs.map((d) => AppUser.fromMap(d.id, d.data())).toList()
                ..sort((a, b) {
                  final byMatches = b.pj.compareTo(a.pj);
                  return byMatches != 0
                      ? byMatches
                      : a.nombre.compareTo(b.nombre);
                }),
        );
  }

  Stream<MatchModel?> nextPendingMatch() {
    return _db
        .collection('partidos')
        .where('estado', whereIn: ['Pendiente', 'En Juego'])
        .snapshots()
        .map((query) {
          if (query.docs.isEmpty) {
            return null;
          }
          final matches =
              query.docs.map((d) => MatchModel.fromMap(d.id, d.data())).toList()
                ..sort((a, b) {
                  final aDate = parseMatchDateTime(a.fecha, a.hora);
                  final bDate = parseMatchDateTime(b.fecha, b.hora);
                  if (aDate != null && bDate != null) {
                    return aDate.compareTo(bDate);
                  }
                  if (aDate != null) return -1;
                  if (bDate != null) return 1;
                  return a.fecha.compareTo(b.fecha);
                });
          return matches.first;
        });
  }

  Stream<MatchModel?> lastFinishedMatch() {
    return _db
        .collection('partidos')
        .where('estado', isEqualTo: 'Finalizado')
        .snapshots()
        .map((query) {
          if (query.docs.isEmpty) {
            return null;
          }
          final docs =
              query.docs.toList()..sort(
                (a, b) => ((b.data()['timestampCierre'] as num?)?.toInt() ?? 0)
                    .compareTo(
                      ((a.data()['timestampCierre'] as num?)?.toInt() ?? 0),
                    ),
              );
          return MatchModel.fromMap(docs.first.id, docs.first.data());
        });
  }

  Stream<List<MatchModel>> allMatchesStream() {
    return _db.collection('partidos').snapshots().map((query) {
      final matches =
          query.docs.map((d) => MatchModel.fromMap(d.id, d.data())).toList();
      matches.sort((a, b) {
        final aDate = parseMatchDateTime(a.fecha, a.hora);
        final bDate = parseMatchDateTime(b.fecha, b.hora);
        if (aDate != null && bDate != null) {
          return aDate.compareTo(bDate);
        }
        if (aDate != null) {
          return -1;
        }
        if (bDate != null) {
          return 1;
        }
        return a.fecha.compareTo(b.fecha);
      });
      return matches;
    });
  }

  Stream<List<MatchModel>> finishedMatchesForUser(String uid) {
    return _db
        .collection('partidos')
        .where('estado', isEqualTo: 'Finalizado')
        .where('temporada', isEqualTo: temporadaActual)
        .snapshots()
        .map((query) {
          final filtered =
              query.docs
                  .map((d) => MatchModel.fromMap(d.id, d.data()))
                  .where(
                    (m) => m.estadisticasJugadores.any(
                      (p) => p.id == uid && p.haJugado,
                    ),
                  )
                  .toList()
                ..sort(
                  (a, b) => b.timestampCierre.compareTo(a.timestampCierre),
                );
          return filtered;
        });
  }

  Stream<List<MatchModel>> contributionMatches({
    required String uid,
    required String type,
  }) {
    final isGoals = type == 'goles';
    return finishedMatchesForUser(uid).map((matches) {
      return matches.where((m) {
        final mine = m.estadisticasJugadores.where((s) => s.id == uid).toList();
        final stat = mine.isEmpty ? null : mine.first;
        if (stat == null) {
          return false;
        }
        return isGoals ? stat.goles > 0 : stat.asistencias > 0;
      }).toList();
    });
  }

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> matchVotesDocs(
    String matchId,
  ) async {
    final snap =
        await _db.collection('partidos').doc(matchId).collection('votos').get();
    return snap.docs;
  }

  Stream<MatchModel?> matchById(String id) {
    return _db.collection('partidos').doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return MatchModel.fromMap(doc.id, doc.data()!);
    });
  }

  Stream<MatchModel?> inGameMatch() {
    return _db
        .collection('partidos')
        .where('estado', isEqualTo: 'En Juego')
        .limit(1)
        .snapshots()
        .map((query) {
          if (query.docs.isEmpty) {
            return null;
          }
          final d = query.docs.first;
          return MatchModel.fromMap(d.id, d.data());
        });
  }

  Stream<List<Map<String, dynamic>>> liveEvents(String matchId) {
    return _db
        .collection('partidos')
        .doc(matchId)
        .collection('eventos_live')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((q) => q.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> addLiveGoal({
    required String matchId,
    required String scorerId,
    required int scorerTeam,
    required int minute,
    required int indiceTurno,
    required int segundosTurno,
    String scorerName = '',
    String? assistId,
    String? assistName,
  }) async {
    final matchRef = _db.collection('partidos').doc(matchId);
    final eventRef =
        _db
            .collection('partidos')
            .doc(matchId)
            .collection('eventos_live')
            .doc();

    final batch = _db.batch();
    batch.set(eventRef, {
      'tipo': 'GOL',
      'idGoleador': scorerId,
      'nombreGoleador': scorerName,
      'equipo': scorerTeam,
      'idAsistente': assistId ?? '',
      'nombreAsistente': assistName ?? '',
      'minuto': minute,
      'indiceTurno': indiceTurno,
      'segundosTurno': segundosTurno,
      'scorerId': scorerId,
      'scorerName': scorerName,
      'scorerTeam': scorerTeam,
      'assistId': assistId,
      'assistName': assistName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'type': 'goal',
    });
    batch.update(matchRef, {
      scorerTeam == 1 ? 'goles1' : 'goles2': FieldValue.increment(1),
    });
    await batch.commit();
  }

  Future<void> createMatch({
    required String equipo1,
    required String color1,
    required String equipo2,
    required String color2,
    required String fecha,
    required String hora,
    required String ubicacion,
  }) {
    final uid = currentUid;
    return _db.collection('partidos').add({
      'equipo1': equipo1,
      'color1': color1,
      'equipo2': equipo2,
      'color2': color2,
      'fecha': fecha,
      'hora': hora,
      'ubicacion': ubicacion,
      'estado': 'Pendiente',
      'goles1': 0,
      'goles2': 0,
      'adminPartido': uid,
      'convocatoria1': <String>[],
      'convocatoria2': <String>[],
      'estadisticasJugadores': <Map<String, dynamic>>[],
      'timestampCierre': 0,
      'hanVotado': <String>[],
      'alineacionDetallada1': <Map<String, dynamic>>[],
      'alineacionDetallada2': <Map<String, dynamic>>[],
      'formacion1': '1-2-1 (Rombo)',
      'formacion2': '1-2-1 (Rombo)',
      'indiceTurno': 0,
      'tiempoSegundos': 360,
      'timestampInicio': 0,
      'invitados': <Map<String, dynamic>>[],
      'temporada': temporadaActual,
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String nombre,
    required String fechaNacimiento,
    required String posicion,
    required String fotoUrl,
  }) async {
    final data = {
      'nombre': nombre,
      'fechaNacimiento': fechaNacimiento,
      'posicion': posicion,
      'fotoUrl': fotoUrl,
    };
    await _db
        .collection('usuarios')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Future<void> saveLineup({
    required String matchId,
    required List<String> convocatoria1,
    required List<String> convocatoria2,
    required String adminPartido,
    required List<GuestPlayer> invitados,
  }) {
    return _db.collection('partidos').doc(matchId).update({
      'convocatoria1': convocatoria1,
      'convocatoria2': convocatoria2,
      'adminPartido': adminPartido,
      'invitados': invitados.map((e) => e.toMap()).toList(),
    });
  }

  Future<void> startMatch({
    required String matchId,
    required String adminPartido,
    required List<LineupPlayer> alineacion1,
    required List<LineupPlayer> alineacion2,
    required String formacion1,
    required String formacion2,
  }) {
    final adminFinal = adminPartido.isEmpty ? currentUid : adminPartido;
    return _db.collection('partidos').doc(matchId).update({
      'estado': 'En Juego',
      'adminPartido': adminFinal,
      'alineacionDetallada1': alineacion1.map((p) => p.toMap()).toList(),
      'alineacionDetallada2': alineacion2.map((p) => p.toMap()).toList(),
      'formacion1': formacion1,
      'formacion2': formacion2,
      'indiceTurno': 0,
      'tiempoSegundos': 360,
      'timestampInicio': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateTurnState({
    required String matchId,
    required int indiceTurno,
    required int tiempoSegundos,
  }) {
    return _db.collection('partidos').doc(matchId).update({
      'indiceTurno': indiceTurno,
      'tiempoSegundos': tiempoSegundos,
    });
  }

  Future<void> closeActa({
    required String matchId,
    required int goles1,
    required int goles2,
    required List<PlayerStat> stats,
  }) async {
    final matchSnap = await _db.collection('partidos').doc(matchId).get();
    final match = MatchModel.fromMap(matchSnap.id, matchSnap.data() ?? {});

    final puntosDefensivos = await _calcularPuntosDefensivos(
      matchId: matchId,
      raw1: match.alineacionDetallada1,
      raw2: match.alineacionDetallada2,
      indiceTurno: match.indiceTurno,
    );

    final played =
        stats.where((s) => s.haJugado).map((s) {
          final esLocal = s.equipo == 1;
          return s.copyWith(
            puntosDefensivos: puntosDefensivos[s.id] ?? 0,
            notaObjetiva: calcularNotaObjetiva(
              goles: s.goles,
              asistencias: s.asistencias,
              posicionFutsal: s.posicion,
              golesEquipo: esLocal ? goles1 : goles2,
              golesRival: esLocal ? goles2 : goles1,
            ),
          );
        }).toList();

    final batch = _db.batch();
    final partidoRef = _db.collection('partidos').doc(matchId);

    batch.update(partidoRef, {
      'estado': 'Finalizado',
      'goles1': goles1,
      'goles2': goles2,
      'timestampCierre': DateTime.now().millisecondsSinceEpoch,
      'estadisticasJugadores': played.map((e) => e.toMap()).toList(),
    });

    for (final s in played) {
      final docId = s.esInvitado ? _guestGlobalId : s.id;
      final userRef = _db.collection('usuarios').doc(docId);
      final incrementos = {
        'pj': FieldValue.increment(1),
        'goles': FieldValue.increment(s.goles),
        'asistencias': FieldValue.increment(s.asistencias),
        'puntosDefensivos': FieldValue.increment(s.puntosDefensivos),
      };
      if (s.esInvitado) {
        batch.set(userRef, {
          ...incrementos,
          'nombre': 'Invitados Globales',
        }, SetOptions(merge: true));
      } else {
        batch.update(userRef, incrementos);
      }
    }

    await batch.commit();
  }

  Future<Map<String, int>> _calcularPuntosDefensivos({
    required String matchId,
    required List<LineupPlayer> raw1,
    required List<LineupPlayer> raw2,
    required int indiceTurno,
  }) async {
    final golesSnap =
        await _db
            .collection('partidos')
            .doc(matchId)
            .collection('eventos_live')
            .where('tipo', isEqualTo: 'GOL')
            .get();
    final goles = golesSnap.docs.map((d) => d.data()).toList();

    List<LineupPlayer> porteros(List<LineupPlayer> raw) {
      final conOrden =
          raw.where((p) => p.ordenPortero > 0).toList()
            ..sort((a, b) => a.ordenPortero.compareTo(b.ordenPortero));
      return conOrden.isEmpty ? raw : conOrden;
    }

    final porteros1 = porteros(raw1);
    final porteros2 = porteros(raw2);
    final acumulador = <String, int>{};

    for (var t = 0; t <= indiceTurno; t++) {
      final segundosConcedidosEq1 =
          goles
              .where(
                (g) =>
                    ((g['indiceTurno'] as num?)?.toInt() ?? 0) == t &&
                    ((g['equipo'] as num?)?.toInt() ?? 0) == 2,
              )
              .map((g) => (g['segundosTurno'] as num?)?.toInt() ?? 0)
              .toList();
      final segundosConcedidosEq2 =
          goles
              .where(
                (g) =>
                    ((g['indiceTurno'] as num?)?.toInt() ?? 0) == t &&
                    ((g['equipo'] as num?)?.toInt() ?? 0) == 1,
              )
              .map((g) => (g['segundosTurno'] as num?)?.toInt() ?? 0)
              .toList();

      final puntosEq1 = _puntosDefensivosTurno(segundosConcedidosEq1);
      final puntosEq2 = _puntosDefensivosTurno(segundosConcedidosEq2);

      final idPortero1 =
          porteros1.isNotEmpty ? porteros1[t % porteros1.length].id : null;
      final idPortero2 =
          porteros2.isNotEmpty ? porteros2[t % porteros2.length].id : null;

      for (final jug in raw1) {
        if (jug.id == idPortero1) continue;
        acumulador[jug.id] = (acumulador[jug.id] ?? 0) + puntosEq1;
      }
      for (final jug in raw2) {
        if (jug.id == idPortero2) continue;
        acumulador[jug.id] = (acumulador[jug.id] ?? 0) + puntosEq2;
      }
    }

    return acumulador;
  }

  int _puntosDefensivosTurno(List<int> golesSegundos) {
    final ordenados = [...golesSegundos]..sort();
    var puntos = 0;
    var ultimo = 0;
    for (final segundo in ordenados) {
      puntos += (segundo - ultimo) ~/ 30;
      ultimo = segundo;
    }
    puntos += (360 - ultimo) ~/ 30;
    final penalizacion =
        golesSegundos.length >= 2 ? golesSegundos.length - 1 : 0;
    return puntos - penalizacion;
  }

  Future<void> reassignPlayerTeam({
    required String matchId,
    required String jugadorId,
    required int nuevoEquipo,
  }) async {
    final partidoRef = _db.collection('partidos').doc(matchId);
    final eventosRef = partidoRef.collection('eventos_live');
    final batch = _db.batch();

    if (nuevoEquipo == 1) {
      batch.update(partidoRef, {
        'convocatoria1': FieldValue.arrayUnion([jugadorId]),
        'convocatoria2': FieldValue.arrayRemove([jugadorId]),
      });
    } else {
      batch.update(partidoRef, {
        'convocatoria1': FieldValue.arrayRemove([jugadorId]),
        'convocatoria2': FieldValue.arrayUnion([jugadorId]),
      });
    }

    final golesJugador =
        await eventosRef.where('idGoleador', isEqualTo: jugadorId).get();
    for (final doc in golesJugador.docs) {
      batch.update(doc.reference, {'equipo': nuevoEquipo});
    }
    final asistenciasJugador =
        await eventosRef.where('idAsistente', isEqualTo: jugadorId).get();
    for (final doc in asistenciasJugador.docs) {
      batch.update(doc.reference, {'equipo': nuevoEquipo});
    }

    await batch.commit();
  }

  Future<void> submitRatings({
    required MatchModel match,
    required Map<String, double> ratings,
    required String voterUid,
  }) async {
    final partidoRef = _db.collection('partidos').doc(match.id);
    final voterDocRef = partidoRef.collection('votos').doc(voterUid);

    final existingVote = await voterDocRef.get();
    if (existingVote.exists) {
      throw Exception('Este usuario ya ha votado este partido.');
    }

    // Los invitados no tienen documento propio en `usuarios`: sus votos se
    // redirigen y acumulan en el documento global `invitado_global`, igual
    // que hace la app Android.
    final aggregated = <String, List<double>>{};
    ratings.forEach((playerId, rating) {
      final targetId =
          playerId.startsWith('invitado_') ? _guestGlobalId : playerId;
      aggregated.putIfAbsent(targetId, () => []).add(rating);
    });

    final batch = _db.batch();

    batch.update(partidoRef, {
      'hanVotado': FieldValue.arrayUnion([voterUid]),
    });

    batch.set(voterDocRef, {
      'usuarioId': voterUid,
      'partidoId': match.id,
      'notas': ratings,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    for (final entry in aggregated.entries) {
      final userRef = _db.collection('usuarios').doc(entry.key);
      final snap = await userRef.get();
      final prevStars = (snap.data()?['totalEstrellas'] as num?)?.toDouble() ?? 0;
      final prevVotes = (snap.data()?['votosRecibidos'] as num?)?.toInt() ?? 0;
      final addedStars = entry.value.fold<double>(0, (a, b) => a + b);
      final addedVotes = entry.value.length;
      final newStars = prevStars + addedStars;
      final newVotes = prevVotes + addedVotes;
      final avg = ((newStars / newVotes) * 10).round() / 10;

      batch.set(userRef, {
        'totalEstrellas': newStars,
        'votosRecibidos': newVotes,
        'valoracion': avg,
        if (entry.key == _guestGlobalId) 'nombre': 'Invitados Globales',
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<int> totalFinishedMatches() async {
    final query =
        await _db
            .collection('partidos')
            .where('estado', isEqualTo: 'Finalizado')
            .get();
    return query.size;
  }

  Future<MonthlySummary> monthlySummary(String uid) async {
    if (uid.isEmpty) {
      return const MonthlySummary(partidos: 0, goles: 0);
    }
    final now = DateTime.now();
    final matches = await finishedMatchesForUser(uid).first;
    final delMes =
        matches.where((m) {
          final dt = DateTime.fromMillisecondsSinceEpoch(m.timestampCierre);
          return dt.year == now.year && dt.month == now.month;
        }).toList();

    var goles = 0;
    final coincidencias = <String, int>{};
    final nombres = <String, String>{};

    for (final m in delMes) {
      final propios = m.estadisticasJugadores.where((s) => s.id == uid);
      if (propios.isEmpty) {
        continue;
      }
      final propio = propios.first;
      goles += propio.goles;
      for (final s in m.estadisticasJugadores) {
        if (s.id == uid || s.equipo != propio.equipo) {
          continue;
        }
        coincidencias[s.id] = (coincidencias[s.id] ?? 0) + 1;
        nombres[s.id] = s.nombre;
      }
    }

    String? socio;
    if (coincidencias.isNotEmpty) {
      final topId =
          coincidencias.entries
              .reduce((a, b) => a.value >= b.value ? a : b)
              .key;
      socio = nombres[topId];
    }

    return MonthlySummary(
      partidos: delMes.length,
      goles: goles,
      socioNombre: socio,
    );
  }

  Future<Map<String, Map<String, dynamic>>> pastSeasons(String uid) async {
    final snap =
        await _db
            .collection('usuarios')
            .doc(uid)
            .collection('temporadas_pasadas')
            .get();
    return {for (final d in snap.docs) d.id: d.data()};
  }

  /// Archiva las estadísticas de todos los jugadores en
  /// `usuarios/{uid}/temporadas_pasadas/{temporada}` y resetea los
  /// contadores en vivo a 0, dando paso a una nueva temporada.
  Future<void> resetSeason() async {
    final seasonId = archivedSeasonId(temporadaActual);
    final totalPartidos = await totalFinishedMatches();
    final snapshot = await _db.collection('usuarios').get();

    const chunkSize = 200; // 2 escrituras/usuario, bajo el límite de 500 por batch
    for (var i = 0; i < snapshot.docs.length; i += chunkSize) {
      final chunk = snapshot.docs.skip(i).take(chunkSize);
      final batch = _db.batch();

      for (final doc in chunk) {
        final data = doc.data();
        final historicoRef = doc.reference
            .collection('temporadas_pasadas')
            .doc(seasonId);

        batch.set(historicoRef, {
          'pj': data['pj'] ?? 0,
          'goles': data['goles'] ?? 0,
          'asistencias': data['asistencias'] ?? 0,
          'valoracion': data['valoracion'] ?? 0.0,
          'puntosDefensivos': data['puntosDefensivos'] ?? 0,
          'listaTitulos': data['titulos_2026'] ?? <String>[],
          'totalPartidosPenaAnual': totalPartidos,
        });

        batch.update(doc.reference, {
          'pj': 0,
          'goles': 0,
          'asistencias': 0,
          'valoracion': 0.0,
          'puntosDefensivos': 0,
          'totalEstrellas': 0.0,
          'votosRecibidos': 0,
        });
      }

      await batch.commit();
    }
  }
}
