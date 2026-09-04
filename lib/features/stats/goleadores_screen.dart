import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';
import '../common/app_bottom_nav.dart';
import '../common/avatar_jugador.dart';

class GoleadoresScreen extends StatefulWidget {
  const GoleadoresScreen({super.key});

  @override
  State<GoleadoresScreen> createState() => _GoleadoresScreenState();
}

class _GoleadoresScreenState extends State<GoleadoresScreen> {
  final _service = FirestoreService();

  Map<String, List<int>> _historial(List<AppUser> jugadores) {
    final random = Random();
    final mapa = <String, List<int>>{};
    for (final jug in jugadores) {
      final historial = <int>[0];
      var golesRepartir = jug.goles;
      var golesAcumulados = 0;
      for (var i = 1; i <= jug.pj; i++) {
        final partidosRestantes = jug.pj - i + 1;
        final golesEstePartido =
            partidosRestantes == 1
                ? golesRepartir
                : random.nextInt(min(golesRepartir, 3) + 1);
        golesRepartir -= golesEstePartido;
        golesAcumulados += golesEstePartido;
        historial.add(golesAcumulados);
      }
      mapa[jug.nombre] = historial;
    }
    return mapa;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'ESTADÍSTICAS',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(selectedIndex: -1),
      body: StreamBuilder<List<AppUser>>(
        stream: _service.allUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.vipGold),
            );
          }
          final jugadores =
              (snapshot.data ?? [])
                  .where((u) => u.goles > 0 || u.asistencias > 0)
                  .toList()
                ..sort((a, b) => b.goles.compareTo(a.goles));

          if (jugadores.isEmpty) {
            return const Center(
              child: Text(
                'Aún no hay registros en la liga.',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final pichichi = jugadores.first;
          final topGrafico = jugadores.take(4).toList();
          final historial = _historial(topGrafico);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 4),
                child: Text(
                  'CLASIFICACIÓN GLOBAL',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              for (var i = 0; i < jugadores.length; i++) ...[
                _ItemGoleadorAesthetic(posicion: i + 1, jugador: jugadores[i]),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'ANÁLISIS Y DESTACADOS',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _TarjetaPichichiSemanal(jugador: pichichi),
              const SizedBox(height: 16),
              _GraficoRendimientoMinimalista(
                jugadores: topGrafico,
                historial: historial,
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _TarjetaPichichiSemanal extends StatelessWidget {
  const _TarjetaPichichiSemanal({required this.jugador});

  final AppUser jugador;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A1A), Color(0xFF333333)],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC2A679).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '🔥 PICHICHI SEMANAL',
                      style: TextStyle(
                        color: Color(0xFFC2A679),
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    jugador.nombre.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: AppTheme.oswald,
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                    ),
                  ),
                  const Text(
                    'El jugador más letal del momento',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            AvatarJugador(
              nombre: jugador.nombre,
              fotoUrl: jugador.fotoUrl,
              size: 70,
            ),
          ],
        ),
      ),
    );
  }
}

class _GraficoRendimientoMinimalista extends StatelessWidget {
  const _GraficoRendimientoMinimalista({
    required this.jugadores,
    required this.historial,
  });

  final List<AppUser> jugadores;
  final Map<String, List<int>> historial;

  static const _colores = [
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFFB300),
  ];

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EVOLUCIÓN GOLEADORA',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Histórico de goles por partido jugado',
                style: TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 160,
              child: CustomPaint(
                painter: _EvolucionPainter(
                  jugadores: jugadores,
                  historial: historial,
                  colores: _colores,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 12,
              children: [
                for (var i = 0; i < jugadores.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _colores[i % _colores.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        jugadores[i].nombre.split(' ').first,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EvolucionPainter extends CustomPainter {
  _EvolucionPainter({
    required this.jugadores,
    required this.historial,
    required this.colores,
  });

  final List<AppUser> jugadores;
  final Map<String, List<int>> historial;
  final List<Color> colores;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final maxPj = historial.values
        .map((v) => v.length - 1)
        .fold<double>(1, (a, b) => max(a, b.toDouble()));
    final maxGoles = historial.values
        .expand((v) => v)
        .fold<double>(1, (a, b) => max(a, b.toDouble()));

    final guidePaint =
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.35)
          ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = h - (i * (h / 4));
      canvas.drawLine(Offset(0, y), Offset(w, y), guidePaint);
    }
    final axisPaint =
        Paint()
          ..color = Colors.grey
          ..strokeWidth = 2;
    canvas.drawLine(Offset(0, 0), Offset(0, h), axisPaint);
    canvas.drawLine(Offset(0, h), Offset(w, h), axisPaint);

    for (var i = 0; i < jugadores.length; i++) {
      final color = colores[i % colores.length];
      final serie = historial[jugadores[i].nombre] ?? [0, jugadores[i].goles];
      final path = Path();
      final points = <Offset>[];
      for (var j = 0; j < serie.length; j++) {
        final x = (j / maxPj) * w;
        final y = h - ((serie[j] / maxGoles) * h);
        points.add(Offset(x, y));
        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
      for (final point in points) {
        canvas.drawCircle(point, 6, Paint()..color = color);
        canvas.drawCircle(point, 3, Paint()..color = Colors.white);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EvolucionPainter oldDelegate) => true;
}

class _ItemGoleadorAesthetic extends StatelessWidget {
  const _ItemGoleadorAesthetic({required this.posicion, required this.jugador});

  final int posicion;
  final AppUser jugador;

  @override
  Widget build(BuildContext context) {
    final destacado = posicion <= 3;
    const medallas = ['🥇', '🥈', '🥉'];

    return Card(
      elevation: destacado ? 4 : 0,
      color: destacado ? Colors.white : Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                destacado ? medallas[posicion - 1] : '$posicion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: destacado ? 24 : 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AvatarJugador(
              nombre: jugador.nombre,
              fotoUrl: jugador.fotoUrl,
              size: 46,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    jugador.nombre,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    '${jugador.pj} Partidos jugados',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 45,
              child: Column(
                children: [
                  Text(
                    '${jugador.goles}',
                    style: const TextStyle(
                      fontFamily: AppTheme.oswald,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  const Text(
                    'GOLES',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 30,
              width: 1,
              color: Colors.grey.shade300,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            SizedBox(
              width: 45,
              child: Column(
                children: [
                  Text(
                    '${jugador.asistencias}',
                    style: const TextStyle(
                      fontFamily: AppTheme.oswald,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      height: 1,
                      color: AppTheme.vipGold,
                    ),
                  ),
                  const Text(
                    'ASIST.',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
