import 'package:flutter/material.dart';

class AppTheme {
  static final ThemeData light = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0B5D3B),
      primary: const Color(0xFF0B5D3B),
      secondary: const Color(0xFFD19A2A),
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF8F7F2),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      backgroundColor: Color(0xFF0B5D3B),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    useMaterial3: true,
  );
}
