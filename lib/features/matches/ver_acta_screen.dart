import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_user.dart';
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

        return StreamBuilder<List<AppUser>>(
          stream: service.allUsers(),
          builder: (context, usersSnap) {
            final usersById = {
              for (final user in usersSnap.data ?? const <AppUser>[]) user.id: user,
            };

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
                  bottomNavigationBar: const AppBottomNavBar(selectedIndex: 2),
                  body: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                    children: [
                      _buildSummaryHeader(match),
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
                      _buildRatingsBoard(match, usersById, stats),
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

  Widget _buildFormationCard(MatchModel match) {
    final team1 = _teamLineup(match, 1);
    final team2 = _teamLineup(match, 2);

    return Container(
      height: 600,
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
            ..._buildPitchPlayers(team1, topTeam: true),
            ..._buildPitchPlayers(team2, topTeam: false),
          ],
        ),
      ),
    );
  }

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

  String _teamAbbr(String value) {
    final clean = value.trim();
    if (clean.isEmpty) {
      return '---';
    }
    return clean.length <= 3 ? clean.toUpperCase() : clean.substring(0, 3).toUpperCase();
  }

  List<LineupPlayer> _teamLineup(MatchModel match, int team) {
    final source = team == 1 ? match.alineacionDetallada1 : match.alineacionDetallada2;
    if (source.isNotEmpty) {
      return source;
    }

    return match.estadisticasJugadores
        .where((player) => player.equipo == team && player.haJugado)
        .map(
          (player) => LineupPlayer(
            id: player.id,
            nombre: player.nombre,
          ),
        )
        .toList();
  }

  List<Widget> _buildPitchPlayers(List<LineupPlayer> players, {required bool topTeam}) {
    if (players.isEmpty) {
      return const [];
    }

    final positions = _pitchPositions(players.length, topTeam: topTeam);
    return [
      for (var index = 0; index < players.length; index++)
        Align(
          alignment: positions[index],
          child: _PitchPlayerMarker(
            player: players[index],
            topTeam: topTeam,
          ),
        ),
    ];
  }

  List<Alignment> _pitchPositions(int count, {required bool topTeam}) {
    final topPositions = <int, List<Alignment>>{
      1: [const Alignment(0, -0.72)],
      2: [const Alignment(-0.38, -0.60), const Alignment(0.38, -0.60)],
      3: [
        const Alignment(0, -0.76),
        const Alignment(-0.56, -0.38),
        const Alignment(0.56, -0.38),
      ],
      4: [
        const Alignment(0, -0.82),
        const Alignment(-0.60, -0.48),
        const Alignment(0.60, -0.48),
        const Alignment(0, -0.10),
      ],
      5: [
        const Alignment(0, -0.84),
        const Alignment(0, -0.46),
        const Alignment(-0.72, -0.10),
        const Alignment(0.72, -0.10),
        const Alignment(0, 0.28),
      ],
      6: [
        const Alignment(-0.58, -0.58),
        const Alignment(0, -0.62),
        const Alignment(0.58, -0.58),
        const Alignment(-0.58, -0.16),
        const Alignment(0, -0.16),
        const Alignment(0.58, -0.16),
      ],
    };
    final bottomPositions = <int, List<Alignment>>{
      1: [const Alignment(0, 0.72)],
      2: [const Alignment(-0.38, 0.60), const Alignment(0.38, 0.60)],
      3: [
        const Alignment(0, 0.76),
        const Alignment(-0.56, 0.38),
        const Alignment(0.56, 0.38),
      ],
      4: [
        const Alignment(0, 0.82),
        const Alignment(-0.60, 0.48),
        const Alignment(0.60, 0.48),
        const Alignment(0, 0.10),
      ],
      5: [
        const Alignment(0, 0.84),
        const Alignment(0, 0.46),
        const Alignment(-0.72, 0.10),
        const Alignment(0.72, 0.10),
        const Alignment(0, -0.28),
      ],
      6: [
        const Alignment(-0.58, 0.58),
        const Alignment(0, 0.62),
        const Alignment(0.58, 0.58),
        const Alignment(-0.58, 0.16),
        const Alignment(0, 0.16),
        const Alignment(0.58, 0.16),
      ],
    };

    final positions = topTeam ? topPositions[count] : bottomPositions[count];
    if (positions != null) {
      return positions;
    }
    return List.generate(count, (index) {
      final row = index ~/ 3;
      final col = index % 3;
      final x = -0.62 + (col * 0.62);
      final baseY = topTeam ? -0.62 + (row * 0.26) : 0.62 - (row * 0.26);
      return Alignment(x.clamp(-0.75, 0.75), baseY.clamp(-0.70, 0.70));
    });
  }

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
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
          ),
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

  Widget _buildHighlights(List<PlayerStat> stats) {
    final played = stats.where((s) => s.haJugado).toList();
    final topScorer =
        played.isEmpty
            ? null
            : (played.toList()..sort((a, b) => b.goles.compareTo(a.goles)))
                .first;
    final topAssist =
        played.isEmpty
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

  Widget _buildRatingsBoard(
    MatchModel match,
    Map<String, AppUser> usersById,
    List<PlayerStat> stats,
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
            usersById: usersById,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _RatingsColumn(
            title: match.equipo2.toUpperCase(),
            players: team2,
            usersById: usersById,
          ),
        ),
      ],
    );
  }

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
        if (byMinute != 0) {
          return byMinute;
        }
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
      if (type.toUpperCase() != 'GOL' && type.toLowerCase() != 'goal') {
        continue;
      }

      final scorerId =
          (data['idGoleador'] as String?) ??
          (data['scorerId'] as String?) ??
          '';
      final assistId =
          (data['idAsistente'] as String?) ??
          (data['assistId'] as String?) ??
          '';
      final team =
          ((data['equipo'] as num?) ?? (data['scorerTeam'] as num?))?.toInt() ??
          1;
      final minute = _parseMinute(data['minuto']);
      final scorerName =
          (data['nombreGoleador'] as String?) ??
          (data['scorerName'] as String?) ??
          playersById[scorerId]?.nombre ??
          'Jugador';
      final assistName =
          assistId.isEmpty
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
      if (byMinute != 0) {
        return byMinute;
      }
      return a.order.compareTo(b.order);
    });

    return events;
  }

  int _parseMinute(dynamic raw) {
    if (raw is num) {
      return raw.toInt();
    }
    if (raw is String) {
      return int.tryParse(raw.replaceAll("'", '').trim()) ?? 0;
    }
    return 0;
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line =
        Paint()
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
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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

class _PitchPlayerMarker extends StatelessWidget {
  const _PitchPlayerMarker({required this.player, required this.topTeam});

  final LineupPlayer player;
  final bool topTeam;

  @override
  Widget build(BuildContext context) {
    final firstName = player.nombre.split(' ').first;
    final isGoalkeeper = player.ordenPortero == 1 || player.posicionFutsal == 'POR';
    final label = firstName.length > 10 ? '${firstName.substring(0, 7)}...' : firstName;
    final fallbackLetter = firstName.isNotEmpty ? firstName.substring(0, 1).toUpperCase() : '?';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: topTeam ? const Color(0xFFEFEFEF) : const Color(0xFFF6F1EA),
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
          child:
              player.fotoUrl.trim().isNotEmpty
                  ? Image.network(
                    player.fotoUrl.trim(),
                    fit: BoxFit.cover,
                    errorBuilder:
                        (context, error, stackTrace) => Center(
                          child: Text(
                            isGoalkeeper ? 'P' : fallbackLetter,
                            style: TextStyle(
                              color: Colors.black87,
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
                        color: Colors.black87,
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

class _RatingsColumn extends StatelessWidget {
  const _RatingsColumn({
    required this.title,
    required this.players,
    required this.usersById,
  });

  final String title;
  final List<LineupPlayer> players;
  final Map<String, AppUser> usersById;

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
          final user = usersById[player.id];
          final rating = user?.valoracion ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    user?.nombre ?? player.nombre,
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

class _RatingPill extends StatelessWidget {
  const _RatingPill({required this.value});

  final double value;

  Color get _background {
    if (value >= 4.2) {
      return const Color(0xFF63C05A);
    }
    if (value >= 3.7) {
      return const Color(0xFFF5BE1A);
    }
    if (value >= 3.2) {
      return const Color(0xFFFF9B1A);
    }
    return const Color(0xFFEF5A5A);
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
