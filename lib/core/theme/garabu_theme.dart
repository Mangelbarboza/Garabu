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

  // Paleta Artística Expandida de 24 colores para Bocetos, Ropas y Frutas
  static const List<Color> canvasPalette = [
    Color(0xFF1E1E1E), // Negro Carbón
    Color(0xFF5A4A42), // Café Chocolate
    Color(0xFF8D6E63), // Marrón Cálido
    Color(0xFFC19A6B), // Kraft Canela
    Color(0xFFE0BB95), // Tono Piel / Arena
    Color(0xFFF5EBE6), // Crema Suave
    Color(0xFFFFFFFF), // Blanco Puro
    Color(0xFF9E9E9E), // Gris Grafito
    Color(0xFFE53935), // Rojo Manzana
    Color(0xFFFF7043), // Naranja Mandarina
    Color(0xFFFFB74D), // Durazno
    Color(0xFFFFD54F), // Amarillo Banana / Piña
    Color(0xFFF06292), // Rosa Chicle
    Color(0xFFBA68C8), // Lila Pastel
    Color(0xFF880E4F), // Vino Tinto / Mora
    Color(0xFF7E57C2), // Uva Púrpura
    Color(0xFF43A047), // Verde Pera
    Color(0xFF8BC34A), // Verde Lima
    Color(0xFF2E7D32), // Verde Bosque
    Color(0xFF80CBC4), // Menta Fresca
    Color(0xFF00ACC1), // Turquesa
    Color(0xFF42A5F5), // Azul Cielo
    Color(0xFF1E88E5), // Azul Océano
    Color(0xFF3949AB), // Azul Índigo Profundo
  ];

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
