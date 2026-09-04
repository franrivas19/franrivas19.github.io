import 'package:flutter/material.dart';

import '../../core/models/match_model.dart';
import '../../core/services/firestore_service.dart';
import '../common/app_bottom_nav.dart';

class MisValoracionesScreen extends StatelessWidget {
  const MisValoracionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    final uid = service.currentUid;

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        foregroundColor: Colors.white,
        title: const Text('MIS VALORACIONES'),
      ),
      bottomNavigationBar: const AppBottomNavBar(selectedIndex: -1),
      body: StreamBuilder<List<MatchModel>>(
        stream: service.finishedMatchesForUser(uid),
        builder: (context, snapshot) {
          final matches = snapshot.data ?? const <MatchModel>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFC2A679)),
            );
          }
          if (matches.isEmpty) {
            return const Center(
              child: Text(
                'Aún no tienes partidos finalizados.',
                style: TextStyle(color: Colors.white70),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.9,
            ),
            itemCount: matches.length,
            itemBuilder: (context, i) {
              final match = matches[i];
              return FutureBuilder<_RatingCardData>(
                future: _buildCardData(service, match, uid),
                builder: (context, dataSnap) {
                  final data = dataSnap.data;
                  final isMvp = data?.isMvp ?? false;
                  final score = data?.myAverage ?? 0;

                  return Container(
                    decoration: BoxDecoration(
                      gradient: isMvp
                          ? const LinearGradient(
                              colors: [Color(0xFFD6BC8D), Color(0xFFC2A679)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isMvp ? null : const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isMvp ? const Color(0xFFF4E2B8) : const Color(0xFF2A2A2A),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.fecha,
                            style: TextStyle(
                              color: isMvp ? const Color(0xFF111111) : Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${match.equipo1} ${match.goles1}-${match.goles2} ${match.equipo2}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: isMvp ? const Color(0xFF111111) : Colors.white,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            score.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: isMvp ? const Color(0xFF111111) : const Color(0xFFC2A679),
                            ),
                          ),
                          Text(
                            isMvp ? 'MVP DEL PARTIDO' : 'Rendimiento',
                            style: TextStyle(
                              color: isMvp ? const Color(0xFF111111) : Colors.white70,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<_RatingCardData> _buildCardData(
    FirestoreService service,
    MatchModel match,
    String uid,
  ) async {
    final votes = await service.matchVotesDocs(match.id);
    final totals = <String, double>{};
    final counts = <String, int>{};

    for (final doc in votes) {
      final data = doc.data();
      final rawMap = data['notas'];
      if (rawMap is! Map) {
        continue;
      }
      rawMap.forEach((key, value) {
        final playerId = key.toString();
        final score = (value as num?)?.toDouble();
        if (score == null) {
          return;
        }
        totals[playerId] = (totals[playerId] ?? 0) + score;
        counts[playerId] = (counts[playerId] ?? 0) + 1;
      });
    }

    double averageFor(String playerId) {
      final avg = (totals[playerId] ?? 0) / (counts[playerId] ?? 1);
      return (avg * 10).round() / 10;
    }

    double mvpRankFor(String playerId, double avg) {
      final filtered = match.estadisticasJugadores.where((s) => s.id == playerId).toList();
      final stat = filtered.isEmpty ? null : filtered.first;
      final goles = stat?.goles ?? 0;
      final asistencias = stat?.asistencias ?? 0;
      return avg + (0.001 * (goles + asistencias));
    }

    var maxRank = double.negativeInfinity;
    var maxAvg = 0.0;
    var maxPlayerId = '';
    for (final p in match.estadisticasJugadores) {
      if (!p.haJugado) {
        continue;
      }
      final avg = averageFor(p.id);
      final rank = mvpRankFor(p.id, avg);
      if (rank > maxRank) {
        maxRank = rank;
        maxAvg = avg;
        maxPlayerId = p.id;
      }
    }

    return _RatingCardData(
      myAverage: averageFor(uid),
      isMvp: uid == maxPlayerId && maxAvg > 0.0,
    );
  }
}

class _RatingCardData {
  const _RatingCardData({required this.myAverage, required this.isMvp});

  final double myAverage;
  final bool isMvp;
}
