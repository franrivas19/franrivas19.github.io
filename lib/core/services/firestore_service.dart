import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/match_model.dart';
import '../models/player_stat.dart';
import '../utils/date_utils.dart';

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
      return (snap.data()!['rol'] as String?) == 'admin';
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
    return _db.collection('usuarios').snapshots().map(
          (query) => query.docs
              .map((d) => AppUser.fromMap(d.id, d.data()))
              .toList()
            ..sort((a, b) => a.nombre.compareTo(b.nombre)),
        );
  }

  Stream<MatchModel?> nextPendingMatch() {
    return _db
        .collection('partidos')
        .where('estado', whereIn: ['Pendiente', 'En Juego'])
        .orderBy('fecha')
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

  Stream<MatchModel?> lastFinishedMatch() {
    return _db
        .collection('partidos')
        .where('estado', isEqualTo: 'Finalizado')
        .snapshots()
        .map((query) {
      if (query.docs.isEmpty) {
        return null;
      }
      final docs = query.docs.toList()
        ..sort(
          (a, b) => ((b.data()['timestampCierre'] as num?)?.toInt() ?? 0)
              .compareTo(((a.data()['timestampCierre'] as num?)?.toInt() ?? 0),),
        );
      return MatchModel.fromMap(docs.first.id, docs.first.data());
    });
  }

  Stream<List<MatchModel>> allMatchesStream() {
    return _db.collection('partidos').snapshots().map((query) {
      final matches = query.docs
          .map((d) => MatchModel.fromMap(d.id, d.data()))
          .toList();
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
        .snapshots()
        .map((query) {
      final filtered = query.docs
          .map((d) => MatchModel.fromMap(d.id, d.data()))
          .where((m) => m.estadisticasJugadores.any((p) => p.id == uid && p.haJugado))
          .toList()
        ..sort((a, b) => b.timestampCierre.compareTo(a.timestampCierre));
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

  Future<List<QueryDocumentSnapshot<Map<String, dynamic>>>> matchVotesDocs(String matchId) async {
    final snap = await _db.collection('partidos').doc(matchId).collection('votos').get();
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
        .map((q) => q.docs
            .map((d) => {
                  'id': d.id,
                  ...d.data(),
                })
            .toList());
  }

  Future<void> addLiveEvent({
    required String matchId,
    required String scorerId,
    required String scorerName,
    required int scorerTeam,
    String? assistId,
    String? assistName,
  }) async {
    final eventRef = _db
        .collection('partidos')
        .doc(matchId)
        .collection('eventos_live')
        .doc();

    await eventRef.set({
      'scorerId': scorerId,
      'scorerName': scorerName,
      'scorerTeam': scorerTeam,
      'assistId': assistId,
      'assistName': assistName,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'type': 'goal',
    });
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
    });
  }

  Future<void> updateProfile({
    required String uid,
    required String nombre,
    required String correo,
    required String fechaNacimiento,
    required String posicion,
    required String fotoUrl,
  }) async {
    final data = {
      'nombre': nombre,
      'correo': correo,
      'fechaNacimiento': fechaNacimiento,
      'posicion': posicion,
      'fotoUrl': fotoUrl,
    };
    await _db.collection('usuarios').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> saveLineup({
    required String matchId,
    required List<String> convocatoria1,
    required List<String> convocatoria2,
    required String adminPartido,
  }) {
    return _db.collection('partidos').doc(matchId).update({
      'convocatoria1': convocatoria1,
      'convocatoria2': convocatoria2,
      'adminPartido': adminPartido,
    });
  }

  Future<void> closeActa({
    required String matchId,
    required int goles1,
    required int goles2,
    required List<PlayerStat> stats,
  }) async {
    final events = await _db
        .collection('partidos')
        .doc(matchId)
        .collection('eventos_live')
        .get();

    final goalsMap = <String, int>{};
    final assistsMap = <String, int>{};
    var autoGoals1 = 0;
    var autoGoals2 = 0;

    for (final e in events.docs) {
      final data = e.data();
      if (data['type'] != 'goal') {
        continue;
      }
      final scorerId = data['scorerId'] as String?;
      final assistId = data['assistId'] as String?;
      final team = (data['scorerTeam'] as num?)?.toInt() ?? 1;
      if (scorerId != null && scorerId.isNotEmpty) {
        goalsMap[scorerId] = (goalsMap[scorerId] ?? 0) + 1;
      }
      if (assistId != null && assistId.isNotEmpty) {
        assistsMap[assistId] = (assistsMap[assistId] ?? 0) + 1;
      }
      if (team == 1) {
        autoGoals1++;
      } else {
        autoGoals2++;
      }
    }

    final batch = _db.batch();
    final partidoRef = _db.collection('partidos').doc(matchId);
    final enrichedStats = stats
        .map((s) => s.copyWith(
              goles: s.goles + (goalsMap[s.id] ?? 0),
              asistencias: s.asistencias + (assistsMap[s.id] ?? 0),
            ))
        .toList();
    final played = enrichedStats.where((s) => s.haJugado).toList();
    final finalGoles1 = goalsMap.isNotEmpty ? autoGoals1 : goles1;
    final finalGoles2 = goalsMap.isNotEmpty ? autoGoals2 : goles2;

    batch.update(partidoRef, {
      'estado': 'Finalizado',
      'goles1': finalGoles1,
      'goles2': finalGoles2,
      'timestampCierre': DateTime.now().millisecondsSinceEpoch,
      'estadisticasJugadores': played.map((e) => e.toMap()).toList(),
    });

    for (final s in played) {
      final userRef = _db.collection('usuarios').doc(s.id);
      batch.update(userRef, {
        'pj': FieldValue.increment(1),
        'goles': FieldValue.increment(s.goles),
        'asistencias': FieldValue.increment(s.asistencias),
      });
    }

    await batch.commit();
  }

  Future<void> submitRatings({
    required MatchModel match,
    required Map<String, double> ratings,
    required String voterUid,
  }) async {
    final users = await _db.collection('usuarios').get();
    final batch = _db.batch();

    final partidoRef = _db.collection('partidos').doc(match.id);
    final voterDocRef = partidoRef.collection('votos').doc(voterUid);

    final existingVote = await voterDocRef.get();
    if (existingVote.exists) {
      throw Exception('Este usuario ya ha votado este partido.');
    }

    batch.update(partidoRef, {
      'hanVotado': FieldValue.arrayUnion([voterUid]),
    });

    batch.set(voterDocRef, {
      'usuarioId': voterUid,
      'partidoId': match.id,
      'notas': ratings,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });

    for (final doc in users.docs) {
      final uid = doc.id;
      final rating = ratings[uid];
      if (rating == null) {
        continue;
      }

      final prevStars = (doc.data()['totalEstrellas'] as num?)?.toDouble() ?? 0;
      final prevVotes = (doc.data()['votosRecibidos'] as num?)?.toInt() ?? 0;
      final newStars = prevStars + rating;
      final newVotes = prevVotes + 1;
      final avg = ((newStars / newVotes) * 10).round() / 10;

      batch.update(doc.reference, {
        'totalEstrellas': newStars,
        'votosRecibidos': newVotes,
        'valoracion': avg,
      });
    }

    await batch.commit();
  }

  Future<int> totalFinishedMatches() async {
    final query = await _db
        .collection('partidos')
        .where('estado', isEqualTo: 'Finalizado')
        .get();
    return query.size;
  }
}
