import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class ImageExporter {
  /// Renderiza una función de dibujo sobre un canvas con fondo transparente
  /// y exporta los bytes en formato PNG.
  static Future<Uint8List?> exportToTransparentPng({
    required Size size,
    required void Function(Canvas canvas, Size size) drawCallback,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size.width, size.height));

    // IMPORTANTE: NO se dibuja ningún color de fondo para preservar canal alfa transparente.
    drawCallback(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData?.buffer.asUint8List();
  }
}
