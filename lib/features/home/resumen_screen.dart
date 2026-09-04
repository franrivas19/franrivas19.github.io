import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_user.dart';
import '../../core/models/match_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bottom_nav.dart';
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
                    builder:
                        (ctx) => ListView(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Bienvenido,'),
                                      Text(
                                        firstName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.headlineSmall?.copyWith(
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed:
                                      () => Scaffold.of(ctx).openEndDrawer(),
                                  icon: const Icon(
                                    Icons.menu,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            if (next != null) ...[
                              ProximoPartidoCard(
                                match: next,
                                onTap:
                                    () =>
                                        context.push('/live-score/${next.id}'),
                                onEdit:
                                    () => context.push(
                                      '/editar-partido/${next.id}',
                                    ),
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
                                onTap:
                                    () => context.push('/ver-acta/${last.id}'),
                              ),
                              const SizedBox(height: 8),
                              if (_canRate(last))
                                FilledButton(
                                  onPressed:
                                      () => context.push(
                                        '/votar-partido/${last.id}',
                                      ),
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
                                    onTap:
                                        () => context.push(
                                          '/detalle-estadistica/goles',
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _StatCard(
                                    label: 'Asistencias',
                                    value: '${user?.asistencias ?? 0}',
                                    onTap:
                                        () => context.push(
                                          '/detalle-estadistica/asistencias',
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Card(
                              color: const Color(0xFF1A1A1A),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(18),
                                child: Row(
                                  children: [
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.star,
                                                color: Color(0xFFD4AF37),
                                              ),
                                              SizedBox(width: 8),
                                              Text(
                                                'VALORACION MEDIA',
                                                style: TextStyle(
                                                  color: Color(0xFFD4AF37),
                                                  fontWeight: FontWeight.w900,
                                                  letterSpacing: 0.5,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 6),
                                          Text(
                                            'Basado en tus ultimos partidos',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 66,
                                      height: 66,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFFDE08B),
                                            Color(0xFFC2A679),
                                          ],
                                        ),
                                        border: Border.fromBorderSide(
                                          BorderSide(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        (user?.valoracion ?? 0).toStringAsFixed(
                                          1,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            _TarjetaPuntosDefensivosStyled(
                              puntos: user?.puntosDefensivos ?? 0,
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'TU CARTA ULTIMATE TEAM',
                              style: TextStyle(
                                fontFamily: AppTheme.oswald,
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (user != null)
                              Center(child: _CartaFifaJugador(jugador: user)),
                          ],
                        ),
                  ),
                  bottomNavigationBar: const AppBottomNavBar(selectedIndex: 0),
                );
              },
            );
          },
        );
      },
    );
  }

  bool _esMesDeReseteo() {
    final month = DateTime.now().month;
    return month == DateTime.july || month == DateTime.august;
  }

  Future<void> _showResetSeasonDialog(BuildContext context) async {
    final controller = TextEditingController();
    bool procesando = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setLocal) {
            return AlertDialog(
              title: const Text(
                '⚠️ Cerrar Temporada',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Se guardará el historial de todos los jugadores y los '
                    'contadores volverán a 0. Esta acción no se puede '
                    'deshacer.',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Para confirmar, escribe la palabra RESETEAR en '
                    'mayúsculas:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'RESETEAR',
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                    onChanged: (_) => setLocal(() {}),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed:
                      procesando ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  onPressed:
                      controller.text == 'RESETEAR' && !procesando
                          ? () async {
                            setLocal(() => procesando = true);
                            try {
                              await _service.resetSeason();
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '¡Nueva temporada 26/27 iniciada!',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              setLocal(() => procesando = false);
                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          }
                          : null,
                  child:
                      procesando
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                          : const Text(
                            'SÍ, REINICIAR TODO',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  bool _canFillActa(MatchModel match, AppUser? user) {
    if (user == null) {
      return false;
    }
    final isManager = user.isAdmin || match.adminPartido == user.id;
    return isManager && match.estado == 'En Juego';
  }

  bool _canRate(MatchModel match) {
    final uid = _service.currentUid;
    if (uid.isEmpty) {
      return false;
    }
    final played = match.estadisticasJugadores.any((s) => s.id == uid);
    final voted = match.hanVotado.contains(uid);
    final open =
        DateTime.now().millisecondsSinceEpoch - match.timestampCierre <
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
              if (user?.isAdmin ?? false)
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
              ListTile(
                leading: const Icon(Icons.auto_stories),
                title: const Text('Resumen del mes'),
                onTap: () => context.push('/resumen-mensual'),
              ),
              if ((user?.isAdmin ?? false) && _esMesDeReseteo())
                ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: const Text(
                    'Cerrar Temporada',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showResetSeasonDialog(context);
                  },
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

class _TarjetaPuntosDefensivosStyled extends StatelessWidget {
  const _TarjetaPuntosDefensivosStyled({required this.puntos});

  final int puntos;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: const Color(0xFFF5F1E7),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A1A1A),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🛡️', style: TextStyle(fontSize: 28)),
                ),
                const SizedBox(width: 20),
                const Text(
                  'Empeño defensivo',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            Text(
              '$puntos',
              style: const TextStyle(
                fontFamily: AppTheme.oswald,
                color: Color(0xFFC2A679),
                fontWeight: FontWeight.w900,
                fontSize: 42,
                letterSpacing: -2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FifaCardClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.12, 0)
      ..lineTo(w * 0.88, 0)
      ..lineTo(w, h * 0.10)
      ..lineTo(w, h * 0.85)
      ..lineTo(w * 0.5, h)
      ..lineTo(0, h * 0.85)
      ..lineTo(0, h * 0.10)
      ..close();
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _CartaFifaJugador extends StatelessWidget {
  const _CartaFifaJugador({required this.jugador});

  final AppUser jugador;

  @override
  Widget build(BuildContext context) {
    final pjSeguros = jugador.pj > 0 ? jugador.pj : 1;
    final golesPorPartido = jugador.goles / pjSeguros;
    final asistenciasPorPartido = jugador.asistencias / pjSeguros;
    final pos =
        jugador.posicion
            .substring(0, jugador.posicion.length.clamp(0, 3))
            .toUpperCase();

    final ovr =
        jugador.pj > 0
            ? (55 + jugador.valoracion * 8).toInt().clamp(40, 99)
            : 50;
    final sho = (50 + golesPorPartido * 18).toInt().clamp(30, 99);
    final pas = (50 + asistenciasPorPartido * 22).toInt().clamp(30, 99);
    final pac = switch (pos) {
      'ALA' => (ovr + 8).clamp(0, 99),
      'PIV' => (ovr + 2).clamp(0, 99),
      'CIE' => (ovr - 4).clamp(30, 99),
      'POR' => (ovr - 15).clamp(30, 99),
      _ => ovr,
    };
    final dri = switch (pos) {
      'ALA' => (ovr + 7).clamp(0, 99),
      'PIV' => (ovr + 4).clamp(0, 99),
      'CIE' => (ovr - 3).clamp(30, 99),
      'POR' => (ovr - 10).clamp(30, 99),
      _ => ovr,
    };
    final def = switch (pos) {
      'CIE' => (ovr + 9).clamp(0, 99),
      'ALA' => (ovr - 8).clamp(30, 99),
      'PIV' => (ovr - 15).clamp(30, 99),
      'POR' => (ovr + 5).clamp(0, 99),
      _ => ovr,
    };
    final phy = switch (pos) {
      'PIV' || 'CIE' => (ovr + 6).clamp(0, 99),
      'ALA' => (ovr - 5).clamp(30, 99),
      _ => ovr,
    };

    final isPortero = pos == 'POR';
    final labels =
        isPortero
            ? ['DIV', 'HAN', 'KIC', 'REF', 'SPD', 'POS']
            : ['PAC', 'SHO', 'PAS', 'DRI', 'DEF', 'PHY'];
    final stats = [pac, sho, pas, dri, def, phy];

    const colorTexto = Color(0xFF332608);
    const colorBorde = Color(0xFF4A3B12);

    return Container(
      width: 220,
      height: 340,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipPath(
        clipper: _FifaCardClipper(),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFE8CA75),
                Color(0xFFC59F47),
                Color(0xFF9E7C30),
              ],
            ),
            border: Border.all(color: const Color(0xFFFDE08B), width: 2),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Opacity(
                    opacity: 0.08,
                    child: Icon(Icons.star, color: Colors.white, size: 340),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 150,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12, left: 8),
                            child: SizedBox(
                              width: 50,
                              child: Column(
                                children: [
                                  Text(
                                    '$ovr',
                                    style: const TextStyle(
                                      fontFamily: AppTheme.oswald,
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      color: colorTexto,
                                      height: 1,
                                    ),
                                  ),
                                  Text(
                                    pos,
                                    style: const TextStyle(
                                      fontFamily: AppTheme.oswald,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorTexto,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'G',
                                      style: TextStyle(
                                        color: Color(0xFFC2A679),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child:
                                  jugador.fotoUrl.isNotEmpty
                                      ? Image.network(
                                        jugador.fotoUrl,
                                        fit: BoxFit.cover,
                                        height: 138,
                                      )
                                      : Icon(
                                        Icons.person,
                                        size: 100,
                                        color: colorBorde.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      color: colorBorde.withValues(alpha: 0.4),
                      height: 12,
                    ),
                    Text(
                      jugador.nombre.split(' ').first.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: AppTheme.oswald,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: colorTexto,
                      ),
                    ),
                    Divider(
                      color: colorBorde.withValues(alpha: 0.4),
                      height: 12,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < 3; i++)
                                _FifaStatRow(
                                  stat: stats[i],
                                  label: labels[i],
                                  color: colorTexto,
                                ),
                            ],
                          ),
                          Container(
                            width: 1,
                            height: 70,
                            color: colorBorde.withValues(alpha: 0.2),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 3; i < 6; i++)
                                _FifaStatRow(
                                  stat: stats[i],
                                  label: labels[i],
                                  color: colorTexto,
                                ),
                            ],
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
  }
}

class _FifaStatRow extends StatelessWidget {
  const _FifaStatRow({required this.stat, required this.label, required this.color});

  final int stat;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: SizedBox(
        width: 75,
        child: Row(
          children: [
            SizedBox(
              width: 26,
              child: Text(
                '$stat',
                style: TextStyle(
                  fontFamily: AppTheme.oswald,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
            Text(
              label,
              style: TextStyle(fontFamily: AppTheme.oswald, fontSize: 15, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final watermark =
        label.toUpperCase() == 'GOLES' ? 'GOL' : label.toUpperCase();

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
                    fontFamily: AppTheme.oswald,
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
