import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/lineup_player.dart';
import '../../core/models/match_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bottom_nav.dart';

class LiveScoreScreen extends StatefulWidget {
  const LiveScoreScreen({super.key, required this.matchId});

  final String matchId;

  @override
  State<LiveScoreScreen> createState() => _LiveScoreScreenState();
}

class _LiveScoreScreenState extends State<LiveScoreScreen> {
  final _service = FirestoreService();
  int? _lastGoalCount;
  String _goalOverlayName = '';
  Timer? _overlayTimer;

  @override
  void dispose() {
    _overlayTimer?.cancel();
    super.dispose();
  }

  void _maybeShowGoalOverlay(List<_LiveGoalEvent> events) {
    final currentCount = events.length;
    final previous = _lastGoalCount;
    if (previous != null && currentCount > previous && events.isNotEmpty) {
      final latest = [...events]
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      HapticFeedback.vibrate();
      setState(() => _goalOverlayName = latest.last.scorerName.toUpperCase());
      _overlayTimer?.cancel();
      _overlayTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _goalOverlayName = '');
        }
      });
    }
    _lastGoalCount = currentCount;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MatchModel?>(
      stream: _service.matchById(widget.matchId),
      builder: (context, matchSnap) {
        final match = matchSnap.data;
        if (match == null) {
          return const Scaffold(
            backgroundColor: Color(0xFFF5F5F7),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return StreamBuilder<List<Map<String, dynamic>>>(
          stream: _service.liveEvents(match.id),
          builder: (context, eventsSnap) {
            final events = _parseEvents(eventsSnap.data ?? const [], match);
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => _maybeShowGoalOverlay(events),
            );

            return Scaffold(
              backgroundColor: const Color(0xFFF5F5F7),
              appBar: AppBar(
                title: const Text(
                  'LIVE SCORE',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                leading: IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              bottomNavigationBar: const AppBottomNavBar(selectedIndex: -1),
              body: Stack(
                children: [
                  ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _ScoreCard(match: match),
                      const SizedBox(height: 20),
                      const _SectionLabel('🧤 PORTEROS ACTUALES'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _GoalkeeperCard(
                              title: match.equipo1,
                              current: _currentGoalkeeper(
                                match.alineacionDetallada1,
                                match.indiceTurno,
                              ),
                              dark: true,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _GoalkeeperCard(
                              title: match.equipo2,
                              current: _currentGoalkeeper(
                                match.alineacionDetallada2,
                                match.indiceTurno,
                              ),
                              dark: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const _SectionLabel('⏱️ CRONOLOGÍA'),
                      const SizedBox(height: 8),
                      _TimelineCard(events: events),
                    ],
                  ),
                  _GoalOverlay(name: _goalOverlayName),
                ],
              ),
            );
          },
        );
      },
    );
  }

  LineupPlayer? _currentGoalkeeper(List<LineupPlayer> lineup, int turnIndex) {
    final goalkeepers =
        lineup.where((p) => p.ordenPortero > 0).toList()
          ..sort((a, b) => a.ordenPortero.compareTo(b.ordenPortero));
    final source = goalkeepers.isEmpty ? lineup : goalkeepers;
    if (source.isEmpty) {
      return null;
    }
    return source[turnIndex % source.length];
  }

  List<_LiveGoalEvent> _parseEvents(
    List<Map<String, dynamic>> raw,
    MatchModel match,
  ) {
    final names = <String, String>{
      for (final p in [
        ...match.alineacionDetallada1,
        ...match.alineacionDetallada2,
      ])
        p.id: p.nombre,
    };

    final events =
        raw.where((e) => e['tipo'] == 'GOL' || e['type'] == 'goal').map((e) {
            final scorerId =
                (e['idGoleador'] as String?) ??
                (e['scorerId'] as String?) ??
                '';
            final assistId =
                (e['idAsistente'] as String?) ??
                (e['assistId'] as String?) ??
                '';
            final scorerName =
                names[scorerId] ??
                (e['nombreGoleador'] as String?) ??
                (e['scorerName'] as String?) ??
                'Jugador';
            final assistName =
                assistId.isEmpty
                    ? ''
                    : (names[assistId] ??
                        (e['nombreAsistente'] as String?) ??
                        (e['assistName'] as String?) ??
                        '');

            return _LiveGoalEvent(
              minute: _intValue(e['minuto']),
              team: _intValue(e['equipo'] ?? e['scorerTeam'], fallback: 1),
              scorerName: scorerName,
              assistName: assistName,
              timestamp: _intValue(e['timestamp']),
            );
          }).toList()
          ..sort((a, b) {
            final byMinute = a.minute.compareTo(b.minute);
            return byMinute != 0
                ? byMinute
                : a.timestamp.compareTo(b.timestamp);
          });
    return events;
  }

  int _intValue(dynamic value, {int fallback = 0}) {
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.replaceAll("'", '').trim()) ?? fallback;
    }
    return fallback;
  }
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    final live = match.estado == 'En Juego';
    return Card(
      color: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _TeamName(match.equipo1)),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2A679),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${match.goles1} - ${match.goles2}',
                    style: const TextStyle(
                      fontFamily: AppTheme.oswald,
                      color: Colors.black,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(child: _TeamName(match.equipo2)),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                live ? '🔴 EN DIRECTO' : 'PARTIDO FINALIZADO',
                style: const TextStyle(
                  color: Color(0xFF43A047),
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamName extends StatelessWidget {
  const _TeamName(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text(
      _abbr(name),
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 24,
      ),
    );
  }

  String _abbr(String value) {
    final clean = value.trim();
    return clean.length <= 3
        ? clean.toUpperCase()
        : clean.substring(0, 3).toUpperCase();
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      ),
    );
  }
}

