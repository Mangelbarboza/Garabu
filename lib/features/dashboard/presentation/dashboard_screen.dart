import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/garabu_theme.dart';
import '../../../core/widgets/notebook_background.dart';
import '../../auth/data/auth_repository.dart';
import '../../canvas/presentation/fruit_canvas_screen.dart';
import '../../canvas/presentation/widgets/eye_widget.dart';
import '../../lobby/data/lobby_repository.dart';
import '../../lobby/domain/couple_model.dart';
import '../../pet/data/pet_repository.dart';
import '../../pet/domain/pet_model.dart';
import 'widgets/closet_bottom_sheet.dart';
import 'widgets/feed_bottom_sheet.dart';

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
    with TickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _bounceAnimation;

  // Animación de rebote elástico (Squash & Stretch) para caricias y comida
  late AnimationController _squashController;
  late Animation<double> _scaleXAnimation;
  late Animation<double> _scaleYAnimation;

  // Estados de interacción
  bool _isPetHappy = false;
  String? _speechBubbleText;
  Timer? _happyResetTimer;
  final List<_FloatingHeart> _particles = [];
  final Random _random = Random();
  int _lastStrokeTime = 0;

  @override
  void initState() {
    super.initState();
    // 1. Animación suave de respiración
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // 2. Animación de rebote elástico (Squash & Stretch)
    _squashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scaleXAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.14).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.14, end: 0.94).chain(CurveTween(curve: Curves.easeInOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 30),
    ]).animate(_squashController);

    _scaleYAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.86).chain(CurveTween(curve: Curves.easeOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.86, end: 1.06).chain(CurveTween(curve: Curves.easeInOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.06, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 30),
    ]).animate(_squashController);
  }

  @override
  void dispose() {
    _animController.dispose();
    _squashController.dispose();
    _happyResetTimer?.cancel();
    super.dispose();
  }

  void _triggerPetReaction(PetModel pet, {String? customMessage, Offset? tapOffset}) {
    _squashController.forward(from: 0.0);

    // Generar partículas de corazones y estrellas
    final center = tapOffset ?? const Offset(160, 160);
    final emojis = ['❤️', '💖', '✨', '🥰', '💕'];
    for (int i = 0; i < 4; i++) {
      final particle = _FloatingHeart(
        key: UniqueKey(),
        startOffset: center + Offset(_random.nextDouble() * 40 - 20, _random.nextDouble() * 20 - 10),
        emoji: emojis[_random.nextInt(emojis.length)],
        driftX: _random.nextDouble() * 50 - 25,
      );
      setState(() {
        _particles.add(particle);
      });
    }

    final cuteMessages = [
      '¡Ronroneos de amor! 🥰',
      '¡A ${pet.name} le encantan tus caricias! ❤️',
      '¡Purrrr! ✨',
      '¡Qué rico se siente! 💕',
      '${pet.name} sonríe muy feliz 🥰',
    ];

    setState(() {
      _isPetHappy = true;
      _speechBubbleText = customMessage ?? cuteMessages[_random.nextInt(cuteMessages.length)];
    });

    _happyResetTimer?.cancel();
    _happyResetTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) {
        setState(() {
          _isPetHappy = false;
          _speechBubbleText = null;
        });
      }
    });
  }

  void _onPetStroke(PetModel pet, Offset localPosition) {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastStrokeTime > 280) {
      _lastStrokeTime = now;
      _triggerPetReaction(pet, tapOffset: localPosition);
    }
  }

  void _onFruitFed(PetModel pet, FruitInfo fruit) async {
    final petRepo = ref.read(petRepositoryProvider);
    await petRepo.feedPet(petId: pet.id, fruitKey: fruit.key);

    _triggerPetReaction(
      pet,
      customMessage: '¡Ñam ñam! ${fruit.emoji} ¡A ${pet.name} le fascinó la ${fruit.name.toLowerCase()}!',
    );
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
                  const SizedBox(height: 16),

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
                    '¡Toca o acaricia tu garabato para mimarlo!',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: GarabuTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contenedor Apilado de la Mascota con interacción táctil y física elástica
                  AnimatedBuilder(
                    animation: Listenable.merge([_bounceAnimation, _squashController]),
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _bounceAnimation.value),
                        child: Transform.scale(
                          scaleX: _scaleXAnimation.value,
                          scaleY: _scaleYAnimation.value,
                          child: child,
                        ),
                      );
                    },
                    child: GestureDetector(
                      onTapDown: (details) => _triggerPetReaction(pet, tapOffset: details.localPosition),
                      onPanUpdate: (details) => _onPetStroke(pet, details.localPosition),
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

                            // 3. Ojos animados con parpadeo periódico y reacción sonriente
                            BlinkingEyeOverlay(
                              position: pet.eyesConfig.leftEye,
                              canvasSize: canvasSize,
                              color: Color(pet.eyesConfig.color),
                              hasEyelashes: pet.eyesConfig.hasEyelashes,
                              isLeft: true,
                              isHappy: _isPetHappy,
                            ),
                            BlinkingEyeOverlay(
                              position: pet.eyesConfig.rightEye,
                              canvasSize: canvasSize,
                              color: Color(pet.eyesConfig.color),
                              hasEyelashes: pet.eyesConfig.hasEyelashes,
                              isLeft: false,
                              isHappy: _isPetHappy,
                            ),

                            // 4. Imagen PNG de la Prenda activa del clóset
                            if (pet.clothesImageUrl != null)
                              _buildLayerImage(pet.clothesImageUrl, canvasSize),

                            // 5. Partículas flotantes de corazones al acariciar
                            ..._particles.map(
                              (p) => _ParticleWidget(
                                key: p.key,
                                particle: p,
                                onDismissed: () {
                                  setState(() {
                                    _particles.removeWhere((item) => item.key == p.key);
                                  });
                                },
                              ),
                            ),

                            // 6. Globo de diálogo tierno de reacción
                            if (_speechBubbleText != null)
                              Positioned(
                                top: 12,
                                left: 16,
                                right: 16,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: GarabuTheme.primaryBrown, width: 1.5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      _speechBubbleText!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: GarabuTheme.deepEspresso,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Botones de interacción y cuidado diario
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Botón Alimentar (Abre selector de frutas)
                      _buildActionButton(
                        icon: Icons.restaurant_rounded,
                        label: 'Alimentar',
                        badgeText: '${pet.drawnFruits.length}/6',
                        onTap: () => FeedBottomSheet.show(
                          context: context,
                          pet: pet,
                          onFruitFed: (fruit) => _onFruitFed(pet, fruit),
                        ),
                      ),

                      // Botón Acariciar (Activa animación y corazones)
                      _buildActionButton(
                        icon: Icons.favorite_rounded,
                        label: 'Acariciar',
                        onTap: () => _triggerPetReaction(pet),
                      ),

                      // Botón Clóset (Abre los 5 slots interactivos)
                      _buildActionButton(
                        icon: Icons.checkroom_rounded,
                        label: 'Clóset',
                        badgeText: '${pet.closet.length}/5',
                        onTap: () => ClosetBottomSheet.show(context, currentCouple, pet),
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
    String? badgeText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 96,
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: GarabuTheme.primaryBrown, size: 26),
                if (badgeText != null)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: GarabuTheme.warmSand,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: GarabuTheme.deepEspresso,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
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

class _FloatingHeart {
  final Key key;
  final Offset startOffset;
  final String emoji;
  final double driftX;

  _FloatingHeart({
    required this.key,
    required this.startOffset,
    required this.emoji,
    required this.driftX,
  });
}

class _ParticleWidget extends StatefulWidget {
  final _FloatingHeart particle;
  final VoidCallback onDismissed;

  const _ParticleWidget({
    super.key,
    required this.particle,
    required this.onDismissed,
  });

  @override
  State<_ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<_ParticleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _translateYAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    _translateYAnimation = Tween<double>(begin: 0.0, end: -60.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward().then((_) {
      if (mounted) {
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value;
        final currentX = widget.particle.startOffset.dx + (widget.particle.driftX * progress);
        final currentY = widget.particle.startOffset.dy + _translateYAnimation.value;

        return Positioned(
          left: currentX,
          top: currentY,
          child: Opacity(
            opacity: _fadeAnimation.value.clamp(0.0, 1.0),
            child: Text(
              widget.particle.emoji,
              style: const TextStyle(fontSize: 22),
            ),
          ),
        );
      },
    );
  }
}
