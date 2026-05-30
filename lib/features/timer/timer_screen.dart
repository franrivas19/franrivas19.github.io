import 'dart:math' as math;
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../../core/models/lineup_player.dart';
import '../../core/models/match_model.dart';
import '../../core/services/firestore_service.dart';
import '../common/app_bottom_nav.dart';

enum FutsalFormation {
  rombo('1-2-1 (Rombo)'),
  cuadrado('2-2 (Cuadrado)'),
  yGriega('1-1-2 (Y)');

  const FutsalFormation(this.label);

  final String label;

  static FutsalFormation fromLabel(String label) {
    return FutsalFormation.values.firstWhere(
      (f) => f.label == label,
      orElse: () => FutsalFormation.rombo,
    );
  }
}

class TimerTurnosScreen extends StatefulWidget {
  const TimerTurnosScreen({super.key});

  @override
  State<TimerTurnosScreen> createState() => _TimerTurnosScreenState();
}

class _TimerTurnosScreenState extends State<TimerTurnosScreen> {
  static const int _turnDuration = 360;
  static const Color _gold = Color(0xFFC2A679);
  static const Color _dark = Color(0xFF1A1A1A);
  static const Color _softGreen = Color(0xFFD5E5B5);
  static const Color _danger = Color(0xFFE53935);

  final _service = FirestoreService();

  Timer? _timer;
  String? _configuredMatchId;
  List<LineupPlayer> _lineup1 = [];
  List<LineupPlayer> _lineup2 = [];
  FutsalFormation _formation1 = FutsalFormation.rombo;
  FutsalFormation _formation2 = FutsalFormation.rombo;
  int _turnIndex = 0;
  int _seconds = _turnDuration;
  int _changeCountdown = -1;
  bool _active = false;
  bool _starting = false;
  bool _savingGoal = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncFromMatch(MatchModel match, List<AppUser> users) {
    if (_configuredMatchId == match.id) {
      return;
    }

    final byId = {for (final user in users) user.id: user};
    final fallback1 =
        match.convocatoria1
            .where((id) => byId.containsKey(id))
            .map((id) => _lineupFromUser(byId[id]!))
            .toList();
    final fallback2 =
        match.convocatoria2
            .where((id) => byId.containsKey(id))
            .map((id) => _lineupFromUser(byId[id]!))
            .toList();

    _configuredMatchId = match.id;
    _lineup1 =
        match.alineacionDetallada1.isNotEmpty
            ? match.alineacionDetallada1
            : fallback1;
    _lineup2 =
        match.alineacionDetallada2.isNotEmpty
            ? match.alineacionDetallada2
            : fallback2;
    _formation1 = FutsalFormation.fromLabel(match.formacion1);
    _formation2 = FutsalFormation.fromLabel(match.formacion2);
    _turnIndex = match.indiceTurno;
    _seconds = match.tiempoSegundos;
    _active = match.estado == 'En Juego' && match.tiempoSegundos > 0;
    _ensureTimer();
  }

  LineupPlayer _lineupFromUser(AppUser user) {
    return LineupPlayer(
      id: user.id,
      nombre: user.nombre.split(' ').first,
      fotoUrl: user.fotoUrl,
    );
  }

