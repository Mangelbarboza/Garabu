import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/garabu_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_screen.dart';
import 'features/canvas/presentation/body_canvas_screen.dart';
import 'features/canvas/presentation/clothes_canvas_screen.dart';
import 'features/canvas/presentation/pet_naming_dialog.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/lobby/data/lobby_repository.dart';
import 'features/lobby/presentation/lobby_screen.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kIsWeb) {
      await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    }
  } catch (e) {
    debugPrint('Error al inicializar Firebase: $e');
  }

  runApp(
    const ProviderScope(
      child: GarabuApp(),
    ),
  );
}

class GarabuApp extends StatelessWidget {
  const GarabuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Garabu',
      debugShowCheckedModeBanner: false,
      theme: GarabuTheme.lightTheme,
      home: const AppRouter(),
    );
  }
}

class AppRouter extends ConsumerWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);

    return authState.when(
      loading: () => const Scaffold(
        backgroundColor: GarabuTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: GarabuTheme.primaryBrown),
        ),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Error de autenticación: $e')),
      ),
      data: (user) {
        if (user == null) {
          return const AuthScreen();
        }

        // Si el usuario no tiene pareja vinculada, va directo al Lobby
        if (user.coupleId == null) {
          return const LobbyScreen();
        }

        // Si tiene un coupleId, escuchamos el estado de la pareja
        final coupleAsync = ref.watch(currentCoupleProvider(user.coupleId!));
        return coupleAsync.when(
          loading: () => const Scaffold(
            backgroundColor: GarabuTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: GarabuTheme.primaryBrown),
            ),
          ),
          error: (e, _) => const LobbyScreen(),
          data: (couple) {
            if (couple == null || couple.status == 'waiting_partner') {
              return const LobbyScreen();
            }

            if (couple.status == 'drawing_body') {
              if (user.id == couple.user1Id) {
                return PetNamingDialog(couple: couple);
              } else {
                return ClothesCanvasScreen(couple: couple);
              }
            }

            if (couple.status == 'drawing_clothes') {
              if (user.id == couple.user2Id) {
                return ClothesCanvasScreen(couple: couple);
              } else {
                return BodyCanvasScreen(
                  couple: couple,
                  petName: 'Nuestra Mascota',
                );
              }
            }

            // Cuando la mascota ya está lista, se muestra el Dashboard
            return DashboardScreen(couple: couple);
          },
        );
      },
    );
  }
}
