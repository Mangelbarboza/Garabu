import 'dart:typed_data';

/// Niveles de potencia del balde de pintura para cubrimiento de trazos a mano alzada
enum BucketPower {
  weak,   // Débil: tolerancia suave (22), sin expansión (ideal para detalles finos)
  medium, // Medio: tolerancia balanceada (48), expansión de 1 pixel (cubre antialiasing estándar)
  strong, // Fuerte: tolerancia alta (88), expansión de 2 pixeles (relleno uniforme que se pasa de bordes para cero huecos blancos)
}

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
    int tolerance = 35,
    BucketPower power = BucketPower.medium,
  }) {
    if (startX < 0 || startX >= width || startY < 0 || startY >= height) {
      return false;
    }

    final startIndex = startY * width + startX;
    final targetColor = pixels[startIndex];

    if (colorsAreClose(targetColor, fillColor, 5)) {
      return false;
    }

    // Configurar tolerancia y expansión según el nivel del balde
    int effectiveTolerance = tolerance;
    int expandRadius = 0;
    switch (power) {
      case BucketPower.weak:
        effectiveTolerance = 22;
        expandRadius = 0;
        break;
      case BucketPower.medium:
        effectiveTolerance = 48;
        expandRadius = 1;
        break;
      case BucketPower.strong:
        effectiveTolerance = 88;
        expandRadius = 2;
        break;
    }

    // Cola plana de índices
    final queue = Int32List(width * height);
    var head = 0;
    var tail = 0;

    // Bitmap de visitados para prevenir bucles
    final visited = Uint8List(width * height);

    queue[tail++] = startIndex;
    visited[startIndex] = 1;

    final filledIndices = <int>[];

    while (head < tail) {
      final idx = queue[head++];
      final currentX = idx % width;
      final currentY = idx ~/ width;

      pixels[idx] = fillColor;
      if (expandRadius > 0) {
        filledIndices.add(idx);
      }

      // 4 Vecinos: Norte, Sur, Este, Oeste
      // Oeste (X - 1)
      if (currentX > 0) {
        final leftIdx = idx - 1;
        if (visited[leftIdx] == 0 &&
            colorsAreClose(pixels[leftIdx], targetColor, effectiveTolerance)) {
          visited[leftIdx] = 1;
          queue[tail++] = leftIdx;
        }
      }

      // Este (X + 1)
      if (currentX < width - 1) {
        final rightIdx = idx + 1;
        if (visited[rightIdx] == 0 &&
            colorsAreClose(pixels[rightIdx], targetColor, effectiveTolerance)) {
          visited[rightIdx] = 1;
          queue[tail++] = rightIdx;
        }
      }

      // Norte (Y - 1)
      if (currentY > 0) {
        final upIdx = idx - width;
        if (visited[upIdx] == 0 &&
            colorsAreClose(pixels[upIdx], targetColor, effectiveTolerance)) {
          visited[upIdx] = 1;
          queue[tail++] = upIdx;
        }
      }

      // Sur (Y + 1)
      if (currentY < height - 1) {
        final downIdx = idx + width;
        if (visited[downIdx] == 0 &&
            colorsAreClose(pixels[downIdx], targetColor, effectiveTolerance)) {
          visited[downIdx] = 1;
          queue[tail++] = downIdx;
        }
      }
    }

    // Pasada de expansión morfológica para sobrepasar bordes con antialiasing
    if (expandRadius > 0 && filledIndices.isNotEmpty) {
      for (final idx in filledIndices) {
        final cx = idx % width;
        final cy = idx ~/ width;

        for (int dy = -expandRadius; dy <= expandRadius; dy++) {
          final ny = cy + dy;
          if (ny < 0 || ny >= height) continue;

          for (int dx = -expandRadius; dx <= expandRadius; dx++) {
            final nx = cx + dx;
            if (nx < 0 || nx >= width) continue;

            final nIdx = ny * width + nx;
            if (visited[nIdx] == 0) {
              // No pintar sobre líneas oscuras sólidas del boceto (evita desbordes fuera del dibujo)
              final nColor = pixels[nIdx];
              final isSolidOutline = isDarkOrSolidOutline(nColor);
              if (!isSolidOutline) {
                pixels[nIdx] = fillColor;
              }
            }
          }
        }
      }
    }

    return true;
  }

  /// Comprueba si un color es un contorno oscuro sólido para no sobrepasarlo
  static bool isDarkOrSolidOutline(int c) {
    final a = (c >> 24) & 0xFF;
    if (a < 80) return false; // Si es muy transparente, no es contorno sólido
    final r = c & 0xFF;
    final g = (c >> 8) & 0xFF;
    final b = (c >> 16) & 0xFF;
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b);
    return luminance < 60; // Píxel negro/marrón muy oscuro de contorno
  }

  /// Compara dos colores de 32 bits considerando una tolerancia por canal.
  static bool colorsAreClose(int c1, int c2, int tolerance) {
    if (c1 == c2) return true;
    if (tolerance <= 0) return false;

    // Asumiendo formato de 32-bit (ARGB o RGBA)
    final a1 = (c1 >> 24) & 0xFF;
    final r1 = c1 & 0xFF;
    final g1 = (c1 >> 8) & 0xFF;
    final b1 = (c1 >> 16) & 0xFF;

    final a2 = (c2 >> 24) & 0xFF;
    final r2 = c2 & 0xFF;
    final g2 = (c2 >> 8) & 0xFF;
    final b2 = (c2 >> 16) & 0xFF;

    return (a1 - a2).abs() <= tolerance &&
        (r1 - r2).abs() <= tolerance &&
        (g1 - g2).abs() <= tolerance &&
        (b1 - b2).abs() <= tolerance;
  }
}
