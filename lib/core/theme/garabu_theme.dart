import 'package:flutter/material.dart';

class GarabuTheme {
  // Paleta de Colores: Blancos cálidos y Marrones terrosos elegantes
  static const Color background = Color(0xFFFDFCFA);
  static const Color paperWhite = Color(0xFFFAF8F5);
  static const Color cardSurface = Color(0xFFFFFFFF);

  // Tonos Kraft / Café con leche / Beige
  static const Color primaryBrown = Color(0xFFC19A6B);
  static const Color lightBrown = Color(0xFFD2B48C);
  static const Color warmSand = Color(0xFFE8DFD8);
  static const Color deepEspresso = Color(0xFF4A3E3D);
  static const Color textPrimary = Color(0xFF2C2420);
  static const Color textSecondary = Color(0xFF7A6F68);

  // Líneas de cuaderno
  static const Color notebookLine = Color(0xFFE6E2DC);
  static const Color notebookMargin = Color(0xFFF0DCD5);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      primaryColor: primaryBrown,
      colorScheme: const ColorScheme.light(
        primary: primaryBrown,
        secondary: lightBrown,
        surface: cardSurface,
        onPrimary: Colors.white,
        onSecondary: deepEspresso,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: deepEspresso),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBrown,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBrown,
          side: const BorderSide(color: primaryBrown, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: warmSand),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: warmSand),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryBrown, width: 1.8),
        ),
        hintStyle: const TextStyle(color: textSecondary, fontSize: 14),
        labelStyle: const TextStyle(color: textPrimary, fontSize: 14),
      ),
    );
  }
}
