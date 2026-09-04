import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/lineup_player.dart';
import '../../core/models/match_model.dart';
import '../../core/models/player_stat.dart';
import '../../core/services/firestore_service.dart';
import '../common/app_bottom_nav.dart';

class VerActaScreen extends StatelessWidget {
  const VerActaScreen({super.key, required this.matchId});

  final String matchId;
  static final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return StreamBuilder<MatchModel?>(
      stream: service.matchById(matchId),
      builder: (context, snapshot) {
        final match = snapshot.data;
        if (match == null) {
          return const Scaffold(
            backgroundColor: Color(0xFF07070A),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final stats = [...match.estadisticasJugadores]
          ..sort((a, b) => a.equipo.compareTo(b.equipo));

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream:
              _db
                  .collection('partidos')
                  .doc(matchId)
                  .collection('votos')
                  .snapshots(),
          builder: (context, votesSnap) {
            final voteAverages = _voteAveragesFromFirestore(
              votesSnap.data?.docs ?? const [],
            );

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream:
                  _db
                      .collection('partidos')
                      .doc(matchId)
                      .collection('eventos_live')
                      .snapshots(),
              builder: (context, eventsSnap) {
                final docs = eventsSnap.data?.docs ?? const [];
                final events = _eventsFromFirestore(docs, match);

                return Scaffold(
                  backgroundColor: const Color(0xFF07070A),
                  appBar: AppBar(
                    title: const Text(
                      'Resumen del Partido',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    backgroundColor: const Color(0xFF07070A),
                    foregroundColor: Colors.white,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  bottomNavigationBar: const AppBottomNavBar(selectedIndex: -1),
                  body: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    children: [
                      _buildSummaryHeader(match),
                      const SizedBox(height: 24),
                      _buildSectionTitle('PLANTILLAS'),
                      const SizedBox(height: 10),
                      _buildPlantillasBoard(match, stats),
                      const SizedBox(height: 24),
                      _buildMvpCard(match, stats, voteAverages),
                      const SizedBox(height: 24),
                      _buildSectionTitle('FORMACIÓN INICIAL'),
                      const SizedBox(height: 10),
                      _buildFormationCard(match),
                      const SizedBox(height: 24),
                      _buildSectionTitle('EVENTOS DEL PARTIDO'),
                      const SizedBox(height: 10),
                      _buildEventsTimeline(events),
                      const SizedBox(height: 24),
                      _buildSectionTitle('DESTACADOS'),
                      const SizedBox(height: 10),
                      _buildHighlights(stats),
                      const SizedBox(height: 24),
                      _buildSectionTitle('VALORACIONES DEL DÍA'),
                      const SizedBox(height: 10),
                      _buildRatingsBoard(match, voteAverages),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // SUMMARY HEADER
  // ---------------------------------------------------------------------------

  Widget _buildSummaryHeader(MatchModel match) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.34),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFFCEC7CB), Color(0xFFF1EAF1)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _teamAbbr(match.equipo1),
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.66),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                '${match.goles1} - ${match.goles2}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 66,
                  fontWeight: FontWeight.w900,
                  height: 0.92,
                  letterSpacing: -1.2,
                ),
              ),
            ),
            Expanded(
              child: Text(
                _teamAbbr(match.equipo2),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.black.withValues(alpha: 0.66),
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PLANTILLAS BOARD
  // ---------------------------------------------------------------------------

  Widget _buildPlantillasBoard(MatchModel match, List<PlayerStat> stats) {
    final team1 = _teamLineup(match, 1);
    final team2 = _teamLineup(match, 2);
    final statsById = {for (final s in stats) s.id: s};

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _PlantillaColumn(
            title: match.equipo1.toUpperCase(),
            players: team1,
            statsById: statsById,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PlantillaColumn(
            title: match.equipo2.toUpperCase(),
            players: team2,
            statsById: statsById,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // MVP CARD
  // ---------------------------------------------------------------------------

  Widget _buildMvpCard(
    MatchModel match,
    List<PlayerStat> stats,
    Map<String, double> voteAverages,
  ) {
    final played = stats.where((s) => s.haJugado).toList();
    if (played.isEmpty) return const SizedBox.shrink();

    // Ordenar por la nota media de las votaciones de ESTE partido; en
    // empate, por goles + asistencias (igual que Android).
    final mvp = (played.toList()
          ..sort((a, b) {
            final ratingA = voteAverages[a.id] ?? 0.0;
            final ratingB = voteAverages[b.id] ?? 0.0;
            final byRating = ratingB.compareTo(ratingA);
            if (byRating != 0) return byRating;
            return (b.goles + b.asistencias).compareTo(a.goles + a.asistencias);
          }))
        .first;
    final mvpRating = voteAverages[mvp.id] ?? 0.0;
    if (mvpRating <= 0.0) return const SizedBox.shrink();

    final allPlayers = [
      ...match.alineacionDetallada1,
      ...match.alineacionDetallada2,
    ];
    final mvpLineup = allPlayers.firstWhere(
      (p) => p.id == mvp.id,
      orElse: () => LineupPlayer(id: mvp.id, nombre: mvp.nombre),
    );

    final displayValue = mvpRating.toStringAsFixed(1);

    return Container(
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFB8922A), Color(0xFFE8C96A), Color(0xFFB8922A)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Foto del MVP
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: SizedBox(
              width: 110,
              height: 120,
              child: mvpLineup.fotoUrl.trim().isNotEmpty
                  ? Image.network(
                      mvpLineup.fotoUrl.trim(),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.person, color: Colors.white, size: 50),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.person, color: Colors.white, size: 50),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Textos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'MVP DEL PARTIDO',
                  style: TextStyle(
                    color: Color(0xFF5A3A00),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  mvp.nombre.split(' ').first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 26,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          // Valoración / goles
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: Text(
              displayValue,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 44,
                letterSpacing: -1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // FORMATION CARD
  // ---------------------------------------------------------------------------

  Widget _buildFormationCard(MatchModel match) {
    final team1 = _teamLineup(match, 1);
    final team2 = _teamLineup(match, 2);
    final color1 = _teamColor(match.color1);
    final color2 = _teamColor(match.color2);

    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: const Color(0xFF0D4AAE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _PitchPainter())),
            ..._buildFieldTeam(team1, color1, topTeam: false),
            ..._buildFieldTeam(team2, color2, topTeam: true),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION TITLE
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFFC8AC80),
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
        fontSize: 19,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPERS
  // ---------------------------------------------------------------------------

  String _teamAbbr(String value) {
    final clean = value.trim();
    if (clean.isEmpty) return '---';
    return clean.length <= 3 ? clean.toUpperCase() : clean.substring(0, 3).toUpperCase();
  }

  List<LineupPlayer> _teamLineup(MatchModel match, int team) {
    final source = team == 1 ? match.alineacionDetallada1 : match.alineacionDetallada2;
    if (source.isNotEmpty) return source;

    return match.estadisticasJugadores
        .where((player) => player.equipo == team && player.haJugado)
        .map(
          (player) => LineupPlayer(id: player.id, nombre: player.nombre),
        )
        .toList();
  }

  Color _teamColor(String colorName) {
    switch (colorName) {
      case 'Rojo':
        return const Color(0xFFE53935);
      case 'Azul':
        return const Color(0xFF1E88E5);
      case 'Verde':
        return const Color(0xFF43A047);
      case 'Amarillo':
        return const Color(0xFFFFB300);
      case 'Blanco':
        return Colors.white;
      case 'Negro':
        return Colors.black;
      case 'Morado':
        return const Color(0xFF8E24AA);
      case 'Naranja':
        return const Color(0xFFF4511E);
      default:
        return Colors.grey;
    }
  }

  /// Builds player markers using role-based slots that mirror the Kotlin layout.
  List<Widget> _buildFieldTeam(
    List<LineupPlayer> players,
    Color color,
    {required bool topTeam}
  ) {
    if (players.isEmpty) return const [];

    final goalkeeper = players.firstWhere(
      (player) => player.posicionFutsal == 'POR' || player.ordenPortero == 1,
      orElse: () => players.first,
    );
    final cierre = players.firstWhere(
      (player) => player.posicionFutsal == 'CIE',
      orElse: () => players.length > 1 ? players[1] : goalkeeper,
    );
    final remaining = players
        .where((player) => player.id != goalkeeper.id && player.id != cierre.id)
        .toList();
    final alas = remaining.where((player) => player.posicionFutsal == 'ALA').toList();
    final noAlas = remaining.where((player) => player.posicionFutsal != 'ALA').toList();
    final pivot = players.firstWhere(
      (player) => player.posicionFutsal == 'PIV',
      orElse: () => noAlas.isNotEmpty ? noAlas.last : (remaining.isNotEmpty ? remaining.last : cierre),
    );

    final leftWing = alas.isNotEmpty ? alas.first : (remaining.isNotEmpty ? remaining.first : cierre);
    final rightWing = alas.length > 1 ? alas[1] : (remaining.length > 1 ? remaining[1] : cierre);

    return [
      _buildFieldSlot(
        player: goalkeeper,
        color: color,
        alignment: topTeam ? Alignment.topCenter : Alignment.bottomCenter,
        inset: topTeam ? const EdgeInsets.only(top: 15) : const EdgeInsets.only(bottom: 15),
      ),
      _buildFieldSlot(
        player: cierre,
        color: color,
        alignment: topTeam ? Alignment.topCenter : Alignment.bottomCenter,
        inset: topTeam ? const EdgeInsets.only(top: 90) : const EdgeInsets.only(bottom: 90),
      ),
      _buildFieldSlot(
        player: leftWing,
        color: color,
        alignment: Alignment(-1, topTeam ? -1 : 1),
        inset: topTeam ? const EdgeInsets.only(top: 125, left: 25) : const EdgeInsets.only(bottom: 125, left: 25),
      ),
      _buildFieldSlot(
        player: rightWing,
        color: color,
        alignment: Alignment(1, topTeam ? -1 : 1),
        inset: topTeam ? const EdgeInsets.only(top: 125, right: 25) : const EdgeInsets.only(bottom: 125, right: 25),
      ),
      _buildFieldSlot(
        player: pivot,
        color: color,
        alignment: topTeam ? Alignment.topCenter : Alignment.bottomCenter,
        inset: topTeam ? const EdgeInsets.only(top: 180) : const EdgeInsets.only(bottom: 180),
      ),
    ];
  }

  Widget _buildFieldSlot({
    required LineupPlayer player,
    required Color color,
    required Alignment alignment,
    required EdgeInsets inset,
  }) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: inset,
        child: _PitchPlayerMarker(player: player, background: color),
      ),
    );
  }




  // ---------------------------------------------------------------------------
  // EVENTS TIMELINE
  // ---------------------------------------------------------------------------

  Widget _buildEventsTimeline(List<_MatchEvent> events) {
    if (events.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF16181E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: const Text(
          'Esperando eventos... ¡Que ruede el balón!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101114),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          for (var index = 0; index < events.length; index++)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${events[index].minute}\'',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A3E33),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${events[index].score1} - ${events[index].score2}',
                          style: const TextStyle(
                            color: Color(0xFFC8AC80),
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              events[index].scorerName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            if (events[index].assistName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Asistencia: ${events[index].assistName}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.48),
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.sports_soccer,
                        size: 18,
                        color: events[index].team == 1
                            ? const Color(0xFF1E88E5)
                            : const Color(0xFFE53935),
                      ),
                    ],
                  ),
                ),
                if (index != events.length - 1)
                  Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
              ],
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HIGHLIGHTS
  // ---------------------------------------------------------------------------

  Widget _buildHighlights(List<PlayerStat> stats) {
    final played = stats.where((s) => s.haJugado).toList();
    final topScorer = played.isEmpty
        ? null
        : (played.toList()..sort((a, b) => b.goles.compareTo(a.goles))).first;
    final topAssist = played.isEmpty
        ? null
        : (played.toList()
              ..sort((a, b) => b.asistencias.compareTo(a.asistencias)))
            .first;

    return Row(
      children: [
        Expanded(
          child: _HighlightCard(
            title: 'Bota de Oro',
            name: topScorer?.nombre.split(' ').first ?? '---',
            value: '${topScorer?.goles ?? 0} Goles',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _HighlightCard(
            title: 'Playmaker',
            name: topAssist?.nombre.split(' ').first ?? '---',
            value: '${topAssist?.asistencias ?? 0} Partic.',
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // RATINGS BOARD
  // ---------------------------------------------------------------------------

  Widget _buildRatingsBoard(
    MatchModel match,
    Map<String, double> voteAverages,
  ) {
    final team1 = _teamLineup(match, 1);
    final team2 = _teamLineup(match, 2);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _RatingsColumn(
            title: match.equipo1.toUpperCase(),
            players: team1,
            voteAverages: voteAverages,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RatingsColumn(
            title: match.equipo2.toUpperCase(),
            players: team2,
            voteAverages: voteAverages,
          ),
        ),
      ],
    );
  }

  Map<String, double> _voteAveragesFromFirestore(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final totals = <String, double>{};
    final counts = <String, int>{};
    for (final doc in docs) {
      final rawMap = doc.data()['notas'];
      if (rawMap is! Map) continue;
      rawMap.forEach((key, value) {
        final playerId = key.toString();
        final score = (value as num?)?.toDouble();
        if (score == null) return;
        totals[playerId] = (totals[playerId] ?? 0) + score;
        counts[playerId] = (counts[playerId] ?? 0) + 1;
      });
    }
    return {
      for (final id in totals.keys)
        id: ((totals[id]! / counts[id]!) * 10).round() / 10,
    };
  }

  // ---------------------------------------------------------------------------
  // EVENTS FROM FIRESTORE
  // ---------------------------------------------------------------------------

  List<_MatchEvent> _eventsFromFirestore(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    MatchModel match,
  ) {
    final playersById = <String, LineupPlayer>{
      for (final player in match.alineacionDetallada1) player.id: player,
      for (final player in match.alineacionDetallada2) player.id: player,
      for (final stat in match.estadisticasJugadores)
        stat.id: LineupPlayer(id: stat.id, nombre: stat.nombre),
    };

    final ordered = docs.toList()
      ..sort((a, b) {
        final dataA = a.data();
        final dataB = b.data();
        final minuteA = _parseMinute(dataA['minuto']);
        final minuteB = _parseMinute(dataB['minuto']);
        final byMinute = minuteA.compareTo(minuteB);
        if (byMinute != 0) return byMinute;
        final timestampA = (dataA['timestamp'] as num?)?.toInt() ?? 0;
        final timestampB = (dataB['timestamp'] as num?)?.toInt() ?? 0;
        return timestampA.compareTo(timestampB);
      });

    var score1 = 0;
    var score2 = 0;
    final events = <_MatchEvent>[];

    for (var index = 0; index < ordered.length; index++) {
      final data = ordered[index].data();
      final type = (data['tipo'] as String?) ?? (data['type'] as String?) ?? '';
      if (type.toUpperCase() != 'GOL' && type.toLowerCase() != 'goal') continue;

      final scorerId =
          (data['idGoleador'] as String?) ?? (data['scorerId'] as String?) ?? '';
      final assistId =
          (data['idAsistente'] as String?) ?? (data['assistId'] as String?) ?? '';
      final team =
          ((data['equipo'] as num?) ?? (data['scorerTeam'] as num?))?.toInt() ?? 1;
      final minute = _parseMinute(data['minuto']);
      final scorerName =
          (data['nombreGoleador'] as String?) ??
          (data['scorerName'] as String?) ??
          playersById[scorerId]?.nombre ??
          'Jugador';
      final assistName = assistId.isEmpty
          ? ''
          : ((data['nombreAsistente'] as String?) ??
              (data['assistName'] as String?) ??
              playersById[assistId]?.nombre ??
              '');

      if (team == 1) {
        score1++;
      } else {
        score2++;
      }

      events.add(
        _MatchEvent(
          scorerName: scorerName.split(' ').first,
          assistName: assistName.isEmpty ? '' : assistName.split(' ').first,
          team: team,
          minute: minute,
          order: index,
          score1: score1,
          score2: score2,
        ),
      );
    }

    events.sort((a, b) {
      final byMinute = a.minute.compareTo(b.minute);
      if (byMinute != 0) return byMinute;
      return a.order.compareTo(b.order);
    });

    return events;
  }

  int _parseMinute(dynamic raw) {
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw.replaceAll("'", '').trim()) ?? 0;
    return 0;
  }
}


// =============================================================================
// PITCH PAINTER
// =============================================================================

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final topArc = Rect.fromCenter(
      center: Offset(size.width / 2, -14),
      width: size.width * 0.46,
      height: 110,
    );
    canvas.drawArc(topArc, 0, math.pi, false, line);

    final bottomArc = Rect.fromCenter(
      center: Offset(size.width / 2, size.height + 14),
      width: size.width * 0.46,
      height: 110,
    );
    canvas.drawArc(bottomArc, math.pi, math.pi, false, line);

    final goalPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.35, 0, size.width * 0.30, 8),
      goalPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.35, size.height - 8, size.width * 0.30, 8),
      goalPaint,
    );

    // Barra de color equipo 1 (arriba) — azul
    final team1Paint = Paint()..color = const Color(0xFF1565C0);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 5), team1Paint);

    // Barra de color equipo 2 (abajo) — rojo
    final team2Paint = Paint()..color = const Color(0xFFB71C1C);
    canvas.drawRect(Rect.fromLTWH(0, size.height - 5, size.width, 5), team2Paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =============================================================================
// HIGHLIGHT CARD
// =============================================================================

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({
    required this.title,
    required this.name,
    required this.value,
  });

  final String title;
  final String name;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF16181E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events, color: Color(0xFFC8AC80), size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFC8AC80),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// PITCH PLAYER MARKER
// =============================================================================

class _PitchPlayerMarker extends StatelessWidget {
  const _PitchPlayerMarker({required this.player, required this.background});

  final LineupPlayer player;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final firstName = player.nombre.trim().isEmpty
        ? 'Jugador'
        : player.nombre.trim().split(' ').first;
    final isGoalkeeper =
        player.ordenPortero == 1 || player.posicionFutsal == 'POR';
    final label =
        firstName.length > 10 ? '${firstName.substring(0, 7)}...' : firstName;
    final fallbackLetter =
        firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : '?';
    final textColor = background.computeLuminance() > 0.65 ? Colors.black : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: player.fotoUrl.trim().isNotEmpty
              ? Image.network(
                  player.fotoUrl.trim(),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      isGoalkeeper ? 'P' : fallbackLetter,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w900,
                        fontSize: isGoalkeeper ? 20 : 18,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    isGoalkeeper ? 'P' : fallbackLetter,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w900,
                      fontSize: isGoalkeeper ? 20 : 18,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxWidth: 78),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF112553),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 8.5,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PLANTILLA COLUMN  (nueva — muestra goles y asistencias por jugador)
// =============================================================================

class _PlantillaColumn extends StatelessWidget {
  const _PlantillaColumn({
    required this.title,
    required this.players,
    required this.statsById,
  });

  final String title;
  final List<LineupPlayer> players;
  final Map<String, PlayerStat> statsById;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontWeight: FontWeight.w800,
            fontSize: 17,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        ...players.map((player) {
          final stat = statsById[player.id];
          final goles = stat?.goles ?? 0;
          final asistencias = stat?.asistencias ?? 0;
          final puntosDefensivos = stat?.puntosDefensivos ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    player.nombre.split(' ').first,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (goles > 0) _StatChip(icon: '⚽', value: goles),
                if (asistencias > 0) ...[
                  const SizedBox(width: 4),
                  _StatChip(icon: '👟', value: asistencias),
                ],
                if (puntosDefensivos > 0) ...[
                  const SizedBox(width: 4),
                  _StatChip(
                    icon: '🛡️',
                    value: puntosDefensivos,
                    color: const Color(0xFF2E7D32),
                  ),
                ],
              ],
            ),
          );
        }),
      ],
    );
  }
}

