import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/match_model.dart';
import '../../core/models/player_stat.dart';
import '../../core/services/firestore_service.dart';

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

        final stats = [...match.estadisticasJugadores]..sort((a, b) => a.equipo.compareTo(b.equipo));

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _db
              .collection('partidos')
              .doc(matchId)
              .collection('eventos_live')
              .snapshots(),
          builder: (context, eventsSnap) {
            final docs = eventsSnap.data?.docs ?? const [];
            final events = _eventsFromFirestore(docs, stats);

            return Scaffold(
              backgroundColor: const Color(0xFF07070A),
              appBar: AppBar(
                title: const Text('Resumen del Partido', style: TextStyle(fontWeight: FontWeight.w800)),
                backgroundColor: const Color(0xFF07070A),
                foregroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => context.pop(),
                ),
              ),
              bottomNavigationBar: _buildBottomNav(context),
              body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 118),
                children: [
                  _buildSummaryHeader(match),
                  const SizedBox(height: 24),
                  _buildSectionTitle('FORMACION INICIAL'),
                  const SizedBox(height: 10),
                  _buildPitchCard(match, stats, team: 1),
                  const SizedBox(height: 16),
                  _buildPitchCard(match, stats, team: 2),
                  const SizedBox(height: 24),
                  _buildSectionTitle('EVENTOS DEL PARTIDO'),
                  const SizedBox(height: 10),
                  _buildEventsTimeline(events),
                  const SizedBox(height: 24),
                  _buildSectionTitle('DESTACADOS'),
                  const SizedBox(height: 10),
                  _buildHighlights(stats),
                  const SizedBox(height: 24),
                  _buildSectionTitle('VALORACIONES DEL DIA'),
                  const SizedBox(height: 10),
                  _buildRatingsBoard(match, stats),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryHeader(MatchModel match) {
    final team1Color = _shieldColor(match.color1);
    final team2Color = _shieldColor(match.color2);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 10,
      shadowColor: Colors.black.withValues(alpha: 0.34),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Color(0xFF222227), Color(0xFF07070A)],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFC8AC80).withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'FINALIZADO',
                style: TextStyle(color: Color(0xFFC8AC80), fontWeight: FontWeight.w900, letterSpacing: 0.3),
              ),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Expanded(
                      child: _TeamScoreBlock(name: match.equipo1, color: team1Color),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.42),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${match.goles1} - ${match.goles2}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 58,
                            height: 0.9,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _TeamScoreBlock(name: match.equipo2, color: team2Color),
                    ),
                  ],
                );
              },
            ),
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

  Widget _buildPitchCard(MatchModel match, List<PlayerStat> stats, {required int team}) {
    final players = stats.where((s) => s.haJugado && s.equipo == team).toList();
    final color = team == 1 ? _shieldColor(match.color1) : _shieldColor(match.color2);

    return Container(
      height: 355,
      decoration: BoxDecoration(
        color: const Color(0xFF1A6B21),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            CustomPaint(size: const Size(double.infinity, double.infinity), painter: _PitchPainter()),
            ..._buildPlayerMarkers(players, color),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPlayerMarkers(List<PlayerStat> players, Color color) {
    if (players.isEmpty) {
      return [
        Center(
          child: Text(
            'Sin jugadores',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontWeight: FontWeight.w700),
          ),
        ),
      ];
    }

    final positions = _markerPositions(players.length);
    final widgets = <Widget>[];
    for (var i = 0; i < players.length; i++) {
      widgets.add(
        Align(
          alignment: positions[i],
          child: _PlayerMarker(player: players[i], color: color),
        ),
      );
    }
    return widgets;
  }

  List<Alignment> _markerPositions(int count) {
    switch (count) {
      case 1:
        return const [Alignment(0, 0.0)];
      case 2:
        return const [Alignment(-0.35, 0.0), Alignment(0.35, 0.0)];
      case 3:
        return const [
          Alignment(0, -0.46),
          Alignment(-0.44, 0.08),
          Alignment(0.44, 0.08),
        ];
      case 4:
        return const [
          Alignment(0, -0.58),
          Alignment(-0.48, -0.14),
          Alignment(0.48, -0.14),
          Alignment(0, 0.40),
        ];
      case 5:
        return const [
          Alignment(0, -0.64),
          Alignment(-0.55, -0.22),
          Alignment(0.55, -0.22),
          Alignment(0, 0.12),
          Alignment(0, 0.52),
        ];
      case 6:
        return const [
          Alignment(-0.55, -0.34),
          Alignment(0, -0.34),
          Alignment(0.55, -0.34),
          Alignment(-0.55, 0.28),
          Alignment(0, 0.28),
          Alignment(0.55, 0.28),
        ];
      default:
        final generated = <Alignment>[];
        final columns = 3;
        for (var i = 0; i < count; i++) {
          final row = i ~/ columns;
          final col = i % columns;
          final x = -0.62 + (col * 0.62);
          final y = -0.60 + (row * 0.34);
          generated.add(Alignment(x.clamp(-0.75, 0.75), y.clamp(-0.70, 0.72)));
        }
        return generated;
    }
  }

  Widget _buildEventsTimeline(List<_MatchEvent> events) {
    final source = events.isEmpty
      ? [const _MatchEvent(playerName: 'Sin eventos', minute: 0, order: 0)]
      : events;
    return Column(
      children: source.map((event) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 42,
                child: Text(
                  event.minute == 0 ? '-' : '${event.minute}\'',
                  style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    Container(width: 2, height: 22, color: Colors.white30),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  event.playerName == 'Sin eventos' ? event.playerName : '⚽  Gol de ${event.playerName}',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.88), fontSize: 15.5, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHighlights(List<PlayerStat> stats) {
    final played = stats.where((s) => s.haJugado).toList();
    final topScorer = played.isEmpty ? null : (played.toList()..sort((a, b) => b.goles.compareTo(a.goles))).first;
    final topAssist = played.isEmpty ? null : (played.toList()..sort((a, b) => b.asistencias.compareTo(a.asistencias))).first;

    return Row(
      children: [
        Expanded(
          child: _HighlightCard(
            title: 'Bota de Oro',
            name: topScorer?.nombre ?? '---',
            value: '${topScorer?.goles ?? 0} Goles',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _HighlightCard(
            title: 'Playmaker',
            name: topAssist?.nombre ?? '---',
            value: '${topAssist?.asistencias ?? 0} Partic.',
          ),
        ),
      ],
    );
  }

  Widget _buildRatingsBoard(MatchModel match, List<PlayerStat> stats) {
    final team1 = stats.where((s) => s.equipo == 1 && s.haJugado).toList();
    final team2 = stats.where((s) => s.equipo == 2 && s.haJugado).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _RatingsColumn(title: match.equipo1.toUpperCase(), players: team1)),
        const SizedBox(width: 12),
        Expanded(child: _RatingsColumn(title: match.equipo2.toUpperCase(), players: team2)),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      color: const Color(0xFFE8E2EE),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 22),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: _BottomMenuItem(
                icon: Icons.person,
                label: 'Mi Perfil',
                onTap: () => context.go('/editar-perfil'),
              ),
            ),
            Expanded(
              child: _BottomMenuItem(
                icon: Icons.groups,
                label: 'Plantilla',
                onTap: () => context.go('/plantilla'),
              ),
            ),
            Expanded(
              child: _BottomMenuItem(
                icon: Icons.star,
                label: 'Turnos',
                onTap: () => context.go('/timer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _shieldColor(String colorName) {
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
        return const Color(0xFFF2F2F2);
      case 'Negro':
        return const Color(0xFF121212);
      default:
        return const Color(0xFF8E24AA);
    }
  }

  List<_MatchEvent> _eventsFromFirestore(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    List<PlayerStat> stats,
  ) {
    final namesById = <String, String>{for (final s in stats) s.id: s.nombre};

    final events = docs.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value.data();
      final idGoleador = data['idGoleador'] as String?;
      final nombreData = data['nombreGoleador'] as String?;
      final minute = _parseMinute(data['minuto']);

      final name = (idGoleador != null ? namesById[idGoleador] : null) ??
          nombreData ??
          (idGoleador ?? 'Jugador');

      return _MatchEvent(
        playerName: name.split(' ').first,
        minute: minute,
        order: index,
      );
    }).toList();

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

class _TeamScoreBlock extends StatelessWidget {
  const _TeamScoreBlock({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ShieldIcon(color: color, size: 88),
        const SizedBox(height: 8),
        Text(
          name.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ],
    );
  }
}

class _ShieldIcon extends StatelessWidget {
  const _ShieldIcon({required this.color, this.size = 64});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _ShieldPainter(color: color));
  }
}

class _ShieldPainter extends CustomPainter {
  _ShieldPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * 0.18, size.height * 0.12)
      ..lineTo(size.width * 0.82, size.height * 0.12)
      ..quadraticBezierTo(size.width * 0.96, size.height * 0.12, size.width * 0.94, size.height * 0.28)
      ..lineTo(size.width * 0.94, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.92, size.height * 0.88, size.width * 0.50, size.height * 0.98)
      ..quadraticBezierTo(size.width * 0.08, size.height * 0.88, size.width * 0.06, size.height * 0.58)
      ..lineTo(size.width * 0.06, size.height * 0.28)
      ..quadraticBezierTo(size.width * 0.04, size.height * 0.12, size.width * 0.18, size.height * 0.12)
      ..close();

    final fill = Paint()..color = color;
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..color = const Color(0xFFC8AC80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.03;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _ShieldPainter oldDelegate) => oldDelegate.color != color;
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final topArc = Rect.fromCenter(center: Offset(size.width / 2, -14), width: size.width * 0.46, height: 110);
    canvas.drawArc(topArc, 0, math.pi, false, line);

    final bottomArc = Rect.fromCenter(center: Offset(size.width / 2, size.height + 14), width: size.width * 0.46, height: 110);
    canvas.drawArc(bottomArc, math.pi, math.pi, false, line);

    final goalPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.35, 0, size.width * 0.30, 8), goalPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.35, size.height - 8, size.width * 0.30, 8), goalPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PlayerMarker extends StatelessWidget {
  const _PlayerMarker({required this.player, required this.color});

  final PlayerStat player;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final initial = player.nombre.isNotEmpty ? player.nombre[0].toUpperCase() : '?';

    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.72), width: 2),
          ),
          child: Text(
            initial,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxWidth: 78),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.66),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            player.nombre.split(' ').first,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 7.5),
          ),
        ),
      ],
    );
  }
}

class _HighlightCard extends StatelessWidget {
  const _HighlightCard({required this.title, required this.name, required this.value});

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
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Color(0xFFC8AC80), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _RatingsColumn extends StatelessWidget {
  const _RatingsColumn({required this.title, required this.players});

  final String title;
  final List<PlayerStat> players;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.62), fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 0.4),
        ),
        const SizedBox(height: 10),
        ...players.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(color: const Color(0xFF16181E), borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(p.nombre, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5)),
                        const SizedBox(height: 6),
                        Text('${p.goles} G  •  ${p.asistencias} A', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                      ],
                    ),
                  ),
                  Text('-', style: TextStyle(color: Colors.white.withValues(alpha: 0.66), fontSize: 22, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BottomMenuItem extends StatelessWidget {
  const _BottomMenuItem({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF3F3A4C), size: 29),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(color: Color(0xFF3F3A4C), fontWeight: FontWeight.w500, fontSize: 17)),
          ],
        ),
      ),
    );
  }
}

class _MatchEvent {
  const _MatchEvent({required this.playerName, required this.minute, required this.order});

  final String playerName;
  final int minute;
  final int order;
}
