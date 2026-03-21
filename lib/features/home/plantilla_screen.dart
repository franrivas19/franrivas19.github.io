import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/models/app_user.dart';
import '../../core/services/firestore_service.dart';

class PlantillaScreen extends StatelessWidget {
  const PlantillaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();
    return Scaffold(
      appBar: AppBar(title: const Text('LA PLANTILLA')),
      body: StreamBuilder<List<AppUser>>(
        stream: service.allUsers(),
        builder: (context, snapshot) {
          final users = snapshot.data ?? [];
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            itemCount: users.length,
            itemBuilder: (context, i) {
              final u = users[i];
              final first = u.nombre.split(' ').first.toUpperCase();
              return InkWell(
                onTap: () => context.push('/perfil-jugador/${u.id}'),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (u.fotoUrl.trim().isNotEmpty)
                        Image.network(
                          u.fotoUrl.trim(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _Fallback(name: u.nombre),
                        )
                      else
                        _Fallback(name: u.nombre),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black87],
                            ),
                          ),
                          child: Text(
                            first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
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
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
    return Container(
      color: const Color(0xFF1E88E5),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 42),
      ),
    );
  }
}
