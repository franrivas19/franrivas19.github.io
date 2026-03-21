import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette: Grey, Blue, Gold, Black
  static const Color darkGrey = Color(0xFF1E1E1E);
  static const Color mediumGrey = Color(0xFF2D2D2D);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color accentGrey = Color(0xFF757575);
  
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color darkBlue = Color(0xFF1E40AF);
  
  static const Color goldAccent = Color(0xFFD4A373);
  static const Color darkGold = Color(0xFFA68860);
  
  static const Color black = Color(0xFF000000);
  
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightGrey,
    
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: goldAccent,
      tertiary: darkGrey,
      surface: Colors.white,
      background: lightGrey,
      error: Color(0xFFEF4444),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: darkGrey,
      foregroundColor: lightGrey,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: lightGrey,
        letterSpacing: 1.2,
      ),
    ),
    
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        elevation: 6,
        shadowColor: primaryBlue.withOpacity(0.7),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      labelStyle: const TextStyle(
        color: accentGrey,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      prefixIconColor: accentGrey,
      suffixIconColor: accentGrey,
    ),
    
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: black,
        letterSpacing: 2,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: darkGrey,
        letterSpacing: 1,
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: darkGrey,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: darkGrey,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: accentGrey,
      ),
    ),
  );
}
