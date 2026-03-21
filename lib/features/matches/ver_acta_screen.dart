import 'package:flutter/material.dart';

import '../../core/models/match_model.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/app_colors.dart';

class VerActaScreen extends StatelessWidget {
  const VerActaScreen({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return StreamBuilder<MatchModel?>(
      stream: service.matchById(matchId),
      builder: (context, snapshot) {
        final match = snapshot.data;
        if (match == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final stats = [...match.estadisticasJugadores]..sort((a, b) => a.equipo.compareTo(b.equipo));

        return Scaffold(
          appBar: AppBar(title: const Text('RESUMEN DEL PARTIDO')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 8,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Color(0xFF262626), Color(0xFF0A0A0A)]),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.dorado.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('FINALIZADO', style: TextStyle(color: AppColors.dorado, fontWeight: FontWeight.w900)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _scoreTeam(match.equipo1, match.goles1, AppColors.local),
                          const Text('VS', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w900)),
                          _scoreTeam(match.equipo2, match.goles2, AppColors.visitante),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('MVP Y ESTADISTICAS', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.grey)),
              const SizedBox(height: 8),
              if (stats.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No hay datos guardados para este partido.'),
                )
              else
                ...stats.map(
                  (s) => Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: s.equipo == 1 ? AppColors.local : AppColors.visitante,
                        child: Text((s.nombre.isNotEmpty ? s.nombre[0] : '?').toUpperCase()),
                      ),
                      title: Text(s.nombre, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text((s.equipo == 1 ? match.equipo1 : match.equipo2).toUpperCase()),
                      trailing: Wrap(
                        spacing: 8,
                        children: [
                          if (s.goles > 0)
                            Chip(label: Text('⚽ ${s.goles}')),
                          if (s.asistencias > 0)
                            Chip(label: Text('👟 ${s.asistencias}')),
                          if (s.goles == 0 && s.asistencias == 0)
                            const Text('-'),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _scoreTeam(String name, int goals, Color color) {
    return Column(
      children: [
        Text(name.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        Text('$goals', style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
