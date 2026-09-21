import 'package:flutter_test/flutter_test.dart';
import 'package:garabu/features/pet/domain/pet_model.dart';
import 'package:garabu/features/lobby/domain/couple_model.dart';

void main() {
  group('Pet & Couple Models Tests', () {
    test('EyesConfig serializa y deserializa coordenadas relativas correctamente', () {
      const config = EyesConfig(
        leftEye: RelativePoint(x: 0.35, y: 0.40),
        rightEye: RelativePoint(x: 0.65, y: 0.40),
        color: 0xFF123456,
        hasEyelashes: true,
      );

      final map = config.toMap();
      final recreated = EyesConfig.fromMap(map);

      expect(recreated.leftEye.x, 0.35);
      expect(recreated.leftEye.y, 0.40);
      expect(recreated.rightEye.x, 0.65);
      expect(recreated.rightEye.y, 0.40);
      expect(recreated.color, 0xFF123456);
      expect(recreated.hasEyelashes, true);
    });

    test('CoupleModel maneja la racha y estados correctamente', () {
      final now = DateTime.now();
      final couple = CoupleModel(
        id: 'cpl_1',
        user1Id: 'u1',
        user1Name: 'Angel',
        inviteCode: '839201',
        streak: 5,
        lastInteraction: now,
        status: 'waiting_partner',
        createdAt: now,
      );

      final updated = couple.copyWith(
        user2Id: 'u2',
        user2Name: 'Pareja',
        status: 'drawing_body',
      );

      expect(updated.user2Name, 'Pareja');
      expect(updated.status, 'drawing_body');
      expect(updated.streak, 5);
    });
  });
}
