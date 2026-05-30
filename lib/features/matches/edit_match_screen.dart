import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../../core/models/match_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/date_utils.dart';

class EditMatchScreen extends StatefulWidget {
  const EditMatchScreen({super.key, required this.matchId});

  final String matchId;

  @override
  State<EditMatchScreen> createState() => _EditMatchScreenState();
}

class _EditMatchScreenState extends State<EditMatchScreen> {
  final _service = FirestoreService();
  bool _saving = false;
  String? _loadedMatchId;

  Map<String, int> assignments = {};
  String adminId = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _service.currentUserProfile(),
      builder: (context, userSnap) {
        final user = userSnap.data;
        return StreamBuilder<MatchModel?>(
          stream: _service.matchById(widget.matchId),
          builder: (context, matchSnap) {
            final match = matchSnap.data;
            if (match == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return StreamBuilder<List<AppUser>>(
              stream: _service.allUsers(),
              builder: (context, usersSnap) {
                final users = usersSnap.data ?? [];
                final started = isMatchStarted(match.fecha, match.hora);
                final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                final canManage =
                    (user?.rol == 'admin') || uid == match.adminPartido;

                if (_loadedMatchId != match.id) {
                  assignments = <String, int>{
                    for (final u in users)
                      u.id:
                          match.convocatoria1.contains(u.id)
                              ? 1
                              : (match.convocatoria2.contains(u.id) ? 2 : 0),
                  };
                  adminId = match.adminPartido;
                  _loadedMatchId = match.id;
                } else {
                  for (final user in users) {
                    assignments.putIfAbsent(user.id, () => 0);
                  }
                }

                return Scaffold(
                  appBar: AppBar(title: const Text('CONVOCATORIA')),
                  bottomNavigationBar:
                      started
                          ? null
                          : Padding(
                            padding: const EdgeInsets.all(16),
                            child: FilledButton(
                              onPressed:
                                  _saving
                                      ? null
                                      : () => save(context, match, users),
                              child:
                                  _saving
                                      ? const CircularProgressIndicator()
                                      : const Text('CONFIRMAR ALINEACIONES'),
                            ),
                          ),
                  body: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (started)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '🔒 EL PARTIDO HA COMENZADO. CONVOCATORIA CERRADA.',
                            style: TextStyle(
                              color: Color(0xFFD32F2F),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _counter(
                            match.equipo1.toUpperCase(),
                            assignments.values.where((v) => v == 1).length,
                            const Color(0xFFD5E5B5),
                          ),
                          _counter(
                            'BANQUILLO',
                            assignments.values.where((v) => v == 0).length,
                            Colors.grey.shade300,
                          ),
                          _counter(
                            match.equipo2.toUpperCase(),
                            assignments.values.where((v) => v == 2).length,
                            const Color(0xFF312E2E),
                            textLight: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (user?.rol == 'admin' && !started)
                        DropdownButtonFormField<String>(
                          initialValue: adminId.isEmpty ? null : adminId,
                          items:
                              users
                                  .map(
                                    (u) => DropdownMenuItem(
                                      value: u.id,
                                      child: Text(u.nombre),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setState(() => adminId = v ?? ''),
                          decoration: const InputDecoration(
                            labelText: 'Designar admin del partido',
                          ),
                        ),
                      const SizedBox(height: 10),
                      Text(
                        started
                            ? 'Modo solo lectura. Ya no se admiten cambios.'
                            : (canManage
                                ? 'Eres administrador. Puedes mover a todos.'
                                : 'Solo puedes mover tu ficha.'),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 10),
                      ...users.map((u) {
                        final status = assignments[u.id] ?? 0;
                        final teamName =
                            status == 1
                                ? match.equipo1
                                : (status == 2
                                    ? match.equipo2
                                    : 'No convocado / Banquillo');

                        return Card(
                          child: ListTile(
                            onTap: () {
                              if (started) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Convocatoria cerrada'),
                                  ),
                                );
                                return;
                              }
                              final isMine = u.id == uid;
                              if (!(canManage || isMine)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Solo puedes mover tu ficha.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              setState(() {
                                assignments[u.id] = (status + 1) % 3;
                              });
                            },
                            leading: _ShirtIcon(
                              initial:
                                  (u.nombre.isNotEmpty ? u.nombre[0] : '?')
                                      .toUpperCase(),
                              color:
                                  status == 1
                                      ? const Color(0xFFD5E5B5)
                                      : (status == 2
                                          ? const Color(0xFF312E2E)
                                          : Colors.grey.shade300),
                              selected: status != 0,
                            ),
                            title: Text(u.nombre),
                            subtitle: Text(teamName.toUpperCase()),
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

  Future<void> save(
    BuildContext context,
    MatchModel match,
    List<AppUser> users,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await _service.saveLineup(
        matchId: match.id,
        convocatoria1:
            assignments.entries
                .where((e) => e.value == 1)
                .map((e) => e.key)
                .toList(),
        convocatoria2:
            assignments.entries
                .where((e) => e.value == 2)
                .map((e) => e.key)
                .toList(),
        adminPartido: adminId,
      );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('Convocatoria guardada')),
      );
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

  Widget _counter(
    String title,
    int count,
    Color color, {
    bool textLight = false,
  }) {
    return Card(
      color: color,
      child: SizedBox(
        width: 110,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: textLight ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: textLight ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShirtIcon extends StatelessWidget {
  const _ShirtIcon({
    required this.initial,
    required this.color,
    required this.selected,
  });

  final String initial;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(48, 48),
            painter: _ShirtPainter(color: color, selected: selected),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              initial,
              style: TextStyle(
                color: selected ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShirtPainter extends CustomPainter {
  _ShirtPainter({required this.color, required this.selected});

  final Color color;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final path =
        Path()
          ..moveTo(size.width * 0.20, size.height * 0.15)
          ..quadraticBezierTo(
            size.width * 0.50,
            size.height * 0.28,
            size.width * 0.80,
            size.height * 0.15,
          )
          ..lineTo(size.width, size.height * 0.28)
          ..lineTo(size.width * 0.88, size.height * 0.45)
          ..lineTo(size.width * 0.85, size.height * 0.95)
          ..lineTo(size.width * 0.15, size.height * 0.95)
          ..lineTo(size.width * 0.12, size.height * 0.45)
          ..lineTo(0, size.height * 0.28)
          ..close();

    canvas.drawPath(path, Paint()..color = color);
    if (!selected) {
      canvas.drawPath(
        path,
        Paint()..color = Colors.white.withValues(alpha: 0.40),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ShirtPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.selected != selected;
  }
}
