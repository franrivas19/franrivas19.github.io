import 'package:flutter/material.dart';

class AppColors {
  static const Color local = Color(0xFFD5E5B5);
  static const Color visitante = Color(0xFF312E2E);
  static const Color dorado = Color(0xFFC2A679);
  static const Color fondo = Color(0xFFF5F5F7);

  static Color fromColorName(String color) {
    switch (color) {
      case 'Rojo':
        return const Color(0xFFE53935);
      case 'Azul':
        return const Color(0xFF1E88E5);
      case 'Verde':
        return const Color(0xFF43A047);
      case 'Amarillo':
        return const Color(0xFFFFB300);
      case 'Blanco':
        return Colors.white;
      case 'Negro':
        return Colors.black;
      case 'Morado':
        return const Color(0xFF8E24AA);
      case 'Naranja':
        return const Color(0xFFF4511E);
      default:
        return Colors.grey;
    }
  }
}
