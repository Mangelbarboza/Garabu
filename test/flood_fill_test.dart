import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:garabu/core/utils/flood_fill.dart';

void main() {
  group('FloodFillUtil Tests', () {
    test('FloodFill llena correctamente una región cerrada', () {
      const width = 5;
      const height = 5;
      final pixels = Uint32List(width * height);

      // Todos los píxeles inician en 0xFFFFFFFF (Blanco)
      for (int i = 0; i < pixels.length; i++) {
        pixels[i] = 0xFFFFFFFF;
      }

      // Dibujamos un borde cuadrado con 0xFF000000 (Negro)
      // Borde superior e inferior
      for (int x = 1; x <= 3; x++) {
        pixels[1 * width + x] = 0xFF000000;
        pixels[3 * width + x] = 0xFF000000;
      }
      // Borde lateral izquierdo y derecho
      pixels[2 * width + 1] = 0xFF000000;
      pixels[2 * width + 3] = 0xFF000000;

      // El centro (2, 2) está dentro de la caja cerrada
      const fillColor = 0xFFFF0000; // Rojo
      final filled = FloodFillUtil.floodFill(
        pixels: pixels,
        width: width,
        height: height,
        startX: 2,
        startY: 2,
        fillColor: fillColor,
      );

      expect(filled, true);
      // El centro debe estar teñido de rojo
      expect(pixels[2 * width + 2], fillColor);

      // Los bordes deben seguir siendo negros
      expect(pixels[1 * width + 2], 0xFF000000);
      expect(pixels[3 * width + 2], 0xFF000000);
      expect(pixels[2 * width + 1], 0xFF000000);
      expect(pixels[2 * width + 3], 0xFF000000);

      // Los píxeles exteriores deben seguir siendo blancos
      expect(pixels[0], 0xFFFFFFFF);
    });

    test('FloodFill retorna false si las coordenadas están fuera de límites', () {
      final pixels = Uint32List(10 * 10);
      final result = FloodFillUtil.floodFill(
        pixels: pixels,
        width: 10,
        height: 10,
        startX: 20,
        startY: 20,
        fillColor: 0xFF123456,
      );
      expect(result, false);
    });
  });
}
