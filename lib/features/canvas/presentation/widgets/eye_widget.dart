import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../../pet/domain/pet_model.dart';

class EyeWidget extends StatelessWidget {
  final double size;
  final Color color;
  final bool hasEyelashes;
  final bool isLeft;
  final double blinkProgress; // 0.0 = Abierto, 1.0 = Cerrado
  final bool isHappy; // Ojos achinados felices estilo kawaii (^_^)

  const EyeWidget({
    super.key,
    this.size = 28.0,
    required this.color,
    this.hasEyelashes = false,
    this.isLeft = true,
    this.blinkProgress = 0.0,
    this.isHappy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size + (hasEyelashes ? 8 : 0),
      child: CustomPaint(
        painter: _EyePainter(
          color: color,
          hasEyelashes: hasEyelashes,
          isLeft: isLeft,
          blinkProgress: blinkProgress,
          isHappy: isHappy,
        ),
      ),
    );
  }
}

class _EyePainter extends CustomPainter {
  final Color color;
  final bool hasEyelashes;
  final bool isLeft;
  final double blinkProgress;
  final bool isHappy;

  _EyePainter({
    required this.color,
    required this.hasEyelashes,
    required this.isLeft,
    required this.blinkProgress,
    required this.isHappy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final eyeDiameter = size.width;
    final eyeCenter = Offset(
      eyeDiameter / 2,
      hasEyelashes ? (size.height - eyeDiameter / 2) : (size.height / 2),
    );

    // Si está achinado de felicidad (^_^) o totalmente cerrado por parpadeo
    if (isHappy || blinkProgress >= 0.85) {
      final linePaint = Paint()
        ..color = const Color(0xFF2C2420)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round;

      final path = Path();
      if (isHappy) {
        // Arco hacia arriba (feliz)
        path.moveTo(eyeCenter.dx - eyeDiameter * 0.45, eyeCenter.dy + 2);
        path.quadraticBezierTo(
          eyeCenter.dx,
          eyeCenter.dy - eyeDiameter * 0.4,
          eyeCenter.dx + eyeDiameter * 0.45,
          eyeCenter.dy + 2,
        );
      } else {
        // Arco suave hacia abajo (parpadeo cerrado)
        path.moveTo(eyeCenter.dx - eyeDiameter * 0.45, eyeCenter.dy - 2);
        path.quadraticBezierTo(
          eyeCenter.dx,
          eyeCenter.dy + eyeDiameter * 0.35,
          eyeCenter.dx + eyeDiameter * 0.45,
          eyeCenter.dy - 2,
        );
      }
      canvas.drawPath(path, linePaint);

      // Pestañas cuando está cerrado
      if (hasEyelashes) {
        final lashPaint = Paint()
          ..color = const Color(0xFF2C2420)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeCap = StrokeCap.round;

        final midX = eyeCenter.dx;
        final midY = eyeCenter.dy + (isHappy ? -eyeDiameter * 0.2 : eyeDiameter * 0.2);
        canvas.drawLine(Offset(midX - 5, midY), Offset(midX - 9, midY - 4), lashPaint);
        canvas.drawLine(Offset(midX, midY), Offset(midX, midY - 5), lashPaint);
        canvas.drawLine(Offset(midX + 5, midY), Offset(midX + 9, midY - 4), lashPaint);
      }
      return;
    }

    // Escala vertical para parpadeo fluido
    final scaleY = (1.0 - (blinkProgress * 0.85)).clamp(0.15, 1.0);

    canvas.save();
    canvas.translate(eyeCenter.dx, eyeCenter.dy);
    canvas.scale(1.0, scaleY);
    canvas.translate(-eyeCenter.dx, -eyeCenter.dy);

    // Fondo blanco del globo ocular
    final scleraPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(eyeCenter, eyeDiameter / 2, scleraPaint);

    // Borde exterior
    final borderPaint = Paint()
      ..color = const Color(0xFF2C2420)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(eyeCenter, eyeDiameter / 2, borderPaint);

    // Iris del color seleccionado
    final irisRadius = eyeDiameter * 0.35;
    final irisPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(eyeCenter, irisRadius, irisPaint);

    // Pupila oscura profunda
    final pupilPaint = Paint()
      ..color = const Color(0xFF151210)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(eyeCenter, irisRadius * 0.55, pupilPaint);

    // Brillo / Reflejo de luz
    final shinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      eyeCenter + Offset(-irisRadius * 0.3, -irisRadius * 0.3),
      irisRadius * 0.28,
      shinePaint,
    );

    canvas.restore();

    // Pestañas normales si el ojo está abierto
    if (hasEyelashes) {
      final lashPaint = Paint()
        ..color = const Color(0xFF2C2420)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round;

      final topY = eyeCenter.dy - ((eyeDiameter / 2) * scaleY);
      final midX = eyeCenter.dx;

      if (isLeft) {
        canvas.drawLine(Offset(midX - 4, topY + 2), Offset(midX - 9, topY - 5), lashPaint);
        canvas.drawLine(Offset(midX, topY), Offset(midX - 1, topY - 7), lashPaint);
        canvas.drawLine(Offset(midX + 4, topY + 2), Offset(midX + 6, topY - 5), lashPaint);
      } else {
        canvas.drawLine(Offset(midX - 4, topY + 2), Offset(midX - 6, topY - 5), lashPaint);
        canvas.drawLine(Offset(midX, topY), Offset(midX + 1, topY - 7), lashPaint);
        canvas.drawLine(Offset(midX + 4, topY + 2), Offset(midX + 9, topY - 5), lashPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EyePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.hasEyelashes != hasEyelashes ||
        oldDelegate.isLeft != isLeft ||
        oldDelegate.blinkProgress != blinkProgress ||
        oldDelegate.isHappy != isHappy;
  }
}

/// Widget para posicionar y arrastrar un ojo sobre el canvas interactivo
class DraggableEye extends StatelessWidget {
  final RelativePoint position;
  final Size canvasSize;
  final Color color;
  final bool hasEyelashes;
  final bool isLeft;
  final ValueChanged<RelativePoint> onPositionChanged;

  const DraggableEye({
    super.key,
    required this.position,
    required this.canvasSize,
    required this.color,
    required this.hasEyelashes,
    required this.isLeft,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    const eyeSize = 32.0;
    final pixelX = (position.x * canvasSize.width) - (eyeSize / 2);
    final pixelY = (position.y * canvasSize.height) - (eyeSize / 2);

    return Positioned(
      left: pixelX,
      top: pixelY,
      child: GestureDetector(
        onPanUpdate: (details) {
          final newPixelX = pixelX + details.delta.dx + (eyeSize / 2);
          final newPixelY = pixelY + details.delta.dy + (eyeSize / 2);

          final clampedX = (newPixelX / canvasSize.width).clamp(0.08, 0.92);
          final clampedY = (newPixelY / canvasSize.height).clamp(0.08, 0.92);

          onPositionChanged(RelativePoint(x: clampedX, y: clampedY));
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.brown.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: EyeWidget(
            size: eyeSize,
            color: color,
            hasEyelashes: hasEyelashes,
            isLeft: isLeft,
          ),
        ),
      ),
    );
  }
}

/// Widget para renderizar un ojo estático con coordenadas relativas fijas
class StaticEyeOverlay extends StatelessWidget {
  final RelativePoint position;
  final Size canvasSize;
  final Color color;
  final bool hasEyelashes;
  final bool isLeft;
  final double eyeSize;
  final double blinkProgress;
  final bool isHappy;

  const StaticEyeOverlay({
    super.key,
    required this.position,
    required this.canvasSize,
    required this.color,
    required this.hasEyelashes,
    required this.isLeft,
    this.eyeSize = 30.0,
    this.blinkProgress = 0.0,
    this.isHappy = false,
  });

  @override
  Widget build(BuildContext context) {
    final pixelX = (position.x * canvasSize.width) - (eyeSize / 2);
    final pixelY = (position.y * canvasSize.height) - (eyeSize / 2);

    return Positioned(
      left: pixelX,
      top: pixelY,
      child: EyeWidget(
        size: eyeSize,
        color: color,
        hasEyelashes: hasEyelashes,
        isLeft: isLeft,
        blinkProgress: blinkProgress,
        isHappy: isHappy,
      ),
    );
  }
}

/// Widget animado para renderizar ojos que parpadean periódicamente y responden a felicidad
class BlinkingEyeOverlay extends StatefulWidget {
  final RelativePoint position;
  final Size canvasSize;
  final Color color;
  final bool hasEyelashes;
  final bool isLeft;
  final double eyeSize;
  final bool isHappy;

  const BlinkingEyeOverlay({
    super.key,
    required this.position,
    required this.canvasSize,
    required this.color,
    required this.hasEyelashes,
    required this.isLeft,
    this.eyeSize = 30.0,
    this.isHappy = false,
  });

  @override
  State<BlinkingEyeOverlay> createState() => _BlinkingEyeOverlayState();
}

class _BlinkingEyeOverlayState extends State<BlinkingEyeOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  Timer? _blinkTimer;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scheduleNextBlink();
  }

  void _scheduleNextBlink() {
    _blinkTimer?.cancel();
    // Parpadea entre 3 y 5.5 segundos de forma natural
    final delayMs = 3000 + _random.nextInt(2500);
    _blinkTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (!mounted) return;
      if (!widget.isHappy) {
        await _blinkController.forward();
        if (mounted) {
          await _blinkController.reverse();
        }
      }
      if (mounted) {
        _scheduleNextBlink();
      }
    });
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pixelX = (widget.position.x * widget.canvasSize.width) - (widget.eyeSize / 2);
    final pixelY = (widget.position.y * widget.canvasSize.height) - (widget.eyeSize / 2);

    return Positioned(
      left: pixelX,
      top: pixelY,
      child: AnimatedBuilder(
        animation: _blinkController,
        builder: (context, _) {
          return EyeWidget(
            size: widget.eyeSize,
            color: widget.color,
            hasEyelashes: widget.hasEyelashes,
            isLeft: widget.isLeft,
            blinkProgress: _blinkController.value,
            isHappy: widget.isHappy,
          );
        },
      ),
    );
  }
}

