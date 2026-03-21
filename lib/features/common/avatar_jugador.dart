import 'package:flutter/material.dart';

class AvatarJugador extends StatelessWidget {
  const AvatarJugador({
    super.key,
    required this.nombre,
    required this.fotoUrl,
    this.size = 44,
  });

  final String nombre;
  final String fotoUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (fotoUrl.trim().isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(fotoUrl.trim()),
      );
    }

    final initial = nombre.isNotEmpty ? nombre.substring(0, 1).toUpperCase() : '?';
    final colors = <Color>[
      const Color(0xFFE53935),
      const Color(0xFF1E88E5),
      const Color(0xFF43A047),
      const Color(0xFFFFB300),
      const Color(0xFF8E24AA),
      const Color(0xFFF4511E),
    ];
    final bg = colors[nombre.length % colors.length];

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bg,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.45,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
