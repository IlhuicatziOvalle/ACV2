import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme() {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: Colors.red,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme.copyWith(
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 16),
        bodySmall: TextStyle(fontSize: 16),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        titleSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 16),
          minimumSize: const Size(200, 48),
        ),
      ),
    );
  }

  static ThemeData highContrastTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.yellow,
        onSecondary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
        error: Colors.red,
        onError: Colors.white,
        brightness: Brightness.dark,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(fontSize: 18, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 18, color: Colors.white),
        bodySmall: TextStyle(fontSize: 18, color: Colors.white),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.black,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          minimumSize: const Size(200, 52),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
    );
  }
}

