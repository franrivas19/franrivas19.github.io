import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_user.dart';
import '../../core/models/match_model.dart';
import '../../core/services/firestore_service.dart';
import '../common/avatar_jugador.dart';
import '../common/match_cards.dart';

class ResumenScreen extends StatefulWidget {
  const ResumenScreen({super.key});

  @override
  State<ResumenScreen> createState() => _ResumenScreenState();
}

class _ResumenScreenState extends State<ResumenScreen> {
  final _service = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _service.currentUserProfile(),
      builder: (context, userSnap) {
        final user = userSnap.data;
        final firstName = (user?.nombre ?? 'Jugador').split(' ').first;

        return StreamBuilder<MatchModel?>(
          stream: _service.nextPendingMatch(),
          builder: (context, nextSnap) {
            final next = nextSnap.data;
            return StreamBuilder<MatchModel?>(
              stream: _service.lastFinishedMatch(),
              builder: (context, lastSnap) {
                final last = lastSnap.data;
                return Scaffold(
                  endDrawer: _buildDrawer(context),
                  body: Builder(
                    builder: (ctx) => ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Row(
                          children: [
                            AvatarJugador(
                              nombre: user?.nombre ?? 'Jugador',
                              fotoUrl: user?.fotoUrl ?? '',
                              size: 54,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Bienvenido,'),
                                  Text(
                                    firstName,
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Scaffold.of(ctx).openEndDrawer(),
                              icon: const Icon(Icons.menu),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (next != null) ...[
                          ProximoPartidoCard(
                            match: next,
                            onTap: () => context.push('/editar-partido/${next.id}'),
                          ),
                          const SizedBox(height: 10),
                          if (_canFillActa(next))
                            FilledButton.icon(
                              onPressed: () => context.push('/acta'),
                              icon: const Icon(Icons.edit),
                              label: const Text('RELLENAR Y CERRAR ACTA'),
                            ),
                          const SizedBox(height: 20),
                        ],
                        if (last != null) ...[
                          UltimoPartidoCard(
                            match: last,
                            onTap: () => context.push('/ver-acta/${last.id}'),
                          ),
                          const SizedBox(height: 8),
                          if (_canRate(last))
                            FilledButton(
                              onPressed: () => context.push('/votar-partido/${last.id}'),
                              child: const Text('PUNTUAR A LOS JUGADORES'),
                            ),
                          const SizedBox(height: 20),
                        ],
                        Row(
                          children: [
                            Expanded(child: _StatCard(label: 'Goles', value: '${user?.goles ?? 0}')),
                            const SizedBox(width: 12),
                            Expanded(child: _StatCard(label: 'Asistencias', value: '${user?.asistencias ?? 0}')),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Card(
                          color: const Color(0xFF1A1A1A),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('VALORACION MEDIA', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900)),
                                      SizedBox(height: 6),
                                      Text('Basado en tus ultimos partidos', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 66,
                                  height: 66,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(colors: [Color(0xFFFDE08B), Color(0xFFC2A679)]),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    (user?.valoracion ?? 0).toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
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
    );
  }

  bool _canFillActa(MatchModel match) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return false;
    }
    return _service.isMainAdmin || match.adminPartido == user.uid;
  }

  bool _canRate(MatchModel match) {
    final uid = _service.currentUid;
    if (uid.isEmpty) {
      return false;
    }
    final played = match.estadisticasJugadores.any((s) => s.id == uid);
    final voted = match.hanVotado.contains(uid);
    final open = DateTime.now().millisecondsSinceEpoch - match.timestampCierre <
        const Duration(days: 3).inMilliseconds;
    return played && !voted && open;
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('EL VESTUARIO', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Editar perfil'),
              onTap: () => context.push('/editar-perfil'),
            ),
            if (_service.isMainAdmin)
              ListTile(
                leading: const Icon(Icons.add_circle),
                title: const Text('Crear partido'),
                onTap: () => context.push('/crear-partido'),
              ),
            ListTile(
              leading: const Icon(Icons.groups),
              title: const Text('La plantilla'),
              onTap: () => context.push('/plantilla'),
            ),
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Turnos'),
              onTap: () => context.push('/timer'),
            ),
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Tabla de goleadores'),
              onTap: () => context.push('/goleadores'),
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar sesion'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Text(value, style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
            Text(label, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
