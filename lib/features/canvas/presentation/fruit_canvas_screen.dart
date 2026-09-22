import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/garabu_theme.dart';
import '../../../core/utils/flood_fill.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/notebook_background.dart';
import '../../pet/data/pet_repository.dart';
import '../../pet/domain/pet_model.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/canvas_toolbar.dart';

class FruitInfo {
  final String key;
  final String name;
  final Color color;
  final int price;

  const FruitInfo({
    required this.key,
    required this.name,
    required this.color,
    this.price = 10,
  });
}

const List<FruitInfo> kAvailableFruits = [
  FruitInfo(key: 'agua', name: 'Agua', color: Color(0xFF29B6F6), price: 5),
  FruitInfo(key: 'banano', name: 'Banano', color: Color(0xFFFBC02D), price: 8),
  FruitInfo(key: 'manzana', name: 'Manzana', color: Color(0xFFE53935), price: 10),
  FruitInfo(key: 'pera', name: 'Pera', color: Color(0xFF7CB342), price: 12),
  FruitInfo(key: 'naranja', name: 'Naranja', color: Color(0xFFFB8C00), price: 15),
  FruitInfo(key: 'uva', name: 'Uva', color: Color(0xFF8E24AA), price: 20),
  FruitInfo(key: 'pina', name: 'Piña', color: Color(0xFFFDD835), price: 25),
];

class FruitCanvasScreen extends ConsumerStatefulWidget {
  final PetModel pet;
  final FruitInfo fruit;

  const FruitCanvasScreen({
    super.key,
    required this.pet,
    required this.fruit,
  });

  @override
  ConsumerState<FruitCanvasScreen> createState() => _FruitCanvasScreenState();
}

class _FruitCanvasScreenState extends ConsumerState<FruitCanvasScreen> {
  DrawingCanvasController? _canvasController;
  CanvasTool _selectedTool = CanvasTool.pencil;
  Color _selectedDrawColor = const Color(0xFFE53935);
  double _selectedStrokeWidth = 4.0;
  BucketPower _selectedBucketPower = BucketPower.medium;
  Uint8List? _existingFruitBytes;
  bool _showStencil = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    // Si la fruta ya fue dibujada previamente, cargarla en el lienzo para EDITARLA
    final existingUrl = widget.pet.drawnFruits[widget.fruit.key];
    if (existingUrl != null && existingUrl.isNotEmpty) {
      _existingFruitBytes = decodeDataUri(existingUrl);
      _showStencil = false;
    }

