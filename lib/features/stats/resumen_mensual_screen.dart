import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/firestore_service.dart';

const _meses = [
  'ENERO',
  'FEBRERO',
  'MARZO',
  'ABRIL',
  'MAYO',
  'JUNIO',
  'JULIO',
  'AGOSTO',
  'SEPTIEMBRE',
  'OCTUBRE',
  'NOVIEMBRE',
  'DICIEMBRE',
];

class ResumenMensualScreen extends StatefulWidget {
  const ResumenMensualScreen({super.key});

  @override
  State<ResumenMensualScreen> createState() => _ResumenMensualScreenState();
}

class _ResumenMensualScreenState extends State<ResumenMensualScreen> {
  final _service = FirestoreService();
  int _paso = 0;
  static const _totalPasos = 4;

  void _cerrar() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/resumen');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _service.currentUid;
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: FutureBuilder<MonthlySummary>(
        future: _service.monthlySummary(uid),
        builder: (context, snapshot) {
          final resumen =
              snapshot.data ?? const MonthlySummary(partidos: 0, goles: 0);
          return Stack(
            children: [
              switch (_paso) {
                0 => const _HistoriaIntro(),
                1 => _HistoriaParticipacion(partidos: resumen.partidos),
                2 => _HistoriaGoles(goles: resumen.goles),
                _ => _HistoriaSocio(socio: resumen.socioNombre),
              },
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_paso > 0) setState(() => _paso--);
                      },
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (_paso < _totalPasos - 1) {
                          setState(() => _paso++);
                        } else {
                          _cerrar();
                        }
                      },
                    ),
                  ),
                ],
              ),
              Positioned(
                top: 16,
                left: 8,
                right: 8,
                child: Row(
                  children: [
                    for (var i = 0; i < _totalPasos; i++)
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 3,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(50),
                            color:
                                i <= _paso
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                top: 24,
                right: 8,
                child: IconButton(
                  onPressed: _cerrar,
                  icon: const Text(
                    '✕',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoriaIntro extends StatelessWidget {
  const _HistoriaIntro();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '${_meses[now.month - 1]} ${now.year}',
            style: const TextStyle(
              color: Color(0xFFC2A679),
              fontWeight: FontWeight.w900,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'TU MES EN\nEL CÉSPED',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 48,
              height: 1,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Toca para descubrir tus estadísticas...',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _HistoriaParticipacion extends StatelessWidget {
  const _HistoriaParticipacion({required this.partidos});

  final int partidos;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COMPROMISO INTACTO.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Este mes has bajado al barro en',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          Text(
            '$partidos',
            style: const TextStyle(
              color: Color(0xFFC2A679),
              fontWeight: FontWeight.w900,
              fontSize: 120,
              height: 1,
            ),
          ),
          const Text(
            'PARTIDOS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoriaGoles extends StatelessWidget {
  const _HistoriaGoles({required this.goles});

  final int goles;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            'AFINANDO PUNTERÍA.',
            textAlign: TextAlign.end,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Has mandado el balón a la red',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
          Text(
            '$goles',
            style: const TextStyle(
              color: Color(0xFFC2A679),
              fontWeight: FontWeight.w900,
              fontSize: 120,
              height: 1,
            ),
          ),
          const Text(
            'VECES',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoriaSocio extends StatelessWidget {
  const _HistoriaSocio({required this.socio});

  final String? socio;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'TU SOCIO IDEAL.',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 32,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            width: 120,
            height: 120,
            decoration: const BoxDecoration(
              color: Color(0xFFC2A679),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🤝', style: TextStyle(fontSize: 50)),
          ),
          const SizedBox(height: 24),
          const Text(
            'El jugador con el que más has coincidido en el equipo este mes es:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            (socio ?? 'Sin datos todavía').toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 42,
            ),
          ),
        ],
      ),
    );
  }
}
