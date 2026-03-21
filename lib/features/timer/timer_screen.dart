import 'dart:async';

import 'package:flutter/material.dart';

class TimerTurnosScreen extends StatefulWidget {
  const TimerTurnosScreen({super.key});

  @override
  State<TimerTurnosScreen> createState() => _TimerTurnosScreenState();
}

class _TimerTurnosScreenState extends State<TimerTurnosScreen> {
  final _players = const [
    'JUAN', 'PEDRO', 'LUIS', 'MARIO', 'DIEGO', 'RUBEN', 'NICO', 'TONI',
    'SERGIO', 'ANDRES', 'ISRA', 'JOSE ROMERO', 'FRAN R.', 'BB', 'AA', 'KK',
  ];

  String? _deporte;
  final List<String> _oscuro = [];
  final List<String> _claro = [];
  int _index = 0;
  int _seconds = 360;
  Timer? _timer;

  int get _required {
    switch (_deporte) {
      case 'FUT11':
        return 11;
      case 'FUT7':
        return 7;
      default:
        return 5;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 0) {
        t.cancel();
        return;
      }
      setState(() => _seconds--);
    });
  }

  void _nextTurn() {
    setState(() {
      _index = (_index + 1) % _required;
      _seconds = 360;
    });
    _startTimer();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _deporte = null;
      _oscuro.clear();
      _claro.clear();
      _index = 0;
      _seconds = 360;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_deporte == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('TURNOS')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sport('FUTSAL', const Color(0xFFC5BEE6)),
            _sport('FUT7', const Color(0xFF00CC66)),
            _sport('FUT11', const Color(0xFF8FB89F)),
          ],
        ),
      );
    }

    if (_oscuro.length < _required || _claro.length < _required) {
      final avail = _players.where((p) => !_oscuro.contains(p) && !_claro.contains(p)).toList();
      return Scaffold(
        appBar: AppBar(title: Text('$_deporte - Equipos')),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _teamBlock('Equipo oscuro', _oscuro, Colors.black87, (name) => setState(() => _oscuro.remove(name))),
                  const SizedBox(height: 10),
                  _teamBlock('Equipo claro', _claro, Colors.lightBlue.shade100, (name) => setState(() => _claro.remove(name))),
                  const Divider(height: 30),
                  const Text('Disponibles', style: TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: avail
                        .map(
                          (p) => ActionChip(
                            label: Text(p),
                            onPressed: () {
                              setState(() {
                                if (_oscuro.length < _required) {
                                  _oscuro.add(p);
                                } else if (_claro.length < _required) {
                                  _claro.add(p);
                                }
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(onPressed: _reset, child: const Text('Reiniciar')),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _oscuro.length == _required && _claro.length == _required
                          ? () {
                              _seconds = 360;
                              _startTimer();
                              setState(() {});
                            }
                          : null,
                      child: const Text('Iniciar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Turno en juego')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(_format(_seconds), style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Card(
              child: ListTile(
                title: const Text('Oscuro'),
                subtitle: Text(_oscuro[_index]),
              ),
            ),
            Card(
              child: ListTile(
                title: const Text('Claro'),
                subtitle: Text(_claro[_index]),
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: _reset, child: const Text('Reiniciar'))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: _nextTurn, child: const Text('Siguiente turno'))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _sport(String name, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _deporte = name),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
          child: Text(name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  Widget _teamBlock(String title, List<String> players, Color color, void Function(String) onRemove) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: players
                  .map((p) => InputChip(label: Text(p), onDeleted: () => onRemove(p)))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _format(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }
}