class MouthWidget extends StatelessWidget {
  final double size;
  final bool isOpen;

  const MouthWidget({
    super.key,
    this.size = 24.0,
    this.isOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.6,
      child: CustomPaint(
        painter: _MouthSmilePainter(isOpen: isOpen),
      ),
    );
  }
}

class _MouthSmilePainter extends CustomPainter {
  final bool isOpen;

  _MouthSmilePainter({this.isOpen = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF2C2420)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = isOpen ? PaintingStyle.fill : PaintingStyle.stroke;

    final path = Path();
    if (isOpen) {
      path.moveTo(size.width * 0.1, size.height * 0.2);
      path.quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.1,
        size.width * 0.9,
        size.height * 0.2,
      );
      path.close();
      canvas.drawPath(path, paint);

      final tonguePaint = Paint()
        ..color = const Color(0xFFFF8B94)
        ..style = PaintingStyle.fill;
      final tonguePath = Path();
      tonguePath.moveTo(size.width * 0.3, size.height * 0.55);
      tonguePath.quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.05,
        size.width * 0.7,
        size.height * 0.55,
      );
      tonguePath.close();
      canvas.drawPath(tonguePath, tonguePaint);
    } else {
      path.moveTo(size.width * 0.15, size.height * 0.3);
      path.quadraticBezierTo(
        size.width * 0.5,
        size.height * 0.9,
        size.width * 0.85,
        size.height * 0.3,
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MouthSmilePainter oldDelegate) =>
      oldDelegate.isOpen != isOpen;
}

