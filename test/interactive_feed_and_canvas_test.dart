import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garabu/features/canvas/presentation/fruit_canvas_screen.dart';
import 'package:garabu/features/canvas/presentation/widgets/drawing_canvas.dart';
import 'package:garabu/features/pet/domain/pet_model.dart';

void main() {
  group('Interactive Feed & Drawing Canvas Tests', () {
    test('kAvailableFruits contiene exactamente las 6 frutas solicitadas', () {
      expect(kAvailableFruits.length, 6);
      final fruitKeys = kAvailableFruits.map((f) => f.key).toList();
      expect(fruitKeys, containsAll(['manzana', 'naranja', 'pera', 'pina', 'banano', 'uva']));
    });

    test('EyesConfig resolvedMouth calcula default y respeta mouth personalizado', () {
      const configWithDefault = EyesConfig(
        leftEye: RelativePoint(x: 0.4, y: 0.4),
        rightEye: RelativePoint(x: 0.6, y: 0.4),
      );
      expect(configWithDefault.resolvedMouth.x, 0.5);
      expect(configWithDefault.resolvedMouth.y, closeTo(0.48, 0.01));

      const configWithCustom = EyesConfig(
        leftEye: RelativePoint(x: 0.4, y: 0.4),
        rightEye: RelativePoint(x: 0.6, y: 0.4),
        mouth: RelativePoint(x: 0.52, y: 0.55),
      );
      expect(configWithCustom.resolvedMouth.x, 0.52);
      expect(configWithCustom.resolvedMouth.y, 0.55);
    });

    test('PetModel serializa y deserializa foodInventory y mouth correctamente', () {
      final pet = PetModel(
        id: 'test_pet',
        coupleId: 'couple_1',
        name: 'Garabito',
        bodyImageUrl: 'http://example.com/body.png',
        eyesConfig: const EyesConfig(
          leftEye: RelativePoint(x: 0.35, y: 0.4),
          rightEye: RelativePoint(x: 0.65, y: 0.4),
          mouth: RelativePoint(x: 0.5, y: 0.52),
        ),
        foodInventory: {'manzana': 3, 'uva': 1},
        lastPettedAt: DateTime(2026, 9, 21, 12, 0),
        createdAt: DateTime(2026, 9, 21),
        updatedAt: DateTime(2026, 9, 21),
      );

      final map = pet.toMap();
      final fromMapPet = PetModel.fromMap(map, 'test_pet');

      expect(fromMapPet.eyesConfig.mouth?.x, 0.5);
      expect(fromMapPet.eyesConfig.mouth?.y, 0.52);
      expect(fromMapPet.foodInventory['manzana'], 3);
      expect(fromMapPet.foodInventory['uva'], 1);
      expect(fromMapPet.lastPettedAt, isNotNull);
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
