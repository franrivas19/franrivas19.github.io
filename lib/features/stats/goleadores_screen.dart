import 'package:flutter/material.dart';

import '../../core/models/app_user.dart';
import '../../core/services/firestore_service.dart';

class GoleadoresScreen extends StatelessWidget {
  const GoleadoresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('TABLA DE GOLEADORES')),
      body: StreamBuilder<List<AppUser>>(
        stream: service.allUsers(),
        builder: (context, snapshot) {
          final users = (snapshot.data ?? [])
            ..sort((a, b) => b.goles.compareTo(a.goles));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (users.isEmpty) {
            return const Center(child: Text('Sin datos de goleadores.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, i) {
              final u = users[i];
              return ListTile(
                leading: CircleAvatar(child: Text('${i + 1}')),
                title: Text(u.nombre),
                subtitle: Text('PJ ${u.pj}'),
                trailing: Text('${u.goles}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
              );
            },
            separatorBuilder: (_, __) => const Divider(),
            itemCount: users.length,
          );
        },
      ),
    );
  }
}