/// Widget para posicionar y arrastrar la boca sobre el canvas interactivo
class DraggableMouth extends StatelessWidget {
  final RelativePoint position;
  final Size canvasSize;
  final ValueChanged<RelativePoint> onPositionChanged;

  const DraggableMouth({
    super.key,
    required this.position,
    required this.canvasSize,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    const mouthWidth = 36.0;
    const mouthHeight = 24.0;
    final pixelX = (position.x * canvasSize.width) - (mouthWidth / 2);
    final pixelY = (position.y * canvasSize.height) - (mouthHeight / 2);

    return Positioned(
      left: pixelX,
      top: pixelY,
      child: GestureDetector(
        onPanUpdate: (details) {
          final newPixelX = pixelX + details.delta.dx + (mouthWidth / 2);
          final newPixelY = pixelY + details.delta.dy + (mouthHeight / 2);

          final clampedX = (newPixelX / canvasSize.width).clamp(0.08, 0.92);
          final clampedY = (newPixelY / canvasSize.height).clamp(0.08, 0.92);

          onPositionChanged(RelativePoint(x: clampedX, y: clampedY));
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.brown.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const MouthWidget(size: 24.0),
        ),
      ),
    );
  }
}

/// Widget para renderizar la boca estática o animada
class StaticMouthOverlay extends StatelessWidget {
  final RelativePoint position;
  final Size canvasSize;
  final double size;
  final bool isOpen;

  const StaticMouthOverlay({
    super.key,
    required this.position,
    required this.canvasSize,
    this.size = 28.0,
    this.isOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final pixelX = (position.x * canvasSize.width) - (size / 2);
    final pixelY = (position.y * canvasSize.height) - (size * 0.3);

    return Positioned(
      left: pixelX,
      top: pixelY,
      child: MouthWidget(
        size: size,
        isOpen: isOpen,
      ),
    );
  }
}