// =============================================================================
// STAT CHIP  (nueva — pastilla de goles / asistencias)
// =============================================================================

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.value,
    this.color = const Color(0xFF2A2A2A),
  });

  final String icon;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(
            '$value',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// RATINGS COLUMN
// =============================================================================

class _RatingsColumn extends StatelessWidget {
  const _RatingsColumn({
    required this.title,
    required this.players,
    required this.voteAverages,
  });

  final String title;
  final List<LineupPlayer> players;
  final Map<String, double> voteAverages;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.62),
            fontWeight: FontWeight.w800,
            fontSize: 18,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        ...players.map((player) {
          final rating = voteAverages[player.id] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    player.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 15.5,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _RatingPill(value: rating),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// =============================================================================
// RATING PILL
// =============================================================================

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.value});

  final double value;

  Color get _background {
    if (value <= 2.0) return const Color(0xFFB71C1C);
    if (value <= 3.0) return const Color(0xFFEF5350);
    if (value <= 3.5) return const Color(0xFFFF9800);
    if (value <= 4.0) return const Color(0xFFFFC107);
    if (value <= 4.5) return const Color(0xFF66BB6A);
    if (value < 5.0) return const Color(0xFF4CAF50);
    return const Color(0xFFEFB04D);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Text(
        value.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: 16,
        ),
      ),
    );
  }
}

// =============================================================================
// MATCH EVENT MODEL
// =============================================================================

class _MatchEvent {
  const _MatchEvent({
    required this.scorerName,
    required this.assistName,
    required this.team,
    required this.minute,
    required this.order,
    required this.score1,
    required this.score2,
  });

  final String scorerName;
  final String assistName;
  final int team;
  final int minute;
  final int order;
  final int score1;
  final int score2;
}