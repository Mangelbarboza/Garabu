import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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
  final FirebaseStorage? _storage;

  // Almacén en memoria para modo sin credenciales o pruebas locales
  static final Map<String, PetModel> _mockPets = {};
  static final Map<String, StreamController<PetModel?>> _mockControllers = {};

  PetRepository()
      : _firestore = Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null,
        _storage = Firebase.apps.isNotEmpty ? FirebaseStorage.instance : null;

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

  Future<String> uploadImageBytes({
    required String coupleId,
    required String filename,
    required Uint8List bytes,
  }) async {
    if (_storage != null) {
      try {
        final ref = _storage!.ref().child('couples/$coupleId/$filename');
        final metadata = SettableMetadata(contentType: 'image/png');
        final uploadTask = await ref.putData(bytes, metadata);
        return await uploadTask.ref.getDownloadURL();
      } catch (e) {
        // En navegadores web, Firebase Storage bloquea peticiones si falta CORS.
        // El fallback garantiza funcionamiento guardando como Data URI en Base64.
        final base64String = base64Encode(bytes);
        return 'data:image/png;base64,$base64String';
      }
    } else {
      final base64String = base64Encode(bytes);
      return 'data:image/png;base64,$base64String';
    }
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
      id: 'garment_initial',
      name: 'Prenda Inicial',
      imageUrl: clothesUrl,
      createdAt: now,
    );

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'clothesImageUrl': clothesUrl,
        'activeGarmentId': 'garment_initial',
        'closet': [initialGarment.toMap()],
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          clothesImageUrl: clothesUrl,
          activeGarmentId: 'garment_initial',
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

  /// Clóset: Equipar o Quitar prenda
  Future<void> equipGarment({
    required String petId,
    required String? garmentId,
  }) async {
    final current = await getPet(petId);
    final now = DateTime.now();

    String? newClothesUrl;
    if (garmentId != null && current != null) {
      final found = current.closet.firstWhere(
        (g) => g.id == garmentId,
        orElse: () => GarmentItem(id: '', name: '', imageUrl: '', createdAt: now),
      );
      if (found.imageUrl.isNotEmpty) {
        newClothesUrl = found.imageUrl;
      }
    }

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'activeGarmentId': garmentId,
        'clothesImageUrl': newClothesUrl,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          activeGarmentId: garmentId,
          clothesImageUrl: newClothesUrl,
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

  /// Alimentación: Dar fruta a la mascota
  Future<void> feedPet({
    required String petId,
    required String fruitKey,
  }) async {
    final now = DateTime.now();
    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'lastFedAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          lastFedAt: now,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }
}
