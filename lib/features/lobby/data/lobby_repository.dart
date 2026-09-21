import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/couple_model.dart';

final lobbyRepositoryProvider = Provider<LobbyRepository>((ref) {
  return LobbyRepository();
});

final currentCoupleProvider = StreamProvider.family<CoupleModel?, String>((ref, coupleId) {
  final repo = ref.watch(lobbyRepositoryProvider);
  return repo.watchCouple(coupleId);
});

class LobbyRepository {
  final FirebaseFirestore? _firestore;

  // Memoria local reactiva para modo offline / sin credenciales de Firebase configuradas
  static final Map<String, CoupleModel> _mockCouples = {};
  static final Map<String, StreamController<CoupleModel?>> _mockControllers = {};

  LobbyRepository()
      : _firestore = Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

  String _generate6DigitCode() {
    final rand = Random();
    // Genera un código legible de 6 dígitos numéricos
    final code = 100000 + rand.nextInt(900000);
    return code.toString();
  }

  Stream<CoupleModel?> watchCouple(String coupleId) {
    if (_firestore != null) {
      return _firestore!.collection('couples').doc(coupleId).snapshots().map((doc) {
        if (!doc.exists || doc.data() == null) return null;
        return CoupleModel.fromMap(doc.data()!, doc.id);
      });
    } else {
      if (!_mockControllers.containsKey(coupleId)) {
        _mockControllers[coupleId] = StreamController<CoupleModel?>.broadcast();
      }
      // Emitir valor actual
      Future.microtask(() {
        if (_mockCouples.containsKey(coupleId)) {
          _mockControllers[coupleId]?.add(_mockCouples[coupleId]);
        }
      });
      return _mockControllers[coupleId]!.stream;
    }
  }

  Future<CoupleModel> createCoupleInvite({
    required String user1Id,
    required String user1Name,
  }) async {
    final code = _generate6DigitCode();
    final now = DateTime.now();

    if (_firestore != null) {
      final docRef = _firestore!.collection('couples').doc();
      final couple = CoupleModel(
        id: docRef.id,
        user1Id: user1Id,
        user1Name: user1Name,
        inviteCode: code,
        streak: 1,
        lastInteraction: now,
        status: 'waiting_partner',
        createdAt: now,
      );
      await docRef.set(couple.toMap());
      return couple;
    } else {
      final coupleId = 'cpl_${DateTime.now().millisecondsSinceEpoch}';
      final couple = CoupleModel(
        id: coupleId,
        user1Id: user1Id,
        user1Name: user1Name,
        inviteCode: code,
        streak: 1,
        lastInteraction: now,
        status: 'waiting_partner',
        createdAt: now,
      );
      _mockCouples[coupleId] = couple;
      _mockControllers.putIfAbsent(coupleId, () => StreamController.broadcast()).add(couple);
      return couple;
    }
  }

  Future<CoupleModel> joinWithCode({
    required String code,
    required String user2Id,
    required String user2Name,
  }) async {
    final cleanCode = code.trim().toUpperCase();

    if (_firestore != null) {
      final query = await _firestore!
          .collection('couples')
          .where('inviteCode', isEqualTo: cleanCode)
          .where('status', isEqualTo: 'waiting_partner')
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        throw Exception('Código no encontrado o la pareja ya fue vinculada.');
      }

      final doc = query.docs.first;
      final couple = CoupleModel.fromMap(doc.data(), doc.id).copyWith(
        user2Id: user2Id,
        user2Name: user2Name,
        status: 'drawing_body', // Una vez unidos, Usuario 1 dibuja el cuerpo
      );

      await doc.reference.set(couple.toMap(), SetOptions(merge: true));
      return couple;
    } else {
      CoupleModel? found;
      for (final c in _mockCouples.values) {
        if (c.inviteCode == cleanCode && c.status == 'waiting_partner') {
          found = c;
          break;
        }
      }

      if (found == null) {
        throw Exception('Código no encontrado o la pareja ya fue vinculada.');
      }

      final updated = found.copyWith(
        user2Id: user2Id,
        user2Name: user2Name,
        status: 'drawing_body',
      );
      _mockCouples[found.id] = updated;
      _mockControllers[found.id]?.add(updated);
      return updated;
    }
  }

  Future<void> updateCoupleStatus(String coupleId, String newStatus, {String? petId}) async {
    final Map<String, dynamic> updates = {
      'status': newStatus,
      'lastInteraction': DateTime.now().toIso8601String(),
    };
    if (petId != null) {
      updates['petId'] = petId;
    }

    if (_firestore != null) {
      await _firestore!.collection('couples').doc(coupleId).set(
        updates,
        SetOptions(merge: true),
      );
    } else {
      if (_mockCouples.containsKey(coupleId)) {
        final current = _mockCouples[coupleId]!;
        final updated = current.copyWith(
          status: newStatus,
          petId: petId ?? current.petId,
          lastInteraction: DateTime.now(),
        );
        _mockCouples[coupleId] = updated;
        _mockControllers[coupleId]?.add(updated);
      }
    }
  }

  Future<void> switchActivePet({
    required String coupleId,
    required String petId,
  }) async {
    if (_firestore != null) {
      await _firestore!.collection('couples').doc(coupleId).set({
        'activePetId': petId,
      }, SetOptions(merge: true));
    } else {
      if (_mockCouples.containsKey(coupleId)) {
        final current = _mockCouples[coupleId]!;
        final updated = current.copyWith(activePetId: petId);
        _mockCouples[coupleId] = updated;
        _mockControllers[coupleId]?.add(updated);
      }
    }
  }

  Future<void> assignPetToSlot({
    required String coupleId,
    required int slotNumber,
    required String petId,
  }) async {
    final field = slotNumber == 1 ? 'user1PetId' : 'user2PetId';
    final updates = <String, dynamic>{
      field: petId,
      'activePetId': petId,
      'status': 'ready',
    };
    if (slotNumber == 1) {
      updates['petId'] = petId;
    }

    if (_firestore != null) {
      await _firestore!.collection('couples').doc(coupleId).set(
        updates,
        SetOptions(merge: true),
      );
    } else {
      if (_mockCouples.containsKey(coupleId)) {
        final current = _mockCouples[coupleId]!;
        final updated = current.copyWith(
          user1PetId: slotNumber == 1 ? petId : current.user1PetId,
          user2PetId: slotNumber == 2 ? petId : current.user2PetId,
          petId: slotNumber == 1 ? petId : current.petId,
          activePetId: petId,
          status: 'ready',
        );
        _mockCouples[coupleId] = updated;
        _mockControllers[coupleId]?.add(updated);
      }
    }
  }
}
