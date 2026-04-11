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
                  endDrawer: _buildDrawer(context, user),
                  body: Builder(
                    builder: (ctx) => ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
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
                              icon: const Icon(Icons.menu, color: Colors.black),
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
                          if (_canFillActa(next, user))
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
                            Expanded(
                              child: _StatCard(
                                label: 'Goles',
                                value: '${user?.goles ?? 0}',
                                onTap: () => context.push('/detalle-estadistica/goles'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                label: 'Asistencias',
                                value: '${user?.asistencias ?? 0}',
                                onTap: () => context.push('/detalle-estadistica/asistencias'),
                              ),
                            ),
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
                                        Row(
                                        children: [
                                          const Icon(Icons.star, color: Color(0xFFD4AF37)),
                                          const SizedBox(width: 8),
                                          const Text('VALORACION MEDIA', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, letterSpacing: 0.5, fontSize: 20)),
                                        ],
                                        ),
                                      SizedBox(height: 6),
                                      Text('Basado en tus ultimos partidos', style: TextStyle(color: Colors.white70, fontSize: 15)),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 66,
                                  height: 66,
                                    decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(colors: [Color(0xFFFDE08B), Color(0xFFC2A679)]),
                                    border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                                    ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    (user?.valoracion ?? 0).toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.black),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  bottomNavigationBar: _buildBottomNav(context, activeIndex: 0),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBottomNav(BuildContext context, {required int activeIndex}) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F2FB),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _BottomNavItem(
                label: 'Inicio',
                icon: Icons.home_rounded,
                selected: activeIndex == 0,
                onTap: () => context.go('/resumen'),
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                label: 'Plantilla',
                icon: Icons.groups_rounded,
                selected: activeIndex == 1,
                onTap: () => context.go('/plantilla'),
              ),
            ),
            Expanded(
              child: _BottomNavItem(
                label: 'Turnos',
                icon: Icons.timer_rounded,
                selected: activeIndex == 2,
                onTap: () => context.go('/timer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _canFillActa(MatchModel match, AppUser? user) {
    if (user == null) {
      return false;
    }
    final isManager = user.rol == 'admin' || match.adminPartido == user.id;
    return isManager && match.estado == 'En Juego';
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

  Widget _buildDrawer(BuildContext context, AppUser? user) {
    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: ListTileTheme(
          iconColor: Colors.black87,
          textColor: Colors.black87,
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'EL VESTUARIO',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Editar perfil'),
                onTap: () => context.push('/editar-perfil'),
              ),
              if (user?.rol == 'admin')
                ListTile(
                  leading: const Icon(Icons.add_circle),
                  title: const Text('Crear partido'),
                  onTap: () => context.push('/crear-partido'),
                ),
              ListTile(
                leading: const Icon(Icons.calendar_month),
                title: const Text('Calendario'),
                onTap: () => context.push('/calendario'),
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
              ListTile(
                leading: const Icon(Icons.auto_awesome),
                title: const Text('Mis valoraciones'),
                onTap: () => context.push('/mis-valoraciones'),
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
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = selected ? const Color(0xFFE1D1FA) : Colors.transparent;
    final foreground = selected ? const Color(0xFF1C1630) : const Color(0xFF5B5670);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: foreground, size: 27),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final watermark = label.toUpperCase() == 'GOLES' ? 'GOL' : label.toUpperCase();

    return Card(
      color: const Color(0xFFE3D9F2),
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 150,
          child: Stack(
            children: [
              Positioned(
                left: 16,
                top: 12,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF2D2E36),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 70,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFFFF5B00),
                    fontSize: 50,
                    height: 0.9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Positioned(
                left: watermark.length > 4 ? 10 : -20,
                bottom: watermark.length > 4 ? 5 : -10,
                child: Text(
                  watermark,
                  style: TextStyle(
                    color: const Color(0xFF8776AE).withValues(alpha: 0.22),
                    fontSize: watermark.length > 4 ? 30 : 115,
                    height: 1,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
