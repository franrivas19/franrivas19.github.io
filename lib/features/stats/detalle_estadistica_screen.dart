import 'package:flutter/material.dart';

import '../../core/models/match_model.dart';
import '../../core/services/firestore_service.dart';

class DetalleEstadisticaScreen extends StatelessWidget {
  const DetalleEstadisticaScreen({super.key, required this.tipo});

  final String tipo;

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    final uid = service.currentUid;
    final title = tipo == 'asistencias' ? 'HISTORIAL DE ASISTENCIAS' : 'HISTORIAL DE GOLES';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: StreamBuilder<List<MatchModel>>(
        stream: service.contributionMatches(uid: uid, type: tipo),
        builder: (context, snapshot) {
          final matches = snapshot.data ?? const <MatchModel>[];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (matches.isEmpty) {
            return const Center(
              child: Text('No hay contribuciones para este filtro.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final m = matches[i];
              final mine = m.estadisticasJugadores.firstWhere((s) => s.id == uid);
              final contribution = tipo == 'asistencias' ? mine.asistencias : mine.goles;
              final metricName = tipo == 'asistencias' ? 'Asistencias' : 'Goles';

              return Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2A2A2A)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          m.fecha,
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          m.equipo1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2D2D2D)),
                        ),
                        child: Text(
                          '${m.goles1}-${m.goles2}',
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          m.equipo2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '+$contribution $metricName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFC2A679),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
