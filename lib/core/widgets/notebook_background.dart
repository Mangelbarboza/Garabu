import 'package:flutter/material.dart';
import '../theme/garabu_theme.dart';

class NotebookBackground extends StatelessWidget {
  final Widget? child;
  final double lineSpacing;
  final bool showMargin;

  const NotebookBackground({
    super.key,
    this.child,
    this.lineSpacing = 28.0,
    this.showMargin = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NotebookPaperPainter(
        lineSpacing: lineSpacing,
        showMargin: showMargin,
      ),
      child: child,
    );
  }
}

class _NotebookPaperPainter extends CustomPainter {
  final double lineSpacing;
  final bool showMargin;

  _NotebookPaperPainter({
    required this.lineSpacing,
    required this.showMargin,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Fondo de papel cálido
    final bgPaint = Paint()..color = GarabuTheme.paperWhite;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Líneas horizontales de cuaderno
    final linePaint = Paint()
      ..color = GarabuTheme.notebookLine
      ..strokeWidth = 1.0;

    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Margen vertical suave a la izquierda (típico de libreta)
    if (showMargin) {
      final marginPaint = Paint()
        ..color = GarabuTheme.notebookMargin
        ..strokeWidth = 1.2;
      canvas.drawLine(
        const Offset(36, 0),
        Offset(36, size.height),
        marginPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NotebookPaperPainter oldDelegate) {
    return oldDelegate.lineSpacing != lineSpacing ||
        oldDelegate.showMargin != showMargin;
  }
}
