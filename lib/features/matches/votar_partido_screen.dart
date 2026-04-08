import 'package:flutter/material.dart';

import '../../core/models/match_model.dart';
import '../../core/services/firestore_service.dart';

class VotarPartidoScreen extends StatefulWidget {
  const VotarPartidoScreen({super.key, required this.matchId});

  final String matchId;

  @override
  State<VotarPartidoScreen> createState() => _VotarPartidoScreenState();
}

class _VotarPartidoScreenState extends State<VotarPartidoScreen> {
  final _service = FirestoreService();
  bool _saving = false;
  final Map<String, double> _ratings = {};
  String _ratingsForMatchId = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MatchModel?>(
      stream: _service.matchById(widget.matchId),
      builder: (context, snapshot) {
        final match = snapshot.data;
        if (match == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final uid = _service.currentUid;
        final players = match.estadisticasJugadores.where((p) => p.id != uid).toList();

        if (_ratingsForMatchId != match.id) {
          _ratings
            ..clear()
            ..addEntries(players.map((p) => MapEntry(p.id, 3.0)));
          _ratingsForMatchId = match.id;
        }

        final alreadyVoted = match.hanVotado.contains(uid);
        final withinWindow = DateTime.now().millisecondsSinceEpoch - match.timestampCierre <=
            const Duration(hours: 72).inMilliseconds;

        if (alreadyVoted || !withinWindow) {
          return Scaffold(
            appBar: AppBar(title: const Text('VALORAR COMPANEROS')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  alreadyVoted
                      ? 'Ya has enviado tu valoracion para este partido.'
                      : 'La ventana de valoracion (72h) ya ha expirado.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return StatefulBuilder(
          builder: (context, setLocal) {
            Future<void> save() async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              setState(() => _saving = true);
              try {
                await _service.submitRatings(
                  match: match,
                  ratings: Map<String, double>.from(_ratings),
                  voterUid: uid,
                );
                if (!mounted) {
                  return;
                }
                messenger.showSnackBar(const SnackBar(content: Text('Votaciones enviadas')));
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
              appBar: AppBar(title: const Text('VALORAR COMPANEROS')),
              bottomNavigationBar: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton(
                  onPressed: _saving ? null : save,
                  child: _saving ? const CircularProgressIndicator() : const Text('ENVIAR VALORACIONES'),
                ),
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('Puntua a tus companeros y rivales. Esto afecta a su media historica.'),
                  const SizedBox(height: 10),
                  ...players.map((p) {
                    final score = _ratings[p.id] ?? 3.0;
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.w800)),
                                Chip(label: Text('${score.toStringAsFixed(1)} ⭐')),
                              ],
                            ),
                            Slider(
                              value: score,
                              min: 1,
                              max: 5,
                              divisions: 8,
                              onChanged: (v) => setLocal(() => _ratings[p.id] = v),
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
  }
}
