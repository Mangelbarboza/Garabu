import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../core/utils/flood_fill.dart';

enum CanvasTool { pencil, bucket }

class DrawnLine {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawnLine({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class DrawingCanvas extends StatefulWidget {
  final Size canvasSize;
  final Widget? backgroundWidget;
  final Widget? overlayWidget;
  final void Function(DrawingCanvasController controller)? onControllerReady;

  const DrawingCanvas({
    super.key,
    required this.canvasSize,
    this.backgroundWidget,
    this.overlayWidget,
    this.onControllerReady,
  });

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasController {
  final DrawingCanvasState _state;
  DrawingCanvasController(this._state);

  void setTool(CanvasTool tool) => _state.setTool(tool);
  void setColor(Color color) => _state.setColor(color);
  void setStrokeWidth(double width) => _state.setStrokeWidth(width);
  void undo() => _state.undo();
  void clear() => _state.clear();

  Future<Uint8List?> exportTransparentPng() => _state.exportTransparentPng();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  CanvasTool _currentTool = CanvasTool.pencil;
  Color _currentColor = const Color(0xFF2C2420);
  double _currentStrokeWidth = 4.0;

  final List<DrawnLine> _lines = [];
  DrawnLine? _activeLine;
  ui.Image? _rasterLayer; // Capa de píxeles generada por el balde de pintura (Flood fill)
  final List<ui.Image?> _rasterHistory = [];

  @override
  void initState() {
    super.initState();
    if (widget.onControllerReady != null) {
      widget.onControllerReady!(DrawingCanvasController(this));
    }
  }

  void setTool(CanvasTool tool) {
    setState(() {
      _currentTool = tool;
    });
  }

  void setColor(Color color) {
    setState(() {
      _currentColor = color;
    });
  }

  void setStrokeWidth(double width) {
    setState(() {
      _currentStrokeWidth = width;
    });
  }

  void undo() {
    setState(() {
      if (_lines.isNotEmpty) {
        _lines.removeLast();
      } else if (_rasterHistory.isNotEmpty) {
        _rasterLayer = _rasterHistory.removeLast();
      }
    });
  }

  void clear() {
    setState(() {
      _lines.clear();
      _activeLine = null;
      _rasterLayer = null;
      _rasterHistory.clear();
    });
  }

  Future<void> _handleFloodFillTap(Offset tapPosition) async {
    final w = widget.canvasSize.width.toInt();
    final h = widget.canvasSize.height.toInt();
    if (w <= 0 || h <= 0) return;

    // 1. Snapshot del lienzo actual a imagen
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));

    if (_rasterLayer != null) {
      canvas.drawImage(_rasterLayer!, Offset.zero, Paint());
    }

    for (final line in _lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = line.strokeWidth
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < line.points.length - 1; i++) {
        canvas.drawLine(line.points[i], line.points[i + 1], paint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(w, h);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) return;

    final pixels = byteData.buffer.asUint32List();

    // Color en formato RGBA de 32 bits
    final a = (_currentColor.a * 255.0).round().clamp(0, 255);
    final r = (_currentColor.r * 255.0).round().clamp(0, 255);
    final g = (_currentColor.g * 255.0).round().clamp(0, 255);
    final b = (_currentColor.b * 255.0).round().clamp(0, 255);
    final fillRgba = (a << 24) | (b << 16) | (g << 8) | r;

    final filled = FloodFillUtil.floodFill(
      pixels: pixels,
      width: w,
      height: h,
      startX: tapPosition.dx.toInt().clamp(0, w - 1),
      startY: tapPosition.dy.toInt().clamp(0, h - 1),
      fillColor: fillRgba,
      tolerance: 35,
    );

    if (filled) {
      final completer = Completer<ui.Image>();
      ui.decodeImageFromPixels(
        byteData.buffer.asUint8List(),
        w,
        h,
        ui.PixelFormat.rgba8888,
        (ui.Image img) => completer.complete(img),
      );
      final newImage = await completer.future;

      setState(() {
        _rasterHistory.add(_rasterLayer);
        _rasterLayer = newImage;
        _lines.clear(); // Los trazos anteriores quedan consolidados en la capa raster
      });
    }
  }

  Future<Uint8List?> exportTransparentPng() async {
    final w = widget.canvasSize.width.toInt();
    final h = widget.canvasSize.height.toInt();
    if (w <= 0 || h <= 0) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()));

    // NO se dibuja ningún fondo, para asegurar 100% de transparencia
    if (_rasterLayer != null) {
      canvas.drawImage(_rasterLayer!, Offset.zero, Paint());
    }

    for (final line in _lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = line.strokeWidth
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < line.points.length - 1; i++) {
        canvas.drawLine(line.points[i], line.points[i + 1], paint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(w, h);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.canvasSize.width,
      height: widget.canvasSize.height,
      child: Stack(
        children: [
          // Capa de fondo (cuaderno o cuerpo base)
          if (widget.backgroundWidget != null) widget.backgroundWidget!,

          // Capa de captura de gestos y dibujo
          GestureDetector(
            onPanStart: (details) {
              if (_currentTool == CanvasTool.pencil) {
                setState(() {
                  _activeLine = DrawnLine(
                    points: [details.localPosition],
                    color: _currentColor,
                    strokeWidth: _currentStrokeWidth,
                  );
                  _lines.add(_activeLine!);
                });
              } else if (_currentTool == CanvasTool.bucket) {
                _handleFloodFillTap(details.localPosition);
              }
            },
            onPanUpdate: (details) {
              if (_currentTool == CanvasTool.pencil && _activeLine != null) {
                setState(() {
                  _activeLine!.points.add(details.localPosition);
                });
              }
            },
            onPanEnd: (details) {
              if (_currentTool == CanvasTool.pencil) {
                _activeLine = null;
              }
            },
            onTapUp: (details) {
              if (_currentTool == CanvasTool.bucket) {
                _handleFloodFillTap(details.localPosition);
              }
            },
            child: CustomPaint(
              size: widget.canvasSize,
              painter: _CanvasPainter(
                lines: _lines,
                rasterLayer: _rasterLayer,
              ),
            ),
          ),

          // Capa superpuesta (por ejemplo, los Ojos arrastrables)
          if (widget.overlayWidget != null) widget.overlayWidget!,
        ],
      ),
    );
  }
}

class _CanvasPainter extends CustomPainter {
  final List<DrawnLine> lines;
  final ui.Image? rasterLayer;

  _CanvasPainter({
    required this.lines,
    this.rasterLayer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (rasterLayer != null) {
      canvas.drawImage(rasterLayer!, Offset.zero, Paint());
    }

    for (final line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = line.strokeWidth
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < line.points.length - 1; i++) {
        canvas.drawLine(line.points[i], line.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPainter oldDelegate) => true;
}
