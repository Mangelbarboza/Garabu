import 'dart:typed_data';

/// Algoritmo Flood Fill (Balde de pintura) optimizado para buffers de píxeles Uint32List en Dart.
/// Funciona tanto en Flutter Móvil (Android/iOS) como en Flutter Web PWA.
class FloodFillUtil {
  /// Ejecuta el algoritmo de relleno de cubeta por BFS utilizando una cola plana
  /// para evitar desbordamientos de pila (stack overflow) y asignaciones lentas.
  static bool floodFill({
    required Uint32List pixels,
    required int width,
    required int height,
    required int startX,
    required int startY,
    required int fillColor,
    int tolerance = 30, // Tolerancia de color para lidiar con bordes suavizados (anti-aliasing)
  }) {
    if (startX < 0 || startX >= width || startY < 0 || startY >= height) {
      return false;
    }

    final startIndex = startY * width + startX;
    final targetColor = pixels[startIndex];

    if (colorsAreClose(targetColor, fillColor, 5)) {
      return false;
    }

    // Cola plana de índices
    final queue = Int32List(width * height);
    var head = 0;
    var tail = 0;

    // Bitmap de visitados para prevenir bucles
    final visited = Uint8List(width * height);

    queue[tail++] = startIndex;
    visited[startIndex] = 1;

    while (head < tail) {
      final idx = queue[head++];
      final currentX = idx % width;
      final currentY = idx ~/ width;

      pixels[idx] = fillColor;

      // 4 Vecinos: Norte, Sur, Este, Oeste
      // Oeste (X - 1)
      if (currentX > 0) {
        final leftIdx = idx - 1;
        if (visited[leftIdx] == 0 &&
            colorsAreClose(pixels[leftIdx], targetColor, tolerance)) {
          visited[leftIdx] = 1;
          queue[tail++] = leftIdx;
        }
      }

      // Este (X + 1)
      if (currentX < width - 1) {
        final rightIdx = idx + 1;
        if (visited[rightIdx] == 0 &&
            colorsAreClose(pixels[rightIdx], targetColor, tolerance)) {
          visited[rightIdx] = 1;
          queue[tail++] = rightIdx;
        }
      }

      // Norte (Y - 1)
      if (currentY > 0) {
        final upIdx = idx - width;
        if (visited[upIdx] == 0 &&
            colorsAreClose(pixels[upIdx], targetColor, tolerance)) {
          visited[upIdx] = 1;
          queue[tail++] = upIdx;
        }
      }

      // Sur (Y + 1)
      if (currentY < height - 1) {
        final downIdx = idx + width;
        if (visited[downIdx] == 0 &&
            colorsAreClose(pixels[downIdx], targetColor, tolerance)) {
          visited[downIdx] = 1;
          queue[tail++] = downIdx;
        }
      }
    }

    return true;
  }

  /// Compara dos colores de 32 bits considerando una tolerancia por canal.
  static bool colorsAreClose(int c1, int c2, int tolerance) {
    if (c1 == c2) return true;
    if (tolerance <= 0) return false;

    // Asumiendo formato de 32-bit (ARGB o RGBA)
    final a1 = (c1 >> 24) & 0xFF;
    final r1 = (c1 >> 16) & 0xFF;
    final g1 = (c1 >> 8) & 0xFF;
    final b1 = c1 & 0xFF;

    final a2 = (c2 >> 24) & 0xFF;
    final r2 = (c2 >> 16) & 0xFF;
    final g2 = (c2 >> 8) & 0xFF;
    final b2 = c2 & 0xFF;

    return (a1 - a2).abs() <= tolerance &&
        (r1 - r2).abs() <= tolerance &&
        (g1 - g2).abs() <= tolerance &&
        (b1 - b2).abs() <= tolerance;
  }
}
