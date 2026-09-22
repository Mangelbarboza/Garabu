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

    test('GarmentItem soporta escala y rotacion persistentes', () {
      final now = DateTime.now();
      final garment = GarmentItem(
        id: 'g_transform',
        name: 'Lentes Cool',
        imageUrl: 'lentes_img',
        createdAt: now,
        offsetX: 12.5,
        offsetY: -8.0,
        scale: 1.45,
        rotation: 0.35,
      );

      final map = garment.toMap();
      final recreated = GarmentItem.fromMap(map);

      expect(recreated.id, 'g_transform');
      expect(recreated.scale, 1.45);
      expect(recreated.rotation, 0.35);
      expect(recreated.offsetX, 12.5);
      expect(recreated.offsetY, -8.0);
    });

    test('PetModel calcula energia continua usando energyValue', () {
      final now = DateTime.now();
      final petAwake = PetModel(
        id: 'pet_energy',
        coupleId: 'cpl_1',
        name: 'Garabu Dormilon',
        bodyImageUrl: 'url',
        eyesConfig: const EyesConfig(
          leftEye: RelativePoint(x: 0.4, y: 0.4),
          rightEye: RelativePoint(x: 0.6, y: 0.4),
        ),
        isSleeping: false,
        energyValue: 0.85,
        lastSleptAt: now.subtract(const Duration(hours: 2)), // 2 horas despierto
        createdAt: now,
        updatedAt: now,
      );

      // Decae 5% por hora despierto: 0.85 - (2 * 0.05) = 0.75
      expect(petAwake.energy, closeTo(0.75, 0.01));

      final petSleeping = petAwake.copyWith(
        isSleeping: true,
        energyValue: 0.75,
        sleepStartedAt: now.subtract(const Duration(hours: 1)), // 1 hora dormido
      );

      // Sube 12.5% por hora dormido: 0.75 + (1 * 0.125) = 0.875
      expect(petSleeping.energy, closeTo(0.875, 0.01));

      final map = petSleeping.toMap();
      final fromMap = PetModel.fromMap(map, 'pet_energy');
      expect(fromMap.energyValue, 0.75);
      expect(fromMap.isSleeping, true);
    });

    test('CoupleModel serializa y deserializa activeTrivia y activePinturillo', () {
      final now = DateTime.now();
      final couple = CoupleModel(
        id: 'cpl_active_games',
        user1Id: 'u1',
        user1Name: 'Angel',
        user2Id: 'u2',
        user2Name: 'Maria',
        inviteCode: '777888',
        streak: 1,
        lastInteraction: now,
        status: 'ready',
        createdAt: now,
        activeTrivia: {
          'initiatorId': 'u1',
          'roundId': 'rnd_1',
          'user1Answers': [0, 1, 2, 0, 3],
        },
        activePinturillo: {
          'artistId': 'u1',
          'word': 'CORAZON',
          'category': 'Amor',
        },
      );

      final map = couple.toMap();
      final fromMap = CoupleModel.fromMap(map, 'cpl_active_games');

      expect(fromMap.activeTrivia?['initiatorId'], 'u1');
      expect(fromMap.activeTrivia?['roundId'], 'rnd_1');
      expect(fromMap.activePinturillo?['word'], 'CORAZON');
      expect(fromMap.activePinturillo?['category'], 'Amor');
    });

    test('CoupleModel gestiona interacciones individuales y presencia en linea', () {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final couple = CoupleModel(
        id: 'cpl_presence',
        user1Id: 'u1',
        user1Name: 'Angel',
        user2Id: 'u2',
        user2Name: 'Maria',
        inviteCode: '999888',
        streak: 4,
        lastInteraction: now,
        status: 'ready',
        user1LastInteractionDate: todayStr,
        user2LastInteractionDate: null,
        user1LastSeen: now.subtract(const Duration(seconds: 30)), // En línea (hace 30s)
        user2LastSeen: now.subtract(const Duration(minutes: 10)), // Desconectado (hace 10m)
        createdAt: now,
      );

      // Verificación de interacción individual de hoy
      expect(couple.hasUser1InteractedToday(now), true);
      expect(couple.hasUser2InteractedToday(now), false);
      expect(couple.hasBothInteractedToday(now), false);

      // Verificación de presencia en línea
      expect(couple.isUser1Online(now), true);
      expect(couple.isUser2Online(now), false);

      // Al interactuar u2 hoy
      final updated = couple.copyWith(
        user2LastInteractionDate: todayStr,
        user2LastSeen: now,
      );
      expect(updated.hasUser2InteractedToday(now), true);
      expect(updated.hasBothInteractedToday(now), true);
      expect(updated.isUser2Online(now), true);

      // Serialización y deserialización
      final map = updated.toMap();
      final fromMap = CoupleModel.fromMap(map, 'cpl_presence');
      expect(fromMap.user1LastInteractionDate, todayStr);
      expect(fromMap.user2LastInteractionDate, todayStr);
      expect(fromMap.hasBothInteractedToday(now), true);
      expect(fromMap.isUser1Online(now), true);
    });
  });
}
