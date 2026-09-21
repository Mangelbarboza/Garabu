import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/garabu_theme.dart';
import '../../../core/widgets/notebook_background.dart';
import '../../auth/data/auth_repository.dart';
import '../../canvas/presentation/widgets/eye_widget.dart';
import '../../lobby/data/lobby_repository.dart';
import '../../lobby/domain/couple_model.dart';
import '../../pet/data/pet_repository.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final CoupleModel couple;

  const DashboardScreen({
    super.key,
    required this.couple,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    // Animación sutil de respiración/vida para la mascota
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildLayerImage(String? imageUrl, Size size) {
    if (imageUrl == null || imageUrl.isEmpty) return const SizedBox();

    if (imageUrl.startsWith('data:image/png;base64,')) {
      final base64Data = imageUrl.replaceFirst('data:image/png;base64,', '');
      return Image.memory(
        base64Decode(base64Data),
        width: size.width,
        height: size.height,
        fit: BoxFit.contain,
      );
    } else {
      return Image.network(
        imageUrl,
        width: size.width,
        height: size.height,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox(),
      );
    }
  }

  void _showActionFeedback(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GarabuTheme.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(color: GarabuTheme.deepEspresso, fontWeight: FontWeight.bold)),
        content: Text(message, style: const TextStyle(color: GarabuTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('¡Genial!', style: TextStyle(color: GarabuTheme.primaryBrown, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(currentCoupleProvider(widget.couple.id));
    final currentCouple = coupleAsync.value ?? widget.couple;
    final petId = currentCouple.petId;

    if (petId == null) {
      return const Scaffold(
        body: Center(child: Text('Buscando mascota...')),
      );
    }

    final petAsync = ref.watch(currentPetProvider(petId));

    return Scaffold(
      backgroundColor: GarabuTheme.background,
      appBar: AppBar(
        title: Text('${currentCouple.user1Name} & ${currentCouple.user2Name ?? "Pareja"}'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_rounded, color: GarabuTheme.primaryBrown),
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: SafeArea(
        child: petAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: GarabuTheme.primaryBrown),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (pet) {
            if (pet == null) {
              return const Center(child: Text('Mascota no encontrada'));
            }

            final screenWidth = MediaQuery.of(context).size.width;
            final petBoxSize = (screenWidth - 48).clamp(280.0, 420.0);
            final canvasSize = Size(petBoxSize, petBoxSize);

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                children: [
                  // Módulo de Racha Diaria (Core de Retención)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: GarabuTheme.paperWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GarabuTheme.warmSand),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🔥', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 8),
                        Text(
                          'Racha actual: ${currentCouple.streak} ${currentCouple.streak == 1 ? "día" : "días"}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: GarabuTheme.deepEspresso,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Nombre de la Mascota
                  Text(
                    pet.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Su garabato compartido',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: GarabuTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contenedor Apilado de la Mascota (ORDEN DE STACK ESTRICTO)
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _bounceAnimation.value),
                        child: child,
                      );
                    },
                    child: Container(
                      width: canvasSize.width,
                      height: canvasSize.height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: GarabuTheme.warmSand, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // 1. Fondo de cuaderno
                          const NotebookBackground(),

                          // 2. Imagen PNG del Cuerpo
                          _buildLayerImage(pet.bodyImageUrl, canvasSize),

                          // 3. Widgets de Ojos estáticos
                          StaticEyeOverlay(
                            position: pet.eyesConfig.leftEye,
                            canvasSize: canvasSize,
                            color: Color(pet.eyesConfig.color),
                            hasEyelashes: pet.eyesConfig.hasEyelashes,
                            isLeft: true,
                          ),
                          StaticEyeOverlay(
                            position: pet.eyesConfig.rightEye,
                            canvasSize: canvasSize,
                            color: Color(pet.eyesConfig.color),
                            hasEyelashes: pet.eyesConfig.hasEyelashes,
                            isLeft: false,
                          ),

                          // 4. Imagen PNG de la Prenda
                          if (pet.clothesImageUrl != null)
                            _buildLayerImage(pet.clothesImageUrl, canvasSize),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Botones de interacción y cuidado diario
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        icon: Icons.restaurant_rounded,
                        label: 'Alimentar',
                        onTap: () => _showActionFeedback(
                          '¡Yum yum! 🍖',
                          'Has alimentado a ${pet.name}. ¡Su vínculo se hace más fuerte!',
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.favorite_rounded,
                        label: 'Acariciar',
                        onTap: () => _showActionFeedback(
                          '¡Ronroneos! ❤️',
                          '${pet.name} sonríe feliz con tus caricias.',
                        ),
                      ),
                      _buildActionButton(
                        icon: Icons.checkroom_rounded,
                        label: 'Clóset',
                        onTap: () => _showActionFeedback(
                          'Clóset de Creaciones 👗',
                          'Próximamente: desbloquea slots para dibujar nuevos sombreros, accesorios y vestuarios personalizados.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GarabuTheme.warmSand),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: GarabuTheme.primaryBrown, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: GarabuTheme.deepEspresso,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