class _GoalkeeperCard extends StatelessWidget {
  const _GoalkeeperCard({
    required this.title,
    required this.current,
    required this.dark,
  });

  final String title;
  final LineupPlayer? current;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final background = dark ? const Color(0xFF1A1A1A) : Colors.white;
    final foreground = dark ? Colors.white : Colors.black87;
    return Card(
      color: background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: dark ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.58),
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              current?.nombre ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard({required this.events});

  final List<_LiveGoalEvent> events;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child:
            events.isEmpty
                ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: Text(
                    'Esperando eventos... ¡Que ruede el balón!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                : Column(
                  children:
                      events.map((event) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 38,
                                child: Text(
                                  event.minute > 0 ? "${event.minute}'" : '-',
                                  style: const TextStyle(
                                    color: Color(0xFFC2A679),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.sports_soccer,
                                color:
                                    event.team == 1
                                        ? const Color(0xFF1E88E5)
                                        : const Color(0xFFE53935),
                                size: 18,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'GOL DE ${event.scorerName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (event.assistName.isNotEmpty)
                                      Text(
                                        'Asistencia: ${event.assistName}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                event.team == 1 ? 'Local' : 'Visitante',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                ),
      ),
    );
  }
}

class _GoalOverlay extends StatelessWidget {
  const _GoalOverlay({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: name.isEmpty ? 0 : 1,
        duration: const Duration(milliseconds: 260),
        child: Container(
          color: Colors.black.withValues(alpha: 0.86),
          alignment: Alignment.center,
          child: AnimatedScale(
            scale: name.isEmpty ? 0.86 : 1,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '¡GOOOOL!',
                  style: TextStyle(
                    fontFamily: AppTheme.oswald,
                    color: Color(0xFFC2A679),
                    fontSize: 64,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                const Icon(Icons.sports_soccer, color: Colors.white, size: 44),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveGoalEvent {
  const _LiveGoalEvent({
    required this.minute,
    required this.team,
    required this.scorerName,
    required this.assistName,
    required this.timestamp,
  });

  final int minute;
  final int team;
  final String scorerName;
  final String assistName;
  final int timestamp;
}
