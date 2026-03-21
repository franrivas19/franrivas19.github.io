import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../../core/models/match_model.dart';
import '../../core/models/player_stat.dart';
import '../../core/services/firestore_service.dart';

class ActaScreen extends StatefulWidget {
  const ActaScreen({super.key});

  @override
  State<ActaScreen> createState() => _ActaScreenState();
}

class _ActaScreenState extends State<ActaScreen> {
  final _service = FirestoreService();
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MatchModel?>(
      stream: _service.nextPendingMatch(),
      builder: (context, matchSnap) {
        final match = matchSnap.data;
        if (matchSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (match == null) {
          return const Scaffold(body: Center(child: Text('No hay ningun partido pendiente.')));
        }

        return StreamBuilder<List<AppUser>>(
          stream: _service.allUsers(),
          builder: (context, usersSnap) {
            if (usersSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }
            final users = usersSnap.data ?? [];
            final conv1 = match.convocatoria1;
            final conv2 = match.convocatoria2;

            if (conv1.isEmpty && conv2.isEmpty) {
              return const Scaffold(
                body: Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Alineaciones vacias. Configura primero la convocatoria.'),
                  ),
                ),
              );
            }

            int goles1 = match.goles1;
            int goles2 = match.goles2;
            final stats = users
                .where((u) => conv1.contains(u.id) || conv2.contains(u.id))
                .map((u) => PlayerStat(
                      id: u.id,
                      nombre: u.nombre,
                      goles: 0,
                      asistencias: 0,
                      haJugado: true,
                      equipo: conv1.contains(u.id) ? 1 : 2,
                    ))
                .toList()
              ..sort((a, b) => a.equipo.compareTo(b.equipo));

            return StatefulBuilder(
              builder: (context, setLocal) {
                Future<void> save() async {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  setState(() => _saving = true);
                  try {
                    await _service.closeActa(
                      matchId: match.id,
                      goles1: goles1,
                      goles2: goles2,
                      stats: stats,
                    );
                    if (!mounted) {
                      return;
                    }
                    messenger.showSnackBar(const SnackBar(content: Text('Acta cerrada y estadisticas actualizadas')));
                    navigator.pop();
                  } catch (e) {
                    if (!mounted) {
                      return;
                    }
                    messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                  } finally {
                    if (mounted) {
                      setState(() => _saving = false);
                    }
                  }
                }

                return Scaffold(
                  appBar: AppBar(title: const Text('Cerrar Acta Oficial')),
                  bottomNavigationBar: Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton(
                      onPressed: _saving ? null : save,
                      child: _saving ? const CircularProgressIndicator() : const Text('GUARDAR ACTA'),
                    ),
                  ),
                  body: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _scoreControl(match.equipo1, goles1, (v) => setLocal(() => goles1 = v)),
                              const Text('VS', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                              _scoreControl(match.equipo2, goles2, (v) => setLocal(() => goles2 = v)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('RENDIMIENTO DE JUGADORES', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey)),
                      const SizedBox(height: 8),
                      ...stats.asMap().entries.map((entry) {
                        final i = entry.key;
                        final s = entry.value;
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: s.haJugado,
                                      onChanged: (v) => setLocal(() => stats[i] = s.copyWith(haJugado: v ?? true)),
                                    ),
                                    Expanded(child: Text(s.nombre, style: const TextStyle(fontWeight: FontWeight.w800))),
                                    Text(s.equipo == 1 ? 'LOC' : 'VIS', style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.grey)),
                                  ],
                                ),
                                if (s.haJugado)
                                  Row(
                                    children: [
                                      Expanded(child: _incDec('Goles', s.goles, (v) => setLocal(() => stats[i] = s.copyWith(goles: v)))),
                                      const SizedBox(width: 10),
                                      Expanded(child: _incDec('Asist.', s.asistencias, (v) => setLocal(() => stats[i] = s.copyWith(asistencias: v)))),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
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

  Widget _scoreControl(String team, int value, void Function(int) onChanged) {
    return Column(
      children: [
        Text(team.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900)),
        Row(
          children: [
            IconButton(onPressed: value > 0 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove)),
            Text('$value', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
            IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add)),
          ],
        ),
      ],
    );
  }

  Widget _incDec(String title, int value, void Function(int) onChanged) {
    return Row(
      children: [
        Text('$title: ', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(onPressed: value > 0 ? () => onChanged(value - 1) : null, icon: const Icon(Icons.remove_circle_outline)),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w900)),
        IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add_circle_outline)),
      ],
    );
  }
}
