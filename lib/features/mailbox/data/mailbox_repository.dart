import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/letter_model.dart';

final mailboxRepositoryProvider = Provider<MailboxRepository>((ref) {
  return MailboxRepository();
});

final lettersProvider = StreamProvider.family<List<LetterModel>, String>((ref, coupleId) {
  final repo = ref.watch(mailboxRepositoryProvider);
  return repo.watchLetters(coupleId);
});

class MailboxRepository {
  final FirebaseFirestore? _firestore;

  static final Map<String, List<LetterModel>> _mockLetters = {};
  static final Map<String, StreamController<List<LetterModel>>> _mockControllers = {};

  MailboxRepository()
      : _firestore = Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null;

  Stream<List<LetterModel>> watchLetters(String coupleId) {
    if (_firestore != null) {
      return _firestore!
          .collection('couples')
          .doc(coupleId)
          .collection('letters')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => LetterModel.fromMap(doc.data(), doc.id)).toList();
      });
    } else {
      if (!_mockControllers.containsKey(coupleId)) {
        _mockControllers[coupleId] = StreamController<List<LetterModel>>.broadcast();
      }
      Future.microtask(() {
        _mockControllers[coupleId]?.add(_mockLetters[coupleId] ?? []);
      });
      return _mockControllers[coupleId]!.stream;
    }
  }

  Future<void> sendLetter({
    required String coupleId,
    required String senderId,
    required String senderName,
    required String content,
  }) async {
    final now = DateTime.now();
    final letterId = 'letter_${now.millisecondsSinceEpoch}';

    final letter = LetterModel(
      id: letterId,
      coupleId: coupleId,
      senderId: senderId,
      senderName: senderName,
      content: content.trim(),
      createdAt: now,
      isRead: false,
    );

    if (_firestore != null) {
      await _firestore!
          .collection('couples')
          .doc(coupleId)
          .collection('letters')
          .doc(letterId)
          .set(letter.toMap());
    } else {
      final current = _mockLetters[coupleId] ?? [];
      current.insert(0, letter);
      _mockLetters[coupleId] = current;
      _mockControllers[coupleId]?.add(current);
    }
  }

  Future<void> markAsRead({
    required String coupleId,
    required String letterId,
  }) async {
    if (_firestore != null) {
      await _firestore!
          .collection('couples')
          .doc(coupleId)
          .collection('letters')
          .doc(letterId)
          .set({'isRead': true}, SetOptions(merge: true));
    } else {
      final current = _mockLetters[coupleId] ?? [];
      final idx = current.indexWhere((l) => l.id == letterId);
      if (idx != -1) {
        current[idx] = current[idx].copyWith(isRead: true);
        _mockLetters[coupleId] = current;
        _mockControllers[coupleId]?.add(current);
      }
    }
  }
}
