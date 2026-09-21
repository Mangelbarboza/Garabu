import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garabu/features/canvas/presentation/fruit_canvas_screen.dart';
import 'package:garabu/features/canvas/presentation/widgets/drawing_canvas.dart';

void main() {
  group('Interactive Feed & Drawing Canvas Tests', () {
    test('kAvailableFruits contiene exactamente las 6 frutas solicitadas', () {
      expect(kAvailableFruits.length, 6);
      final fruitKeys = kAvailableFruits.map((f) => f.key).toList();
      expect(fruitKeys, containsAll(['manzana', 'naranja', 'pera', 'pina', 'banano', 'uva']));
    });

    testWidgets('DrawingCanvas invoca onDrawingStarted al iniciar trazo', (tester) async {
      bool drawingStarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DrawingCanvas(
              canvasSize: const Size(200, 200),
              onDrawingStarted: () {
                drawingStarted = true;
              },
            ),
          ),
        ),
      );

      expect(drawingStarted, false);

      // Simular trazo de dibujo
      await tester.drag(find.byType(DrawingCanvas), const Offset(40, 40));
      await tester.pump();
      expect(drawingStarted, true);
    });
  });
}
