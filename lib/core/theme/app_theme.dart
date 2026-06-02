import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F4C81),
        brightness: Brightness.light,
        primary: const Color(0xFF0F4C81),
        secondary: const Color(0xFFF39C12),
        surface: Colors.white,
      ),
      fontFamily: 'Roboto', // Professional default font
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F4C81),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      // Buttons, TextThemes etc to be expanded based on rigorous design systems.
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0F4C81),
        brightness: Brightness.dark,
        primary: const Color(0xFF4FA8F9),
        secondary: const Color(0xFFF39C12),
        surface: const Color(0xFF1E1E2C),
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E2C),
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1E1E2C),
      ),
    );
  }
}
