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

    test('PetModel maneja clóset de 5 slots y frutas dibujadas', () {
      final now = DateTime.now();
      final pet = PetModel(
        id: 'pet_1',
        coupleId: 'cpl_1',
        name: 'Garabito',
        bodyImageUrl: 'data:image/png;base64,body',
        clothesImageUrl: 'data:image/png;base64,cloth1',
        eyesConfig: const EyesConfig(
          leftEye: RelativePoint(x: 0.4, y: 0.4),
          rightEye: RelativePoint(x: 0.6, y: 0.4),
        ),
        closet: [
          GarmentItem(
            id: 'g1',
            name: 'Sombrero',
            imageUrl: 'data:image/png;base64,hat',
            createdAt: now,
          ),
        ],
        activeGarmentId: 'g1',
        drawnFruits: {
          'manzana': 'data:image/png;base64,apple',
          'banano': 'data:image/png;base64,banana',
        },
        createdAt: now,
        updatedAt: now,
      );

      final map = pet.toMap();
      final fromMap = PetModel.fromMap(map, 'pet_1');

      expect(fromMap.closet.length, 1);
      expect(fromMap.closet.first.name, 'Sombrero');
      expect(fromMap.activeGarmentId, 'g1');
      expect(fromMap.drawnFruits.length, 2);
      expect(fromMap.drawnFruits['manzana'], 'data:image/png;base64,apple');
      expect(fromMap.drawnFruits['banano'], 'data:image/png;base64,banana');
    });

    test('PetModel migra automáticamente primera prenda a slot 1 si closet está vacío', () {
      final rawMap = {
        'coupleId': 'cpl_1',
        'name': 'Bicho',
        'bodyImageUrl': 'data:image/png;base64,body',
        'clothesImageUrl': 'data:image/png;base64,first_garment',
        'eyesConfig': {
          'leftEye': {'x': 0.4, 'y': 0.4},
          'rightEye': {'x': 0.6, 'y': 0.4},
        },
      };

      final pet = PetModel.fromMap(rawMap, 'pet_2');

      expect(pet.closet.length, 1);
      expect(pet.closet.first.id, 'initial_garment');
      expect(pet.closet.first.imageUrl, 'data:image/png;base64,first_garment');
      expect(pet.activeGarmentId, 'initial_garment');
    });
  });
}