  void _ensureTimer() {
    _timer?.cancel();
    if (!_active) {
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (!_active || _seconds <= 0) {
        timer.cancel();
        return;
      }
      setState(() {
        _seconds--;
        if (_seconds == 0) {
          _active = false;
          _changeCountdown = 15;
        }
      });
    });
  }

  Future<void> _startMatch(MatchModel match) async {
    if (_lineup1.isEmpty || _lineup2.isEmpty) {
      _showMessage('Configura la convocatoria antes de iniciar.');
      return;
    }

    setState(() => _starting = true);
    try {
      await _service.startMatch(
        matchId: match.id,
        adminPartido: match.adminPartido,
        alineacion1: _lineup1,
        alineacion2: _lineup2,
        formacion1: _formation1.label,
        formacion2: _formation2.label,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _turnIndex = 0;
        _seconds = _turnDuration;
        _active = true;
      });
      _ensureTimer();
    } catch (e) {
      _showMessage('Error al iniciar: $e');
    } finally {
      if (mounted) {
        setState(() => _starting = false);
      }
    }
  }

  Future<void> _nextTurn(MatchModel match) async {
    final nextIndex = _turnIndex + 1;
    setState(() {
      _turnIndex = nextIndex;
      _seconds = _turnDuration;
      _changeCountdown = -1;
      _active = true;
    });
    _ensureTimer();
    await _service.updateTurnState(
      matchId: match.id,
      indiceTurno: nextIndex,
      tiempoSegundos: _turnDuration,
    );
  }

  void _toggleTimer() {
    setState(() => _active = !_active);
    _ensureTimer();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _service.currentUserProfile(),
      builder: (context, userSnap) {
        final currentUser = userSnap.data;

        return StreamBuilder<MatchModel?>(
          stream: _service.nextPendingMatch(),
          builder: (context, matchSnap) {
            final match = matchSnap.data;
            if (matchSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFF5F5F7),
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (match == null) {
              return Scaffold(
                backgroundColor: const Color(0xFFF5F5F7),
                body: const _NoMatchState(),
                bottomNavigationBar: const AppBottomNavBar(selectedIndex: 2),
              );
            }

            return StreamBuilder<List<AppUser>>(
              stream: _service.allUsers(),
              builder: (context, usersSnap) {
                final users = usersSnap.data ?? const <AppUser>[];
                _syncFromMatch(match, users);

                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final canManage =
                    currentUser?.rol == 'admin' ||
                    match.adminPartido.isEmpty ||
                    match.adminPartido == uid;

                return Scaffold(
                  backgroundColor: const Color(0xFFF5F5F7),
                  appBar: AppBar(
                    title: const Text(
                      'TURNOS',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  body:
                      match.estado == 'En Juego'
                          ? _buildPlaying(match, canManage)
                          : _buildConfigure(match, canManage),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildConfigure(MatchModel match, bool canManage) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 106),
          children: [
            _MatchHeader(match: match),
            const SizedBox(height: 16),
            _GoalkeeperList(
              title: match.equipo1,
              players: _lineup1,
              editable: canManage,
              onChanged: (players) => setState(() => _lineup1 = players),
            ),
            const SizedBox(height: 14),
            _GoalkeeperList(
              title: match.equipo2,
              players: _lineup2,
              editable: canManage,
              onChanged: (players) => setState(() => _lineup2 = players),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('PIZARRA TACTICA'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _FormationSelector(
                    label: 'E1',
                    value: _formation1,
                    enabled: canManage,
                    onChanged: (value) => setState(() => _formation1 = value),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FormationSelector(
                    label: 'E2',
                    value: _formation2,
                    enabled: canManage,
                    onChanged: (value) => setState(() => _formation2 = value),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _TacticalPitch(
              team1: _lineup1,
              team2: _lineup2,
              formation1: _formation1,
              formation2: _formation2,
              editable: canManage,
              onSwapTeam1:
                  (a, b) =>
                      setState(() => _lineup1 = _swapPlayers(_lineup1, a, b)),
              onSwapTeam2:
                  (a, b) =>
                      setState(() => _lineup2 = _swapPlayers(_lineup2, a, b)),
            ),
          ],
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            minimum: const EdgeInsets.all(16),
            child:
                canManage
                    ? FilledButton(
                      onPressed: _starting ? null : () => _startMatch(match),
                      style: FilledButton.styleFrom(
                        backgroundColor: _danger,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child:
                          _starting
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : const Text('COMENZAR PARTIDO'),
                    )
                    : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: const Text(
                        'Esperando a que el admin inicie el partido.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaying(MatchModel match, bool canManage) {
    final goalkeeper1 = _goalkeeperForTurn(_lineup1, _turnIndex);
    final goalkeeper2 = _goalkeeperForTurn(_lineup2, _turnIndex);
    final next1 = _goalkeeperForTurn(_lineup1, _turnIndex + 1);
    final next2 = _goalkeeperForTurn(_lineup2, _turnIndex + 1);

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _service.liveEvents(match.id),
      builder: (context, eventsSnap) {
        final counts = _liveCounts(eventsSnap.data ?? const []);
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            _InfoBar(seconds: _seconds),
            const SizedBox(height: 14),
            _LiveScoreCard(match: match),
            const SizedBox(height: 16),
            _TimerCard(
              seconds: _seconds,
              active: _active,
              canManage: canManage,
              onTap:
                  canManage
                      ? _toggleTimer
                      : () => _showMessage(
                        'Solo el administrador puede pausar el reloj.',
                      ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _KeeperCard(
                    title: 'PORTERO ${match.equipo1}',
                    current: goalkeeper1?.nombre,
                    next: next1?.nombre,
                    dark: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KeeperCard(
                    title: 'PORTERO ${match.equipo2}',
                    current: goalkeeper2?.nombre,
                    next: next2?.nombre,
                    dark: false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _LivePerformanceCard(
              team1Name: match.equipo1,
              team2Name: match.equipo2,
              team1: _lineup1,
              team2: _lineup2,
              goals: counts.goals,
              assists: counts.assists,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _savingGoal ? null : () => _showGoalDialog(match),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE91E63),
                minimumSize: const Size(double.infinity, 66),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              icon: const Icon(Icons.sports_soccer, size: 30),
              label: const Text('REGISTRAR GOL'),
            ),
            if (_seconds == 0) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: canManage ? () => _nextTurn(match) : null,
                style: FilledButton.styleFrom(
                  backgroundColor:
                      _changeCountdown > 0 ? Colors.black54 : _danger,
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: Text(
                  _changeCountdown > 0
                      ? '$_changeCountdown s - SALTAR ESPERA'
                      : 'INICIAR SIGUIENTE TURNO',
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  _LiveCounts _liveCounts(List<Map<String, dynamic>> events) {
    final goals = <String, int>{};
    final assists = <String, int>{};
    for (final event in events) {
      if (event['tipo'] != 'GOL' && event['type'] != 'goal') {
        continue;
      }
      final scorer =
          (event['idGoleador'] as String?) ?? (event['scorerId'] as String?);
      final assist =
          (event['idAsistente'] as String?) ?? (event['assistId'] as String?);
      if (scorer != null && scorer.isNotEmpty) {
        goals[scorer] = (goals[scorer] ?? 0) + 1;
      }
      if (assist != null && assist.isNotEmpty) {
        assists[assist] = (assists[assist] ?? 0) + 1;
      }
    }
    return _LiveCounts(goals: goals, assists: assists);
  }

  LineupPlayer? _goalkeeperForTurn(List<LineupPlayer> players, int turnIndex) {
    final keepers =
        players.where((p) => p.ordenPortero > 0).toList()
          ..sort((a, b) => a.ordenPortero.compareTo(b.ordenPortero));
    final source = keepers.isEmpty ? players : keepers;
    if (source.isEmpty) {
      return null;
    }
    return source[turnIndex % source.length];
  }

  List<LineupPlayer> _swapPlayers(
    List<LineupPlayer> players,
    String first,
    String second,
  ) {
    final i = players.indexWhere((p) => p.id == first);
    final j = players.indexWhere((p) => p.id == second);
    if (i == -1 || j == -1) {
      return players;
    }
    final copy = [...players];
    final temp = copy[i];
    copy[i] = copy[j];
    copy[j] = temp;
    return copy;
  }

  Future<void> _showGoalDialog(MatchModel match) async {
    final result = await showDialog<_GoalDraft>(
      context: context,
      builder:
          (context) => _GoalDialog(
            team1Name: match.equipo1,
            team2Name: match.equipo2,
            team1: _lineup1,
            team2: _lineup2,
          ),
    );
    if (result == null) {
      return;
    }

    final player =
        result.team == 1
            ? _lineup1.firstWhere((p) => p.id == result.scorerId)
            : _lineup2.firstWhere((p) => p.id == result.scorerId);
    final assist =
        result.assistId.isEmpty
            ? null
            : (result.team == 1 ? _lineup1 : _lineup2).firstWhere(
              (p) => p.id == result.assistId,
            );
    final minute =
        (_turnIndex * (_turnDuration ~/ 60)) +
        ((_turnDuration - _seconds) ~/ 60) +
        1;

    setState(() => _savingGoal = true);
    try {
      await _service.addLiveGoal(
        matchId: match.id,
        scorerId: player.id,
        scorerName: player.nombre,
        scorerTeam: result.team,
        minute: minute,
        assistId: assist?.id,
        assistName: assist?.nombre,
      );
    } catch (e) {
      _showMessage('Error al guardar gol: $e');
    } finally {
      if (mounted) {
        setState(() => _savingGoal = false);
      }
    }
  }

  void _showMessage(String text) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${match.equipo1} vs ${match.equipo2}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 19,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _TimerTurnosScreenState._gold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                match.estado.toUpperCase(),
                style: const TextStyle(
                  color: _TimerTurnosScreenState._gold,
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

class _GoalkeeperList extends StatelessWidget {
  const _GoalkeeperList({
    required this.title,
    required this.players,
    required this.editable,
    required this.onChanged,
  });

  final String title;
  final List<LineupPlayer> players;
  final bool editable;
  final ValueChanged<List<LineupPlayer>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            if (players.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Sin convocados',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              ...players.map((player) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          player.nombre,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      for (var i = 1; i <= 5; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 5),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(999),
                            onTap:
                                editable
                                    ? () {
                                      final next =
                                          players
                                              .map(
                                                (p) =>
                                                    p.id == player.id
                                                        ? p.copyWith(
                                                          ordenPortero:
                                                              p.ordenPortero ==
                                                                      i
                                                                  ? 0
                                                                  : i,
                                                        )
                                                        : p,
                                              )
                                              .toList();
                                      onChanged(next);
                                    }
                                    : null,
                            child: Container(
                              width: 32,
                              height: 32,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color:
                                    player.ordenPortero == i
                                        ? _TimerTurnosScreenState._gold
                                        : Colors.grey.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      player.ordenPortero == i
                                          ? Colors.black
                                          : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                '$i',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 20,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _FormationSelector extends StatelessWidget {
  const _FormationSelector({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final FutsalFormation value;
  final bool enabled;
  final ValueChanged<FutsalFormation> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<FutsalFormation>(
      initialValue: value,
      items:
          FutsalFormation.values
              .map(
                (f) => DropdownMenuItem(
                  value: f,
                  child: Text('$label: ${f.label}'),
                ),
              )
              .toList(),
      onChanged: enabled ? (v) => onChanged(v ?? value) : null,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }
}

class _TacticalPitch extends StatelessWidget {
  const _TacticalPitch({
    required this.team1,
    required this.team2,
    required this.formation1,
    required this.formation2,
    required this.editable,
    required this.onSwapTeam1,
    required this.onSwapTeam2,
  });

  final List<LineupPlayer> team1;
  final List<LineupPlayer> team2;
  final FutsalFormation formation1;
  final FutsalFormation formation2;
  final bool editable;
  final void Function(String first, String second) onSwapTeam1;
  final void Function(String first, String second) onSwapTeam2;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.58),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            CustomPaint(
              size: const Size(double.infinity, double.infinity),
              painter: _PitchPainter(),
            ),
            ..._teamMarkers(team2, formation2, top: true, onSwap: onSwapTeam2),
            ..._teamMarkers(team1, formation1, top: false, onSwap: onSwapTeam1),
          ],
        ),
      ),
    );
  }

  List<Widget> _teamMarkers(
    List<LineupPlayer> team,
    FutsalFormation formation, {
    required bool top,
    required void Function(String first, String second) onSwap,
  }) {
    if (team.isEmpty) {
      return const [];
    }
    final keeper = team.firstWhere(
      (p) => p.ordenPortero == 1,
      orElse: () => team.first,
    );
    final fieldPlayers = team.where((p) => p.id != keeper.id).toList();
    final positions = <Alignment, LineupPlayer>{
      top ? const Alignment(0, -0.92) : const Alignment(0, 0.92): keeper,
    };

    void add(LineupPlayer? player, Alignment alignment) {
      if (player != null) {
        positions[alignment] = player;
      }
    }

    switch (formation) {
      case FutsalFormation.rombo:
        add(
          fieldPlayers.elementAtOrNull(0),
          top ? const Alignment(0, -0.66) : const Alignment(0, 0.66),
        );
        add(
          fieldPlayers.elementAtOrNull(1),
          top ? const Alignment(-0.56, -0.42) : const Alignment(-0.56, 0.42),
        );
        add(
          fieldPlayers.elementAtOrNull(2),
          top ? const Alignment(0.56, -0.42) : const Alignment(0.56, 0.42),
        );
        add(
          fieldPlayers.elementAtOrNull(3),
          top ? const Alignment(0, -0.16) : const Alignment(0, 0.16),
        );
      case FutsalFormation.cuadrado:
        add(
          fieldPlayers.elementAtOrNull(0),
          top ? const Alignment(-0.48, -0.58) : const Alignment(-0.48, 0.58),
        );
        add(
          fieldPlayers.elementAtOrNull(1),
          top ? const Alignment(0.48, -0.58) : const Alignment(0.48, 0.58),
        );
        add(
          fieldPlayers.elementAtOrNull(2),
          top ? const Alignment(-0.48, -0.25) : const Alignment(-0.48, 0.25),
        );
        add(
          fieldPlayers.elementAtOrNull(3),
          top ? const Alignment(0.48, -0.25) : const Alignment(0.48, 0.25),
        );
      case FutsalFormation.yGriega:
        add(
          fieldPlayers.elementAtOrNull(0),
          top ? const Alignment(0, -0.62) : const Alignment(0, 0.62),
        );
        add(
          fieldPlayers.elementAtOrNull(1),
          top ? const Alignment(0, -0.37) : const Alignment(0, 0.37),
        );
        add(
          fieldPlayers.elementAtOrNull(2),
          top ? const Alignment(-0.50, -0.16) : const Alignment(-0.50, 0.16),
        );
        add(
          fieldPlayers.elementAtOrNull(3),
          top ? const Alignment(0.50, -0.16) : const Alignment(0.50, 0.16),
        );
    }

    return positions.entries.map((entry) {
      return Align(
        alignment: entry.key,
        child: _PlayerMarker(
          player: entry.value,
          allPlayers: team,
          editable: editable,
          onSwap: onSwap,
        ),
      );
    }).toList();
  }
}

class _PlayerMarker extends StatelessWidget {
  const _PlayerMarker({
    required this.player,
    required this.allPlayers,
    required this.editable,
    required this.onSwap,
  });

  final LineupPlayer player;
  final List<LineupPlayer> allPlayers;
  final bool editable;
  final void Function(String first, String second) onSwap;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      enabled: editable,
      tooltip: 'Cambiar posicion',
      onSelected: (otherId) => onSwap(player.id, otherId),
      itemBuilder:
          (context) =>
              allPlayers
                  .where((p) => p.id != player.id)
                  .map((p) => PopupMenuItem(value: p.id, child: Text(p.nombre)))
                  .toList(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  player.ordenPortero == 1
                      ? _TimerTurnosScreenState._gold
                      : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Text(
              player.nombre.isEmpty ? '?' : player.nombre[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(maxWidth: 76),
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              player.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.58)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), line);
    canvas.drawCircle(center, 46, line);
    canvas.drawArc(
      Rect.fromCenter(center: Offset(center.dx, -10), width: 160, height: 120),
      0,
      3.14159,
      false,
      line,
    );
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(center.dx, size.height + 10),
        width: 160,
        height: 120,
      ),
      3.14159,
      3.14159,
      false,
      line,
    );

    final goal = Paint()..color = Colors.white;
    canvas.drawRect(
      Rect.fromCenter(center: Offset(center.dx, 4), width: 110, height: 8),
      goal,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, size.height - 4),
        width: 110,
        height: 8,
      ),
      goal,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _InfoBar extends StatelessWidget {
  const _InfoBar({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _TimerTurnosScreenState._dark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _InfoCell(label: 'TIEMPO', value: _format(seconds), gold: true),
          _InfoCell(label: 'HORA', value: now.format(context), gold: false),
        ],
      ),
    );
  }

  String _format(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({
    required this.label,
    required this.value,
    required this.gold,
  });

  final String label;
  final String value;
  final bool gold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          gold ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 9,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: gold ? _TimerTurnosScreenState._gold : Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _LiveScoreCard extends StatelessWidget {
  const _LiveScoreCard({required this.match});

  final MatchModel match;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _TimerTurnosScreenState._dark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Expanded(child: _ScoreTeamName(match.equipo1)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _TimerTurnosScreenState._gold,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${match.goles1} - ${match.goles2}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Expanded(child: _ScoreTeamName(match.equipo2)),
          ],
        ),
      ),
    );
  }
}

class _ScoreTeamName extends StatelessWidget {
  const _ScoreTeamName(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return Text(
      name.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 16,
      ),
    );
  }
}

class _TimerCard extends StatelessWidget {
  const _TimerCard({
    required this.seconds,
    required this.active,
    required this.canManage,
    required this.onTap,
  });

  final int seconds;
  final bool active;
  final bool canManage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Container(
        height: 160,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color:
              active
                  ? _TimerTurnosScreenState._softGreen
                  : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 74,
                fontWeight: FontWeight.w900,
                height: 0.92,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  active ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                  size: 20,
                ),
                const SizedBox(width: 4),
                Text(
                  canManage
                      ? (active ? 'TOCA PARA PAUSAR' : 'TOCA PARA INICIAR')
                      : (active ? 'EN JUEGO' : 'TIEMPO PAUSADO'),
                  style: TextStyle(
                    color: Colors.black.withValues(alpha: 0.75),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KeeperCard extends StatelessWidget {
  const _KeeperCard({
    required this.title,
    required this.current,
    required this.next,
    required this.dark,
  });

  final String title;
  final String? current;
  final String? next;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? _TimerTurnosScreenState._dark : Colors.white;
    final fg = dark ? Colors.white : Colors.black87;
    return Card(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: dark ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg.withValues(alpha: 0.58),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              current ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'SIGUIENTE:',
              style: TextStyle(
                color: fg.withValues(alpha: 0.42),
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              next ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg.withValues(alpha: 0.70),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LivePerformanceCard extends StatelessWidget {
  const _LivePerformanceCard({
    required this.team1Name,
    required this.team2Name,
    required this.team1,
    required this.team2,
    required this.goals,
    required this.assists,
  });

  final String team1Name;
  final String team2Name;
  final List<LineupPlayer> team1;
  final List<LineupPlayer> team2;
  final Map<String, int> goals;
  final Map<String, int> assists;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RENDIMIENTO EN VIVO',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _TeamStats(
                    title: team1Name,
                    players: team1,
                    goals: goals,
                    assists: assists,
                    highlight: _TimerTurnosScreenState._gold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TeamStats(
                    title: team2Name,
                    players: team2,
                    goals: goals,
                    assists: assists,
                    highlight: Colors.black54,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamStats extends StatelessWidget {
  const _TeamStats({
    required this.title,
    required this.players,
    required this.goals,
    required this.assists,
    required this.highlight,
  });

  final String title;
  final List<LineupPlayer> players;
  final Map<String, int> goals;
  final Map<String, int> assists;
  final Color highlight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: highlight,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        Divider(color: Colors.grey.shade300),
        ...players.map((player) {
          final g = goals[player.id] ?? 0;
          final a = assists[player.id] ?? 0;
          final hasStats = g > 0 || a > 0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    player.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '$g G  $a A',
                  style: TextStyle(
                    color: hasStats ? Colors.black : Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _GoalDialog extends StatefulWidget {
  const _GoalDialog({
    required this.team1Name,
    required this.team2Name,
    required this.team1,
    required this.team2,
  });

  final String team1Name;
  final String team2Name;
  final List<LineupPlayer> team1;
  final List<LineupPlayer> team2;

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  int _team = 1;
  String _scorerId = '';
  String _assistId = '';

  List<LineupPlayer> get _players => _team == 1 ? widget.team1 : widget.team2;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 740),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Text(
                'GOLAZO',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _teamButton(1, widget.team1Name)),
                  const SizedBox(width: 8),
                  Expanded(child: _teamButton(2, widget.team2Name)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    const Text(
                      'QUIEN HA MARCADO?',
                      style: TextStyle(
                        color: _TimerTurnosScreenState._danger,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PlayerGrid(
                      players: _players,
                      selectedId: _scorerId,
                      onSelect:
                          (id) => setState(() {
                            _scorerId = id;
                            if (_assistId == id) {
                              _assistId = '';
                            }
                          }),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'ASISTENCIA (OPCIONAL)',
                      style: TextStyle(
                        color: _TimerTurnosScreenState._gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _PlayerGrid(
                      players:
                          _players.where((p) => p.id != _scorerId).toList(),
                      selectedId: _assistId,
                      onSelect:
                          (id) => setState(
                            () => _assistId = _assistId == id ? '' : id,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed:
                          _scorerId.isEmpty
                              ? null
                              : () => Navigator.of(context).pop(
                                _GoalDraft(
                                  team: _team,
                                  scorerId: _scorerId,
                                  assistId: _assistId,
                                ),
                              ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE91E63),
                      ),
                      child: const Text('GUARDAR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _teamButton(int team, String name) {
    final selected = _team == team;
    return FilledButton(
      onPressed:
          () => setState(() {
            _team = team;
            _scorerId = '';
            _assistId = '';
          }),
      style: FilledButton.styleFrom(
        backgroundColor:
            selected ? _TimerTurnosScreenState._dark : Colors.grey.shade300,
        foregroundColor: selected ? Colors.white : Colors.black87,
      ),
      child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }
}

class _PlayerGrid extends StatelessWidget {
  const _PlayerGrid({
    required this.players,
    required this.selectedId,
    required this.onSelect,
  });

  final List<LineupPlayer> players;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          players.map((player) {
            final selected = player.id == selectedId;
            return SizedBox(
              width: 92,
              height: 112,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelect(player.id),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        selected ? _TimerTurnosScreenState._dark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color:
                          selected
                              ? _TimerTurnosScreenState._gold
                              : Colors.grey.shade300,
                      width: selected ? 3 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            selected ? Colors.white : Colors.grey.shade300,
                        child: Text(
                          player.nombre.isEmpty
                              ? '?'
                              : player.nombre[0].toUpperCase(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        player.nombre,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: selected ? Colors.white : Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
    );
  }
}

class _GoalDraft {
  const _GoalDraft({
    required this.team,
    required this.scorerId,
    required this.assistId,
  });

  final int team;
  final String scorerId;
  final String assistId;
}

class _LiveCounts {
  const _LiveCounts({required this.goals, required this.assists});

  final Map<String, int> goals;
  final Map<String, int> assists;
}

class _NoMatchState extends StatelessWidget {
  const _NoMatchState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 138,
                    height: 138,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x36C2A679), Colors.transparent],
                        radius: 0.74,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.sports_soccer,
                      color: Color(0xFFC2A679),
                      size: 66,
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'EL BALÓN ESTÁ PARADO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      'No hay ningún encuentro pendiente ni en juego en este momento.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF8A8A8A),
                        fontSize: 17,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 44),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _NoMatchPitchPainter(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF4A3E33),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  '¿QUÉ HACER AHORA?',
                                  style: TextStyle(
                                    color: Color(0xFFC2A679),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 34),
                              const Text(
                                'Toca descansar, hidratarse y analizar tácticas. Espera a que el administrador convoque el próximo encuentro.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  height: 1.45,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NoMatchPitchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width * 0.34, line);
    canvas.drawLine(Offset(0, size.height / 2), Offset(size.width, size.height / 2), line);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: size.width * 0.30),
      0,
      math.pi,
      false,
      line,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
