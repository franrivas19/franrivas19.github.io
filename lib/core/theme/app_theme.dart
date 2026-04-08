import 'package:flutter/material.dart';

class AppTheme {
  static const Color vipBlack = Color(0xFF111111);
  static const Color vipSurface = Color(0xFF1A1A1A);
  static const Color vipSurfaceAlt = Color(0xFF222222);
  static const Color vipGold = Color(0xFFC2A679);
  static const Color vipGoldStrong = Color(0xFFD4B483);
  static const Color vipText = Color(0xFFF3F3F3);
  static const Color vipMuted = Color(0xFF9E9E9E);
  static const Color darkGrey = vipSurfaceAlt;
  static const Color mediumGrey = vipSurface;
  static const Color lightGrey = Color(0xFF2C2C2C);
  static const Color accentGrey = vipMuted;
  static const Color primaryBlue = Color(0xFF3A4F6B);
  static const Color lightBlue = Color(0xFF4C6484);
  static const Color darkBlue = Color(0xFF1D2B3B);
  static const Color goldAccent = vipGold;
  static const Color darkGold = Color(0xFFA68860);

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: vipBlack,
    canvasColor: vipBlack,
    colorScheme: const ColorScheme.dark(
      primary: vipGold,
      secondary: vipGoldStrong,
      tertiary: vipSurfaceAlt,
      surface: vipSurface,
      error: Color(0xFFE57373),
      onPrimary: Color(0xFF111111),
      onSecondary: Color(0xFF111111),
      onSurface: vipText,
    ),
    cardTheme: CardThemeData(
      color: vipSurface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: vipBlack,
      foregroundColor: vipText,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: vipText,
        letterSpacing: 1.2,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: vipGold,
        foregroundColor: vipBlack,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        elevation: 0,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: vipGold,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: vipSurface,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2D2D2D), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF2D2D2D), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: vipGold, width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      labelStyle: const TextStyle(
        color: vipMuted,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIconColor: vipMuted,
      suffixIconColor: vipMuted,
    ),
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: vipText,
        letterSpacing: 2,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: vipText,
        letterSpacing: 1,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: vipText,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: vipText,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: vipMuted,
      ),
    ),
  );
}
