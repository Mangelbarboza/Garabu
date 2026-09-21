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

  // Almacén en memoria para modo sin credenciales
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
        // En navegadores web (localhost), Firebase Storage bloquea peticiones por CORS
        // a menos que se configure en Google Cloud. El fallback garantiza que la app
        // continúe funcionando perfectamente guardando la imagen como Data URI.
        final base64String = base64Encode(bytes);
        return 'data:image/png;base64,$base64String';
      }
    } else {
      // Data URI Base64 directa para soporte local/inmediato sin conexión requerida
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

    if (_firestore != null) {
      await _firestore!.collection('pets').doc(petId).set({
        'clothesImageUrl': clothesUrl,
        'updatedAt': now.toIso8601String(),
      }, SetOptions(merge: true));
    } else {
      if (_mockPets.containsKey(petId)) {
        final updated = _mockPets[petId]!.copyWith(
          clothesImageUrl: clothesUrl,
          updatedAt: now,
        );
        _mockPets[petId] = updated;
        _mockControllers[petId]?.add(updated);
      }
    }
  }
}
