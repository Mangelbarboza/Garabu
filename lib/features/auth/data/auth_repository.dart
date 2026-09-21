import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../domain/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final authStateProvider = StreamProvider<UserModel?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

final currentUserProvider = StateProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

class AuthRepository {
  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;

  // StreamController para soporte reactivo con Firebase o modo de prueba local
  final _controller = StreamController<UserModel?>.broadcast();
  UserModel? _currentMockUser;

  AuthRepository()
      : _auth = Firebase.apps.isNotEmpty ? FirebaseAuth.instance : null,
        _firestore = Firebase.apps.isNotEmpty ? FirebaseFirestore.instance : null {
    if (_auth != null && _firestore != null) {
      _auth!.authStateChanges().listen((User? user) async {
        if (user == null) {
          _controller.add(null);
        } else {
          final userDoc = await _firestore!.collection('users').doc(user.uid).get();
          if (userDoc.exists && userDoc.data() != null) {
            _controller.add(UserModel.fromMap(userDoc.data()!, user.uid));
          } else {
            final fallbackUser = UserModel(
              id: user.uid,
              name: (user.displayName != null && user.displayName!.isNotEmpty)
                  ? user.displayName!
                  : (user.email?.split('@').first ?? 'Usuario'),
              email: user.email ?? '',
              age: 18,
              createdAt: DateTime.now(),
            );
            await _firestore!.collection('users').doc(user.uid).set(
              fallbackUser.toMap(),
              SetOptions(merge: true),
            );
            _controller.add(fallbackUser);
          }
        }
      });
    }
  }

  Stream<UserModel?> get authStateChanges => _controller.stream;

  UserModel? get currentUser {
    if (_auth != null && _auth!.currentUser != null) {
      return _currentMockUser ?? UserModel(
        id: _auth!.currentUser!.uid,
        name: _auth!.currentUser!.displayName ?? 'Usuario',
        email: _auth!.currentUser!.email ?? '',
        age: 18,
        createdAt: DateTime.now(),
      );
    }
    return _currentMockUser;
  }

  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required int age,
  }) async {
    if (_auth != null && _firestore != null) {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user?.updateDisplayName(name.trim());

      final newUser = UserModel(
        id: credential.user!.uid,
        name: name.trim(),
        email: email.trim(),
        age: age,
        createdAt: DateTime.now(),
      );

      await _firestore!.collection('users').doc(newUser.id).set(newUser.toMap());
      _controller.add(newUser);
      return newUser;
    } else {
      // Modo local / Fallback para ejecución inmediata sin configuración de Firebase
      final newUser = UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: name.trim(),
        email: email.trim(),
        age: age,
        createdAt: DateTime.now(),
      );
      _currentMockUser = newUser;
      _controller.add(newUser);
      return newUser;
    }
  }

  Future<UserModel?> signIn({
    required String email,
    required String password,
  }) async {
    if (_auth != null && _firestore != null) {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final doc = await _firestore!.collection('users').doc(credential.user!.uid).get();
      if (doc.exists && doc.data() != null) {
        final user = UserModel.fromMap(doc.data()!, doc.id);
        _controller.add(user);
        return user;
      } else {
        final fallback = UserModel(
          id: credential.user!.uid,
          name: (credential.user!.displayName != null && credential.user!.displayName!.isNotEmpty)
              ? credential.user!.displayName!
              : (credential.user!.email?.split('@').first ?? 'Usuario'),
          email: credential.user!.email ?? email.trim(),
          age: 18,
          createdAt: DateTime.now(),
        );
        await _firestore!.collection('users').doc(credential.user!.uid).set(
          fallback.toMap(),
          SetOptions(merge: true),
        );
        _controller.add(fallback);
        return fallback;
      }
    } else {
      final mock = UserModel(
        id: 'usr_demo_1',
        name: email.split('@').first,
        email: email.trim(),
        age: 20,
        createdAt: DateTime.now(),
      );
      _currentMockUser = mock;
      _controller.add(mock);
      return mock;
    }
  }

  Future<void> updateUserCoupleId(String userId, String coupleId) async {
    if (_firestore != null) {
      await _firestore!.collection('users').doc(userId).set(
        {'coupleId': coupleId},
        SetOptions(merge: true),
      );
    }
    if (_currentMockUser != null && _currentMockUser!.id == userId) {
      _currentMockUser = _currentMockUser!.copyWith(coupleId: coupleId);
      _controller.add(_currentMockUser);
    }
  }

  Future<void> signOut() async {
    if (_auth != null) {
      await _auth!.signOut();
    }
    _currentMockUser = null;
    _controller.add(null);
  }
}
