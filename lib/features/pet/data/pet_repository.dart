import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/pet_model.dart';

final petRepositoryProvider = Provider<PetRepository>((ref) {
  return PetRepository();
});

final currentPetProvider = StreamProvider.family<PetModel?, String>((ref, petId) {
  final repo = ref.watch(petRepositoryProvider);
  return repo.watchPet(petId);
});

class PetRepository {
  final FirebaseFirestore? _firestore;

  // Almacén en memoria para modo sin credenciales o pruebas locales
  static final Map<String, PetModel> _mockPets = {};
  static final Map<String, StreamController<PetModel?>> _mockControllers = {};

  PetRepository()
      : _firestore = Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

  Stream<PetModel?> watchPet(String petId) {
    if (_firestore != null) {
      return _firestore!.collection('pets').doc(petId).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return PetModel.fromMap(doc.data()!, doc.id);
      });
    } else {
      if (!_mockControllers.containsKey(petId)) {
        _mockControllers[petId] = StreamController<PetModel?>.broadcast();
      }
      Future.microtask(() {
        if (_mockPets.containsKey(petId)) {
          _mockControllers[petId]?.add(_mockPets[petId]);
        }
      });
      return _mockControllers[petId]!.stream;
    }
  }

  Future<PetModel?> getPet(String petId) async {
    if (_firestore != null) {
      final doc = await _firestore!.collection('pets').doc(petId).get();
      if (!doc.exists || doc.data() == null) return null;
      return PetModel.fromMap(doc.data()!, doc.id);
    } else {
      return _mockPets[petId];
    }
  }

  /// Guarda la imagen como Data URI Base64 directa.
  /// Esto garantiza 100% de compatibilidad en Web y Móvil sin bloqueos de CORS,
  /// asegurando que las previews y miniaturas siempre se vean instantáneamente.
  Future<String> uploadImageBytes({
    required String coupleId,
    required String filename,
    required Uint8List bytes,
  }) async {
    final base64String = base64Encode(bytes);
    return 'data:image/png;base64,$base64String';
  }

  Future<PetModel> createPet({
    required String coupleId,
    required String name,
    required Uint8List bodyBytes,
    required EyesConfig eyesConfig,
  }) async {
    final now = DateTime.now();
    final petId = _firestore != null
        ? _firestore!.collection('pets').doc().id
        : 'pet_${DateTime.now().millisecondsSinceEpoch}';

    final bodyUrl = await uploadImageBytes(
      coupleId: coupleId,
      filename: 'body_$petId.png',
      bytes: bodyBytes,
    );

    final pet = PetModel(
      id: petId,
      coupleId: coupleId,
      name: name,
      bodyImageUrl: bodyUrl,
      eyesConfig: eyesConfig,
      closet: const [],
      drawnFruits: const {},
      createdAt: now,
      updatedAt: now,
    );

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set(pet.toMap());
    } else {
      _mockPets[petId] = pet;
      _mockControllers.putIfAbsent(petId, () => StreamController.broadcast()).add(pet);
    }

    return pet;
  }

  /// Flujo inicial de creación de la primera prenda
  Future<void> updateClothes({
    required String petId,
    required String coupleId,
    required Uint8List clothesBytes,
  }) async {
    final clothesUrl = await uploadImageBytes(
      coupleId: coupleId,
      filename: 'clothes_$petId.png',
      bytes: clothesBytes,
    );

    final now = DateTime.now();
    final initialGarment = GarmentItem(
      id: 'initial_garment',
      name: 'Prenda Inicial',
      imageUrl: clothesUrl,
      createdAt: now,
    );

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'clothesImageUrl': clothesUrl,
        'activeGarmentId': 'initial_garment',
        'closet': [initialGarment.toMap()],
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          clothesImageUrl: clothesUrl,
          activeGarmentId: 'initial_garment',
          closet: [initialGarment],
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Clóset: Agregar una nueva prenda (hasta 5 slots)
  Future<void> addGarment({
    required String petId,
    required String coupleId,
    required Uint8List clothesBytes,
    required String name,
    String createdBy = '',
  }) async {
    final current = await getPet(petId);
    final closet = List<GarmentItem>.from(current?.closet ?? []);
    if (closet.length >= 5) {
      throw Exception('El clóset ya tiene el máximo de 5 prendas.');
    }

    final garmentId = 'garment_${DateTime.now().millisecondsSinceEpoch}';
    final imageUrl = await uploadImageBytes(
      coupleId: coupleId,
      filename: '${garmentId}_$petId.png',
      bytes: clothesBytes,
    );

    final newGarment = GarmentItem(
      id: garmentId,
      name: name.trim().isEmpty ? 'Prenda #${closet.length + 1}' : name.trim(),
      imageUrl: imageUrl,
      createdBy: createdBy,
      createdAt: DateTime.now(),
    );

    closet.add(newGarment);
    final now = DateTime.now();

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'closet': closet.map((g) => g.toMap()).toList(),
        'activeGarmentId': garmentId,
        'clothesImageUrl': imageUrl,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          closet: closet,
          activeGarmentId: garmentId,
          clothesImageUrl: imageUrl,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Clóset: Comprar y añadir prenda o accesorio al clóset
  Future<void> buyGarment({
    required String petId,
    required GarmentItem garment,
    required int price,
  }) async {
    final current = await getPet(petId);
    if (current == null) return;
    final now = DateTime.now();

    final closet = List<GarmentItem>.from(current.closet);
    if (closet.any((g) => g.id == garment.id)) return;

    final newCoins = max(0, current.coins - price);
    closet.add(garment);

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'closet': closet.map((g) => g.toMap()).toList(),
        'coins': newCoins,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          closet: closet,
          coins: newCoins,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Clóset: Equipar o Quitar prenda (retrocompatibilidad)
  Future<void> equipGarment({
    required String petId,
    required String? garmentId,
  }) async {
    if (garmentId == null) {
      final now = DateTime.now();
      if (_firestore != null) {
        await _firestore!.collection('pets').doc(petId).set({
          'activeGarmentId': null,
          'equippedGarmentIds': [],
          'clothesImageUrl': null,
          'updatedAt': now.toIso8601String(),
        }, SetOptions(merge: true));
      } else if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          activeGarmentId: null,
          equippedGarmentIds: [],
          clothesImageUrl: null,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    } else {
      await toggleEquipGarment(petId: petId, garmentId: garmentId);
    }
  }

  /// Clóset: Alternar equipamiento de prenda (hasta 2 prendas simultáneas)
  Future<void> toggleEquipGarment({
    required String petId,
    required String garmentId,
  }) async {
    final current = await getPet(petId);
    if (current == null) return;
    final now = DateTime.now();

    List<String> equipped = List.from(current.resolvedEquippedGarmentIds);
    if (equipped.contains(garmentId)) {
      equipped.remove(garmentId);
    } else {
      if (equipped.length < 2) {
        equipped.add(garmentId);
      } else {
        equipped = [equipped[1], garmentId];
      }
    }

    String? primaryImageUrl;
    if (equipped.isNotEmpty) {
      final found = current.closet.firstWhere(
        (g) => g.id == equipped.first,
        orElse: () => GarmentItem(id: '', name: '', imageUrl: '', createdAt: now),
      );
      if (found.imageUrl.isNotEmpty) primaryImageUrl = found.imageUrl;
    }

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'equippedGarmentIds': equipped,
        'activeGarmentId': equipped.isNotEmpty ? equipped.last : null,
        'clothesImageUrl': primaryImageUrl,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          equippedGarmentIds: equipped,
          activeGarmentId: equipped.isNotEmpty ? equipped.last : null,
          clothesImageUrl: primaryImageUrl,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Clóset: Ajustar posición (offset) de una prenda
  Future<void> updateGarmentOffset({
    required String petId,
    required String garmentId,
    required double offsetX,
    required double offsetY,
  }) async {
    final current = await getPet(petId);
    if (current == null) return;
    final now = DateTime.now();

    final closet = List<GarmentItem>.from(current.closet);
    final index = closet.indexWhere((g) => g.id == garmentId);
    if (index == -1) return;

    closet[index] = closet[index].copyWith(offsetX: offsetX, offsetY: offsetY);

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'closet': closet.map((g) => g.toMap()).toList(),
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          closet: closet,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Fondos: Guardar fondo en uno de los 3 slots
  Future<void> updateBackgroundSlot({
    required String petId,
    required String coupleId,
    required int slotIndex,
    Uint8List? backgroundBytes,
    String? customUrl,
  }) async {
    final current = await getPet(petId);
    if (current == null) return;
    final now = DateTime.now();

    final slots = List<String?>.from(current.backgroundSlots);
    while (slots.length < 3) {
      slots.add(null);
    }

    String? newBgUrl;
    if (customUrl != null && customUrl.isNotEmpty) {
      newBgUrl = customUrl;
    } else if (backgroundBytes != null) {
      newBgUrl = await uploadImageBytes(
        coupleId: coupleId,
        filename: 'background_slot_${slotIndex}_$petId.png',
        bytes: backgroundBytes,
      );
    }
    slots[slotIndex] = newBgUrl;

    if (_firestore != null) {
      final Map<String, dynamic> updateData = {
        'backgroundSlots': slots,
        'activeBackgroundSlotIndex': slotIndex,
        'backgroundUrl': newBgUrl,
        'updatedAt': now.toIso8601String(),
      };
      await _firestore!.collection('pets').doc(petId).set(updateData, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          backgroundSlots: slots,
          activeBackgroundSlotIndex: slotIndex,
          backgroundUrl: newBgUrl,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Fondos: Cambiar slot de fondo activo
  Future<void> setActiveBackgroundSlot({
    required String petId,
    required int slotIndex,
  }) async {
    final current = await getPet(petId);
    if (current == null) return;
    final now = DateTime.now();

    final slots = current.backgroundSlots;
    final bgUrl = (slotIndex >= 0 && slotIndex < slots.length) ? slots[slotIndex] : null;

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'activeBackgroundSlotIndex': slotIndex,
        'backgroundUrl': bgUrl,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          activeBackgroundSlotIndex: slotIndex,
          backgroundUrl: bgUrl,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Clóset: Editar prenda existente
  Future<void> updateGarment({
    required String petId,
    required String coupleId,
    required String garmentId,
    required Uint8List clothesBytes,
    String? newName,
  }) async {
    final current = await getPet(petId);
    if (current == null) return;

    final closet = List<GarmentItem>.from(current.closet);
    final index = closet.indexWhere((g) => g.id == garmentId);
    if (index == -1) return;

    final imageUrl = await uploadImageBytes(
      coupleId: coupleId,
      filename: '${garmentId}_$petId.png',
      bytes: clothesBytes,
    );

    final existing = closet[index];
    final updatedGarment = existing.copyWith(
      name: (newName != null && newName.trim().isNotEmpty) ? newName.trim() : existing.name,
      imageUrl: imageUrl,
    );
    closet[index] = updatedGarment;

    final isActive = current.activeGarmentId == garmentId;
    final now = DateTime.now();

    if (_firestore != null) {
      final Map<String, dynamic> updateData = {
        'closet': closet.map((g) => g.toMap()).toList(),
        'updatedAt': now.toIso8601String(),
      };
      if (isActive) {
        updateData['clothesImageUrl'] = imageUrl;
      }
      await _firestore!.collection('pets').doc(petId).set(updateData, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          closet: closet,
          clothesImageUrl: isActive ? imageUrl : _mockPets[petId]!.clothesImageUrl,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Clóset: Eliminar prenda
  Future<void> deleteGarment({
    required String petId,
    required String garmentId,
  }) async {
    final current = await getPet(petId);
    if (current == null) return;

    final closet = List<GarmentItem>.from(current.closet)..removeWhere((g) => g.id == garmentId);
    final isActive = current.activeGarmentId == garmentId;
    final now = DateTime.now();

    if (_firestore != null) {
      final Map<String, dynamic> updateData = {
        'closet': closet.map((g) => g.toMap()).toList(),
        'updatedAt': now.toIso8601String(),
      };
      if (isActive) {
        updateData['activeGarmentId'] = null;
        updateData['clothesImageUrl'] = null;
      }
      await _firestore!.collection('pets').doc(petId).set(updateData, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          closet: closet,
          activeGarmentId: isActive ? null : _mockPets[petId]!.activeGarmentId,
          clothesImageUrl: isActive ? null : _mockPets[petId]!.clothesImageUrl,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Alimentación: Guardar fruta dibujada a mano
  Future<void> saveDrawnFruit({
    required String petId,
    required String coupleId,
    required String fruitKey,
    required Uint8List fruitBytes,
  }) async {
    final fruitUrl = await uploadImageBytes(
      coupleId: coupleId,
      filename: 'fruit_${fruitKey}_$petId.png',
      bytes: fruitBytes,
    );

    final current = await getPet(petId);
    final drawnFruits = Map<String, String>.from(current?.drawnFruits ?? {});
    drawnFruits[fruitKey] = fruitUrl;
    final now = DateTime.now();

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'drawnFruits': drawnFruits,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          drawnFruits: drawnFruits,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Tienda: Comprar / Adquirir fruta (consumible)
  Future<void> buyFruit({
    required String petId,
    required String fruitKey,
    int quantity = 1,
    int price = 0,
  }) async {
    final current = await getPet(petId);
    final inventory = Map<String, int>.from(current?.foodInventory ?? {});
    inventory[fruitKey] = (inventory[fruitKey] ?? 0) + quantity;
    final currentCoins = current?.coins ?? 999;
    final newCoins = (currentCoins - price).clamp(0, 999999);
    final now = DateTime.now();

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'foodInventory': inventory,
        'coins': newCoins,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          foodInventory: inventory,
          coins: newCoins,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Monedas: Agregar monedas (ganadas en minijuegos)
  Future<void> addCoins({
    required String petId,
    required int amount,
  }) async {
    final current = await getPet(petId);
    final currentCoins = current?.coins ?? 999;
    final newCoins = (currentCoins + amount).clamp(0, 999999);
    final now = DateTime.now();

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'coins': newCoins,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          coins: newCoins,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Enseñar Lenguaje: Agregar frase a la mascota (máx 100 caracteres)
  Future<void> addCustomPhrase({
    required String petId,
    required String phrase,
  }) async {
    final clean = phrase.trim();
    if (clean.isEmpty) return;
    final text = clean.length > 100 ? clean.substring(0, 100) : clean;

    final current = await getPet(petId);
    final phrases = List<String>.from(current?.customPhrases ?? PetModel.defaultPhrases);
    if (!phrases.contains(text)) {
      phrases.add(text);
    }
    final now = DateTime.now();

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'customPhrases': phrases,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          customPhrases: phrases,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Enseñar Lenguaje: Eliminar frase
  Future<void> removeCustomPhrase({
    required String petId,
    required String phrase,
  }) async {
    final current = await getPet(petId);
    final phrases = List<String>.from(current?.customPhrases ?? PetModel.defaultPhrases);
    phrases.remove(phrase);
    final now = DateTime.now();

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'customPhrases': phrases,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          customPhrases: phrases,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Alimentación: Dar fruta/agua a la mascota (consume 1 del inventario)
  Future<void> feedPet({
    required String petId,
    required String fruitKey,
  }) async {
    final current = await getPet(petId);
    final inventory = Map<String, int>.from(current?.foodInventory ?? {});
    final currentCount = inventory[fruitKey] ?? 0;
    if (currentCount > 0) {
      inventory[fruitKey] = currentCount - 1;
    }
    final now = DateTime.now();
    final isWater = fruitKey == 'agua';

    if (_firestore != null) {
      final updateData = <String, dynamic>{
        'foodInventory': inventory,
        'lastFedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      if (isWater) {
        updateData['lastWateredAt'] = now.toIso8601String();
      }
      await _firestore!.collection('pets').doc(petId).set(updateData, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          foodInventory: inventory,
          lastFedAt: now,
          lastWateredAt: isWater ? now : current?.lastWateredAt,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Acariciar mascota: sube el ánimo
  Future<void> petAnimal({
    required String petId,
  }) async {
    final now = DateTime.now();
    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'lastPettedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          lastPettedAt: now,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Sed: Dar agua a la mascota
  Future<void> waterPet({
    required String petId,
  }) async {
    final now = DateTime.now();
    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'lastWateredAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          lastWateredAt: now,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Sueño: Apagar / Encender la luz (con recuperación de energía)
  Future<void> toggleSleep({
    required String petId,
    required bool isSleeping,
  }) async {
    final now = DateTime.now();
    final updateData = <String, dynamic>{
      'isSleeping': isSleeping,
      'updatedAt': now.toIso8601String(),
    };
    if (isSleeping) {
      updateData['sleepStartedAt'] = now.toIso8601String();
    } else {
      updateData['lastSleptAt'] = now.toIso8601String();
    }

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set(updateData, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          isSleeping: isSleeping,
          sleepStartedAt: isSleeping ? now : _mockPets[petId]?.sleepStartedAt,
          lastSleptAt: !isSleeping ? now : _mockPets[petId]?.lastSleptAt,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Fondos: Guardar fondo dibujado
  Future<void> updateBackground({
    required String petId,
    required String coupleId,
    required Uint8List? backgroundBytes,
  }) async {
    final now = DateTime.now();
    String? backgroundUrl;

    if (backgroundBytes != null) {
      backgroundUrl = await uploadImageBytes(
        coupleId: coupleId,
        filename: 'background_$petId.png',
        bytes: backgroundBytes,
      );
    }

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'backgroundUrl': backgroundUrl,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          backgroundUrl: backgroundUrl,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }

  /// Editar cuerpo/silueta y ojos/boca de la mascota existente
  Future<void> updatePetBody({
    required String petId,
    required String coupleId,
    required Uint8List bodyBytes,
    required EyesConfig eyesConfig,
  }) async {
    final now = DateTime.now();
    final bodyUrl = await uploadImageBytes(
      coupleId: coupleId,
      filename: 'body_$petId.png',
      bytes: bodyBytes,
    );

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'bodyImageUrl': bodyUrl,
        'eyesConfig': eyesConfig.toMap(),
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          bodyImageUrl: bodyUrl,
          eyesConfig: eyesConfig,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }
}
