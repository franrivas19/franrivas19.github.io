import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../../core/services/firestore_service.dart';
import '../../core/utils/date_utils.dart';

class PlayerDetailScreen extends StatelessWidget {
  const PlayerDetailScreen({super.key, required this.playerId});

  final String playerId;

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return StreamBuilder<List<AppUser>>(
      stream: service.allUsers(),
      builder: (context, userSnapshot) {
        AppUser? user;
        for (final candidate in (userSnapshot.data ?? <AppUser>[])) {
          if (candidate.id == playerId) {
            user = candidate;
            break;
          }
        }
        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final u = user;

        return FutureBuilder<int>(
          future: service.totalFinishedMatches(),
          builder: (context, totalSnap) {
            final total = totalSnap.data ?? 0;
            final asistencia = total > 0 ? ((u.pj / total) * 100).round().clamp(0, 100) : 0;
            final particip = u.goles + u.asistencias;
            final age = u.fechaNacimiento.isNotEmpty ? calculateAge(u.fechaNacimiento) : 0;

            return Scaffold(
              appBar: AppBar(title: Text(u.nombre.toUpperCase())),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Center(
                    child: Container(
                      width: 220,
                      height: 320,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC2A679), width: 2),
                      ),
                      child: u.fotoUrl.trim().isNotEmpty
                          ? Image.network(u.fotoUrl.trim(), fit: BoxFit.cover)
                          : const Icon(Icons.person, size: 90, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Tag(text: u.posicion.toUpperCase(), dark: false),
                      const SizedBox(width: 10),
                      _Tag(text: '⭐ ${u.valoracion.toStringAsFixed(1)}', dark: true),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _StatsGrid(items: [
                    _Item('Edad', '$age'),
                    _Item('Partidos', '${u.pj}'),
                    _Item('Asisten. peña', '$asistencia%'),
                    _Item('Goles', '${u.goles}'),
                    _Item('Asist.', '${u.asistencias}'),
                    _Item('Particip.', '$particip'),
                  ]),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.dark});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: dark ? const Color(0xFFC2A679) : Colors.white,
        border: Border.all(color: const Color(0xFFC2A679)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.items});

  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.35,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final it = items[i];
        return Card(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(it.value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                Text(it.label.toUpperCase(), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Item {
  _Item(this.label, this.value);

  final String label;
  final String value;
}