    // Seleccionar color inicial sugerido según la fruta elegida
    switch (widget.fruit.key) {
      case 'manzana':
        _selectedDrawColor = const Color(0xFFE53935);
        break;
      case 'naranja':
        _selectedDrawColor = const Color(0xFFFF7043);
        break;
      case 'pera':
        _selectedDrawColor = const Color(0xFF43A047);
        break;
      case 'pina':
        _selectedDrawColor = const Color(0xFFFFD54F);
        break;
      case 'banano':
        _selectedDrawColor = const Color(0xFFFFD54F);
        break;
      case 'uva':
        _selectedDrawColor = const Color(0xFF7E57C2);
        break;
    }
  }

  Future<void> _saveFruit() async {
    if (_canvasController == null || _isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final fruitBytes = await _canvasController!.exportTransparentPng();
      if (fruitBytes == null) {
        throw Exception('No se pudo generar el dibujo de la fruta.');
      }

      final petRepo = ref.read(petRepositoryProvider);
      await petRepo.saveDrawnFruit(
        petId: widget.pet.id,
        coupleId: widget.pet.coupleId,
        fruitKey: widget.fruit.key,
        fruitBytes: fruitBytes,
      );
      // Asegurar al menos 1 unidad en inventario para usar de inmediato
      await petRepo.buyFruit(
        petId: widget.pet.id,
        fruitKey: widget.fruit.key,
        quantity: 1,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡${widget.fruit.name} dibujada y lista para alimentarlo!'),
            backgroundColor: GarabuTheme.primaryBrown,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar fruta: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final availableHeight = size.height - 280.0;
    final availableWidth = size.width - 32.0;
    final canvasDimension = min(availableHeight, availableWidth).clamp(220.0, 420.0);
    final canvasSize = Size(canvasDimension, canvasDimension);

    final isEditing = widget.pet.drawnFruits.containsKey(widget.fruit.key);

    return Scaffold(
      backgroundColor: GarabuTheme.background,
      appBar: AppBar(
        title: Text(isEditing
            ? 'Editar: ${widget.fruit.name}'
            : 'Dibuja: ${widget.fruit.name}'),
        actions: [
          IconButton(
            tooltip: _showStencil ? 'Ocultar silueta guía' : 'Mostrar silueta guía',
            icon: Icon(
              _showStencil ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: GarabuTheme.primaryBrown,
            ),
            onPressed: () => setState(() => _showStencil = !_showStencil),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _isExporting ? null : _saveFruit,
              icon: _isExporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: GarabuTheme.primaryBrown),
                    )
                  : const Icon(Icons.check_circle_outline, color: GarabuTheme.primaryBrown),
              label: const Text(
                'Guardar',
                style: TextStyle(
                  color: GarabuTheme.primaryBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Indicador / Instrucción
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: GarabuTheme.paperWhite,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.gesture_rounded, size: 16, color: GarabuTheme.primaryBrown),
                  const SizedBox(width: 8),
                  Text(
                    isEditing
                        ? 'Rediseña la ${widget.fruit.name.toLowerCase()} a tu gusto'
                        : 'Calca la silueta de la ${widget.fruit.name.toLowerCase()} o crea tu versión única',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                ],
              ),
            ),

            // Canvas de Dibujo
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Container(
                      width: canvasSize.width,
                      height: canvasSize.height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GarabuTheme.warmSand, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: DrawingCanvas(
                        canvasSize: canvasSize,
                        initialImageBytes: _existingFruitBytes,
                        onDrawingStarted: () {
                          // Ocultar la silueta sombra de la fruta apenas se comienza a dibujar
                          if (_showStencil) {
                            setState(() => _showStencil = false);
                          }
                        },
                        onControllerReady: (c) {
                          _canvasController = c;
                          if (_existingFruitBytes != null) {
                            c.loadRasterImage(_existingFruitBytes!);
                          }
                          _canvasController?.setColor(_selectedDrawColor);
                        },
                        onColorPicked: (color) {
                          setState(() => _selectedDrawColor = color);
                        },
                        backgroundWidget: Stack(
                          children: [
                            const NotebookBackground(),
                            if (_showStencil)
                              CustomPaint(
                                size: canvasSize,
                                painter: _FruitStencilPainter(fruitKey: widget.fruit.key),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Barra de herramientas completa
            CanvasToolbar(
              selectedTool: _selectedTool,
              selectedColor: _selectedDrawColor,
              selectedStrokeWidth: _selectedStrokeWidth,
              selectedBucketPower: _selectedBucketPower,
              onToolChanged: (tool) {
                setState(() => _selectedTool = tool);
                _canvasController?.setTool(tool);
              },
              onColorChanged: (color) {
                setState(() => _selectedDrawColor = color);
                _canvasController?.setColor(color);
              },
              onStrokeWidthChanged: (width) {
                setState(() => _selectedStrokeWidth = width);
                _canvasController?.setStrokeWidth(width);
              },
              onBucketPowerChanged: (power) {
                setState(() => _selectedBucketPower = power);
                _canvasController?.setBucketPower(power);
              },
              onUndo: () => _canvasController?.undo(),
              onClear: () => _canvasController?.clear(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Painter de la silueta / shadow dibujo para que la pareja pueda calcar la fruta
class _FruitStencilPainter extends CustomPainter {
  final String fruitKey;

  _FruitStencilPainter({required this.fruitKey});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    final guidePaint = Paint()
      ..color = const Color(0x3D2C2420) // Tinta suave semitransparente estilo boceto a lápiz
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final leafPaint = Paint()
      ..color = const Color(0x3543A047)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    switch (fruitKey) {
      case 'manzana':
        _drawAppleStencil(canvas, center, min(w, h) * 0.35, guidePaint, leafPaint);
        break;
      case 'naranja':
        _drawOrangeStencil(canvas, center, min(w, h) * 0.35, guidePaint, leafPaint);
        break;
      case 'pera':
        _drawPearStencil(canvas, center, min(w, h) * 0.35, guidePaint, leafPaint);
        break;
      case 'pina':
        _drawPineappleStencil(canvas, center, min(w, h) * 0.35, guidePaint, leafPaint);
        break;
      case 'banano':
        _drawBananaStencil(canvas, center, min(w, h) * 0.35, guidePaint);
        break;
      case 'uva':
        _drawGrapeStencil(canvas, center, min(w, h) * 0.35, guidePaint, leafPaint);
        break;
      case 'agua':
        _drawWaterStencil(canvas, center, min(w, h) * 0.35, guidePaint);
        break;
    }
  }

  void _drawWaterStencil(Canvas canvas, Offset center, double r, Paint guidePaint) {
    final glass = Path();
    glass.moveTo(center.dx - r * 0.55, center.dy - r * 0.8);
    glass.lineTo(center.dx + r * 0.55, center.dy - r * 0.8);
    glass.lineTo(center.dx + r * 0.4, center.dy + r * 0.8);
    glass.quadraticBezierTo(center.dx, center.dy + r * 0.88, center.dx - r * 0.4, center.dy + r * 0.8);
    glass.close();
    canvas.drawPath(glass, guidePaint);

    final waterLevel = Path();
    waterLevel.moveTo(center.dx - r * 0.48, center.dy - r * 0.2);
    waterLevel.quadraticBezierTo(center.dx, center.dy - r * 0.1, center.dx + r * 0.48, center.dy - r * 0.2);
    canvas.drawPath(waterLevel, guidePaint);

    canvas.drawCircle(center + Offset(0, r * 0.25), r * 0.12, guidePaint);
  }

  void _drawAppleStencil(Canvas canvas, Offset center, double r, Paint guidePaint, Paint leafPaint) {
    final path = Path();
    // Silueta de manzana con hendidura superior e inferior
    path.moveTo(center.dx, center.dy - r * 0.8);
    path.cubicTo(
      center.dx + r * 1.1, center.dy - r * 1.0,
      center.dx + r * 1.2, center.dy + r * 0.7,
      center.dx, center.dy + r * 0.9,
    );
    path.cubicTo(
      center.dx - r * 1.2, center.dy + r * 0.7,
      center.dx - r * 1.1, center.dy - r * 1.0,
      center.dx, center.dy - r * 0.8,
    );
    canvas.drawPath(path, guidePaint);

    // Tallo
    final stem = Path()
      ..moveTo(center.dx, center.dy - r * 0.8)
      ..quadraticBezierTo(center.dx + 4, center.dy - r * 1.2, center.dx + 12, center.dy - r * 1.25);
    canvas.drawPath(stem, guidePaint);

    // Hoja
    final leaf = Path()
      ..moveTo(center.dx + 5, center.dy - r * 0.95)
      ..quadraticBezierTo(center.dx + r * 0.45, center.dy - r * 1.15, center.dx + r * 0.5, center.dy - r * 0.9)
      ..quadraticBezierTo(center.dx + r * 0.25, center.dy - r * 0.8, center.dx + 5, center.dy - r * 0.95);
    canvas.drawPath(leaf, leafPaint);
  }

  void _drawOrangeStencil(Canvas canvas, Offset center, double r, Paint guidePaint, Paint leafPaint) {
    // Círculo de la naranja
    canvas.drawCircle(center, r * 0.95, guidePaint);

    // Tallo y hoja superior
    final stem = Path()
      ..moveTo(center.dx, center.dy - r * 0.95)
      ..lineTo(center.dx, center.dy - r * 1.15);
    canvas.drawPath(stem, guidePaint);

    final leaf = Path()
      ..moveTo(center.dx, center.dy - r * 1.05)
      ..quadraticBezierTo(center.dx + r * 0.4, center.dy - r * 1.25, center.dx + r * 0.45, center.dy - r * 1.0)
      ..quadraticBezierTo(center.dx + r * 0.2, center.dy - r * 0.95, center.dx, center.dy - r * 1.05);
    canvas.drawPath(leaf, leafPaint);

    // Puntos de textura de cáscara
    for (int i = 0; i < 6; i++) {
      final angle = i * (pi / 3);
      final dotOffset = center + Offset(cos(angle) * (r * 0.5), sin(angle) * (r * 0.5));
      canvas.drawCircle(dotOffset, 1.5, guidePaint);
    }
  }

  void _drawPearStencil(Canvas canvas, Offset center, double r, Paint guidePaint, Paint leafPaint) {
    final path = Path();
    // Pera: estrecha arriba, redonda y ancha abajo
    path.moveTo(center.dx, center.dy - r * 1.05);
    path.cubicTo(
      center.dx + r * 0.45, center.dy - r * 0.9,
      center.dx + r * 0.45, center.dy - r * 0.1,
      center.dx + r * 0.9, center.dy + r * 0.6,
    );
    path.cubicTo(
      center.dx + r * 0.7, center.dy + r * 1.1,
      center.dx - r * 0.7, center.dy + r * 1.1,
      center.dx - r * 0.9, center.dy + r * 0.6,
    );
    path.cubicTo(
      center.dx - r * 0.45, center.dy - r * 0.1,
      center.dx - r * 0.45, center.dy - r * 0.9,
      center.dx, center.dy - r * 1.05,
    );
    canvas.drawPath(path, guidePaint);

    // Tallo
    final stem = Path()
      ..moveTo(center.dx, center.dy - r * 1.05)
      ..quadraticBezierTo(center.dx - 6, center.dy - r * 1.3, center.dx - 10, center.dy - r * 1.35);
    canvas.drawPath(stem, guidePaint);

    // Hoja
    final leaf = Path()
      ..moveTo(center.dx - 4, center.dy - r * 1.2)
      ..quadraticBezierTo(center.dx + r * 0.35, center.dy - r * 1.35, center.dx + r * 0.4, center.dy - r * 1.1)
      ..quadraticBezierTo(center.dx + r * 0.2, center.dy - r * 1.05, center.dx - 4, center.dy - r * 1.2);
    canvas.drawPath(leaf, leafPaint);
  }

  void _drawPineappleStencil(Canvas canvas, Offset center, double r, Paint guidePaint, Paint leafPaint) {
    // Cuerpo ovalado de la piña
    final bodyRect = Rect.fromCenter(center: center + Offset(0, r * 0.2), width: r * 1.25, height: r * 1.45);
    canvas.drawOval(bodyRect, guidePaint);

    // Patrón en rombos (rejilla)
    final gridPath = Path();
    for (double i = -0.4; i <= 0.4; i += 0.3) {
      gridPath.moveTo(center.dx + r * i - r * 0.3, center.dy - r * 0.3);
      gridPath.lineTo(center.dx + r * i + r * 0.3, center.dy + r * 0.7);

      gridPath.moveTo(center.dx + r * i + r * 0.3, center.dy - r * 0.3);
      gridPath.lineTo(center.dx + r * i - r * 0.3, center.dy + r * 0.7);
    }
    canvas.drawPath(gridPath, guidePaint);

    // Corona de hojas espigadas arriba
    final topY = center.dy - r * 0.55;
    final crown = Path()
      ..moveTo(center.dx - r * 0.3, topY)
      ..lineTo(center.dx - r * 0.5, topY - r * 0.7)
      ..lineTo(center.dx - r * 0.15, topY - r * 0.4)
      ..lineTo(center.dx, topY - r * 0.85)
      ..lineTo(center.dx + r * 0.15, topY - r * 0.4)
      ..lineTo(center.dx + r * 0.5, topY - r * 0.7)
      ..lineTo(center.dx + r * 0.3, topY);
    canvas.drawPath(crown, leafPaint);
  }

  void _drawBananaStencil(Canvas canvas, Offset center, double r, Paint guidePaint) {
    final path = Path();
    // Plátano curvado
    path.moveTo(center.dx - r * 0.8, center.dy + r * 0.5);
    path.quadraticBezierTo(
      center.dx - r * 0.4, center.dy - r * 0.6,
      center.dx + r * 0.8, center.dy - r * 0.5,
    );
    // Punta derecha
    path.lineTo(center.dx + r * 0.88, center.dy - r * 0.45);
    // Curva interior
    path.quadraticBezierTo(
      center.dx - r * 0.2, center.dy - r * 0.25,
      center.dx - r * 0.75, center.dy + r * 0.6,
    );
    path.close();
    canvas.drawPath(path, guidePaint);

    // Línea de curvatura dorsal
    final ridge = Path()
      ..moveTo(center.dx - r * 0.75, center.dy + r * 0.55)
      ..quadraticBezierTo(
        center.dx - r * 0.3, center.dy - r * 0.45,
        center.dx + r * 0.8, center.dy - r * 0.48,
      );
    canvas.drawPath(ridge, guidePaint);

    // Tallo
    canvas.drawRect(
      Rect.fromLTWH(center.dx - r * 0.9, center.dy + r * 0.48, r * 0.15, r * 0.12),
      guidePaint,
    );
  }

  void _drawGrapeStencil(Canvas canvas, Offset center, double r, Paint guidePaint, Paint leafPaint) {
    final grapeR = r * 0.22;

    // Racimo de uvas en pirámide invertida
    // Fila 1 (arriba: 3 uvas)
    canvas.drawCircle(center + Offset(-grapeR * 1.8, -grapeR), grapeR, guidePaint);
    canvas.drawCircle(center + Offset(0, -grapeR * 1.1), grapeR, guidePaint);
    canvas.drawCircle(center + Offset(grapeR * 1.8, -grapeR), grapeR, guidePaint);

    // Fila 2 (centro: 2 uvas)
    canvas.drawCircle(center + Offset(-grapeR * 0.9, grapeR * 0.4), grapeR, guidePaint);
    canvas.drawCircle(center + Offset(grapeR * 0.9, grapeR * 0.4), grapeR, guidePaint);

    // Fila 3 (abajo: 1 uva)
    canvas.drawCircle(center + Offset(0, grapeR * 1.7), grapeR, guidePaint);

    // Tallo y ramita
    final stem = Path()
      ..moveTo(center.dx, center.dy - grapeR * 1.9)
      ..lineTo(center.dx, center.dy - grapeR * 2.8);
    canvas.drawPath(stem, guidePaint);

    // Hoja de parra
    final leaf = Path()
      ..moveTo(center.dx, center.dy - grapeR * 2.4)
      ..quadraticBezierTo(center.dx + r * 0.4, center.dy - grapeR * 3.2, center.dx + r * 0.45, center.dy - grapeR * 2.3)
      ..quadraticBezierTo(center.dx + r * 0.2, center.dy - grapeR * 2.1, center.dx, center.dy - grapeR * 2.4);
    canvas.drawPath(leaf, leafPaint);
  }

  @override
  bool shouldRepaint(covariant _FruitStencilPainter oldDelegate) =>
      oldDelegate.fruitKey != fruitKey;
}
