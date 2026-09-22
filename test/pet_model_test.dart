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

    test('CoupleModel maneja slots de personaje correctamente', () {
      final now = DateTime.now();
      final couple = CoupleModel(
        id: 'cpl_1',
        user1Id: 'u1',
        user1Name: 'Angel',
        user2Id: 'u2',
        user2Name: 'Maria',
        inviteCode: '123456',
        streak: 2,
        lastInteraction: now,
        petId: 'pet_user1',
        user1PetId: 'pet_user1',
        user2PetId: 'pet_user2',
        activePetId: 'pet_user1',
        status: 'ready',
        createdAt: now,
      );

      expect(couple.resolvedUser1PetId, 'pet_user1');
      expect(couple.resolvedActivePetId, 'pet_user1');

      final switched = couple.copyWith(activePetId: 'pet_user2');
      expect(switched.resolvedActivePetId, 'pet_user2');

      final map = switched.toMap();
      final fromMap = CoupleModel.fromMap(map, 'cpl_1');
      expect(fromMap.user1PetId, 'pet_user1');
      expect(fromMap.user2PetId, 'pet_user2');
      expect(fromMap.activePetId, 'pet_user2');
    });

    test('PetModel maneja niveles y experiencia acumulada correctamente', () {
      final now = DateTime.now();
      final petLvl1 = PetModel(
        id: 'pet_exp',
        coupleId: 'cpl_1',
        name: 'Garabu',
        bodyImageUrl: 'url',
        eyesConfig: const EyesConfig(
          leftEye: RelativePoint(x: 0.4, y: 0.4),
          rightEye: RelativePoint(x: 0.6, y: 0.4),
        ),
        level: 1,
        experience: 50,
        createdAt: now,
        updatedAt: now,
      );

      expect(petLvl1.level, 1);
      expect(petLvl1.experience, 50);
      expect(petLvl1.maxExperienceForLevel, 100);
      expect(petLvl1.levelProgress, 0.5);

      final petLvl3 = petLvl1.copyWith(level: 3, experience: 90);
      expect(petLvl3.maxExperienceForLevel, 300); // 3 * 100
      expect((petLvl3.levelProgress * 100).round(), 30);
    });

    test('PetModel soporta equipar hasta 5 prendas simultáneas con offsets', () {
      final now = DateTime.now();
      final pet = PetModel(
        id: 'pet_closet_5',
        coupleId: 'cpl_1',
        name: 'Garabu Fashion',
        bodyImageUrl: 'url',
        eyesConfig: const EyesConfig(
          leftEye: RelativePoint(x: 0.4, y: 0.4),
          rightEye: RelativePoint(x: 0.6, y: 0.4),
        ),
        equippedGarmentIds: ['g1', 'g2', 'g3', 'g4', 'g5'],
        createdAt: now,
        updatedAt: now,
        closet: List.generate(
          5,
          (i) => GarmentItem(
            id: 'g${i + 1}',
            name: 'Prenda ${i + 1}',
            imageUrl: 'cloth_$i',
            createdAt: now,
            offsetX: i * 5.0,
            offsetY: -i * 10.0,
          ),
        ),
      );

      expect(pet.resolvedEquippedGarmentIds.length, 5);
      expect(pet.resolvedEquippedGarmentIds, ['g1', 'g2', 'g3', 'g4', 'g5']);

      final map = pet.toMap();
      final fromMap = PetModel.fromMap(map, 'pet_closet_5');
      expect(fromMap.resolvedEquippedGarmentIds.length, 5);
      expect(fromMap.closet[2].offsetY, -20.0);
    });

    test('CoupleModel maneja records de minijuegos para ambos usuarios', () {
      final now = DateTime.now();
      final couple = CoupleModel(
        id: 'cpl_records',
        user1Id: 'u1',
        user1Name: 'Angel',
        user2Id: 'u2',
        user2Name: 'Maria',
        inviteCode: '112233',
        streak: 3,
        lastInteraction: now,
        status: 'ready',
        createdAt: now,
        gameRecords: {
          'atrapa_garabutos_u1': 140,
          'atrapa_garabutos_u2': 180,
          'trivia_pareja_u1': 120,
        },
      );

      expect(couple.gameRecords['atrapa_garabutos_u1'], 140);
      expect(couple.gameRecords['atrapa_garabutos_u2'], 180);
      expect(couple.gameRecords['trivia_pareja_u1'], 120);

      final map = couple.toMap();
      final fromMap = CoupleModel.fromMap(map, 'cpl_records');
      expect(fromMap.gameRecords['atrapa_garabutos_u2'], 180);
    });
  });
}
