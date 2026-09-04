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

  static const List<Color> fallbackColors = <Color>[
    Color(0xFFE53935),
    Color(0xFF1E88E5),
    Color(0xFF43A047),
    Color(0xFFFFB300),
    Color(0xFF8E24AA),
    Color(0xFFF4511E),
  ];

  static Color fallbackColorFor(String nombre) =>
      fallbackColors[nombre.length % fallbackColors.length];

  @override
  Widget build(BuildContext context) {
    final border = Border.all(color: Colors.white, width: 2);

    if (fotoUrl.trim().isNotEmpty) {
      return Container(
        decoration: BoxDecoration(shape: BoxShape.circle, border: border),
        child: CircleAvatar(
          radius: size / 2,
          backgroundImage: NetworkImage(fotoUrl.trim()),
        ),
      );
    }

    final initial = nombre.isNotEmpty ? nombre.substring(0, 1).toUpperCase() : '?';

    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle, border: border),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: fallbackColorFor(nombre),
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
