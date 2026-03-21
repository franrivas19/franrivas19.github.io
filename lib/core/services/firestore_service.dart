import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_user.dart';
import '../models/match_model.dart';
import '../models/player_stat.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get currentUid => _auth.currentUser?.uid ?? '';

  bool get isMainAdmin =>
      (_auth.currentUser?.email ?? '') == 'josemanuelrivasfernandez96@gmail.com';

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
        .where('estado', isEqualTo: 'Pendiente')
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

  Stream<MatchModel?> matchById(String id) {
    return _db.collection('partidos').doc(id).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      return MatchModel.fromMap(doc.id, doc.data()!);
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
    final batch = _db.batch();
    final partidoRef = _db.collection('partidos').doc(matchId);
    final played = stats.where((s) => s.haJugado).toList();

    batch.update(partidoRef, {
      'estado': 'Finalizado',
      'goles1': goles1,
      'goles2': goles2,
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
    batch.update(partidoRef, {
      'hanVotado': FieldValue.arrayUnion([voterUid]),
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
