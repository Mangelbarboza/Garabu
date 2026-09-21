import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/garabu_theme.dart';
import '../../../core/widgets/notebook_background.dart';
import '../../../core/widgets/garabu_image.dart';
import '../../auth/data/auth_repository.dart';
import '../../canvas/presentation/background_canvas_screen.dart';
import '../../canvas/presentation/fruit_canvas_screen.dart';
import '../../canvas/presentation/widgets/eye_widget.dart';
import '../../lobby/data/lobby_repository.dart';
import '../../lobby/domain/couple_model.dart';
import '../../mailbox/data/mailbox_repository.dart';
import '../../pet/data/pet_repository.dart';
import '../../pet/domain/pet_model.dart';
import 'widgets/closet_bottom_sheet.dart';
import 'widgets/feed_bottom_sheet.dart';
import 'widgets/mailbox_bottom_sheet.dart';

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
  // Animación de respiración suave
  late AnimationController _animController;
  late Animation<double> _bounceAnimation;

  // Animación de rebote elástico (Squash & Stretch) para caricias y alimentación
  late AnimationController _squashController;
  late Animation<double> _scaleXAnimation;
  late Animation<double> _scaleYAnimation;

  // Controlador único de parpadeo simultáneo para ambos ojos
  late AnimationController _blinkController;
  Timer? _blinkTimer;

  // Estados interactivos
  bool _isPetHappy = false;
  String? _speechBubbleText;
  Timer? _happyResetTimer;
  final List<_FloatingHeart> _particles = [];
  final Random _random = Random();
  int _lastStrokeTime = 0;

  // Alimentación interactiva (pegado al cursor / táctil)
  FruitInfo? _heldFruit;
  Offset _pointerPosition = Offset.zero;
  bool _isFeedingMouthHovered = false;
  bool _isChewing = false;
  bool _showFoodTray = false;
  final GlobalKey _petContainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    // 1. Respiración
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // 2. Squash & Stretch
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

    // 3. Parpadeo sincronizado simultáneo (ambos ojos parpadean exactamente al mismo tiempo)
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scheduleSimultaneousBlink();
  }

  void _scheduleSimultaneousBlink() {
    _blinkTimer?.cancel();
    final delayMs = 3200 + _random.nextInt(2400);
    _blinkTimer = Timer(Duration(milliseconds: delayMs), () async {
      if (!mounted) return;
      if (!_isPetHappy) {
        await _blinkController.forward();
        if (mounted) {
          await _blinkController.reverse();
        }
      }
      if (mounted) {
        _scheduleSimultaneousBlink();
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _squashController.dispose();
    _blinkController.dispose();
    _blinkTimer?.cancel();
    _happyResetTimer?.cancel();
    super.dispose();
  }

  void _triggerPetReaction(PetModel pet, {String? customMessage, Offset? tapOffset}) {
    if (pet.isSleeping) return; // No reacciona si está durmiendo profundamente

    _squashController.forward(from: 0.0);

    final center = tapOffset ?? const Offset(160, 160);
    final emojis = ['❤️', '💖', '✨', '🥰'];
    for (int i = 0; i < 4; i++) {
      final particle = _FloatingHeart(
        key: UniqueKey(),
        startOffset: center + Offset(_random.nextDouble() * 40 - 20, _random.nextDouble() * 20 - 10),
        emoji: emojis[_random.nextInt(emojis.length)],
        driftX: _random.nextDouble() * 50 - 25,
      );
      setState(() => _particles.add(particle));
    }

    final cuteMessages = [
      '¡Ronroneos de amor! 🥰',
      '¡A ${pet.name} le encantan tus caricias! ❤️',
      '¡Purrrr! ✨',
      '¡Qué rico se siente! 💕',
    ];

    setState(() {
      _isPetHappy = true;
      _speechBubbleText = customMessage ?? cuteMessages[_random.nextInt(cuteMessages.length)];
    });

    _happyResetTimer?.cancel();
    _happyResetTimer = Timer(const Duration(milliseconds: 2200), () {
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
    _feedPetDirectly(pet, fruit);
  }

  void _holdFruit(FruitInfo fruit, Offset initialPosition) {
    setState(() {
      _heldFruit = fruit;
      _pointerPosition = initialPosition;
      _isFeedingMouthHovered = false;
      _speechBubbleText = '¡Mmm, qué rica ${fruit.name.toLowerCase()}! 😮';
    });
  }

  void _checkMouthHover(Offset globalPos) {
    final renderBox = _petContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPos = renderBox.globalToLocal(globalPos);
      final size = renderBox.size;
      final isHovering = localPos.dx >= -10 &&
          localPos.dx <= size.width + 10 &&
          localPos.dy >= -10 &&
          localPos.dy <= size.height + 10;
      if (isHovering != _isFeedingMouthHovered) {
        setState(() {
          _isFeedingMouthHovered = isHovering;
        });
      }
    }
  }

  void _checkFeedHit(Offset globalPos, PetModel pet) {
    if (_heldFruit == null) return;
    final renderBox = _petContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPos = renderBox.globalToLocal(globalPos);
      final size = renderBox.size;
      if (localPos.dx >= -25 &&
          localPos.dx <= size.width + 25 &&
          localPos.dy >= -25 &&
          localPos.dy <= size.height + 25) {
        _feedPetDirectly(pet, _heldFruit!);
        return;
      }
    }
  }

  void _feedPetDirectly(PetModel pet, FruitInfo fruit) async {
    if (_heldFruit != null || _isFeedingMouthHovered) {
      setState(() {
        _heldFruit = null;
        _isFeedingMouthHovered = false;
      });
    }

    setState(() {
      _isChewing = true;
      _isPetHappy = true;
      _speechBubbleText = '¡Ñam! ¡Crunch crunch! ${fruit.emoji}';
    });

    // Masticar con 2 rebotes squash rápidos
    for (int i = 0; i < 2; i++) {
      if (!mounted) break;
      await _squashController.forward(from: 0.0);
    }

    if (mounted) {
      setState(() {
        _isChewing = false;
      });
    }

    final petRepo = ref.read(petRepositoryProvider);
    await petRepo.feedPet(petId: pet.id, fruitKey: fruit.key);

    _triggerPetReaction(
      pet,
      customMessage: '¡Deliciosa ${fruit.name.toLowerCase()}! ${fruit.emoji} A ${pet.name} le encantó',
    );
  }

  Widget _buildPetMouth(PetModel pet, Size canvasSize) {
    final mouthX = (pet.eyesConfig.leftEye.x + pet.eyesConfig.rightEye.x) / 2 * canvasSize.width;
    final mouthY = (max(pet.eyesConfig.leftEye.y, pet.eyesConfig.rightEye.y) + 0.08) * canvasSize.height;

    // 1. Boca abierta con lengüita cuando la comida se acerca a la boca/cuerpo
    if (_isFeedingMouthHovered) {
      return Positioned(
        left: mouthX - 18,
        top: mouthY - 10,
        child: Container(
          width: 36,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2420),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: GarabuTheme.primaryBrown.withValues(alpha: 0.4),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: 20,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFFF8A80),
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
              ),
            ),
          ),
        ),
      );
    }

    // 2. Masticando comida
    if (_isChewing) {
      return Positioned(
        left: mouthX - 14,
        top: mouthY - 6,
        child: Container(
          width: 28,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2420),
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    // 3. Sosteniendo una fruta cerca: boquita sonriente feliz
    if (_heldFruit != null) {
      return Positioned(
        left: mouthX - 14,
        top: mouthY - 5,
        child: CustomPaint(
          size: const Size(28, 12),
          painter: _PetSmilePainter(color: const Color(0xFF2C2420), isHappy: true),
        ),
      );
    }

    // 4. Modo normal: sonrisa tranquila
    return Positioned(
      left: mouthX - 12,
      top: mouthY - 4,
      child: CustomPaint(
        size: const Size(24, 10),
        painter: _PetSmilePainter(color: const Color(0xFF2C2420), isHappy: _isPetHappy),
      ),
    );
  }

  void _onWaterGiven(PetModel pet) async {
    final petRepo = ref.read(petRepositoryProvider);
    await petRepo.waterPet(petId: pet.id);

    _triggerPetReaction(
      pet,
      customMessage: '¡Glup glup! 💧 ${pet.name} está bien hidratado',
    );
  }

  void _toggleLight(PetModel pet) async {
    final petRepo = ref.read(petRepositoryProvider);
    final willSleep = !pet.isSleeping;
    await petRepo.toggleSleep(petId: pet.id, isSleeping: willSleep);

    setState(() {
      _speechBubbleText = willSleep ? 'Zzz... Buenas noches' : '¡Buenos días! ☀️';
    });

    _happyResetTimer?.cancel();
    _happyResetTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _speechBubbleText = null);
    });
  }

  bool _isSatisfied(DateTime? lastTime, int maxHours) {
    if (lastTime == null) return false;
    return DateTime.now().difference(lastTime).inHours < maxHours;
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
    final lettersAsync = ref.watch(lettersProvider(currentCouple.id));
    final unreadLettersCount = lettersAsync.value?.where((l) => !l.isRead && l.senderId != ref.read(currentUserProvider)?.id).length ?? 0;

    return Scaffold(
      backgroundColor: GarabuTheme.background,
      appBar: AppBar(
        title: Text('${currentCouple.user1Name} & ${currentCouple.user2Name ?? "Pareja"}'),
        actions: [
          // Racha minimalista con fuego y número
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: GarabuTheme.warmSand.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '${currentCouple.streak}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: GarabuTheme.deepEspresso,
                  ),
                ),
              ],
            ),
          ),
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
            final isWideScreen = screenWidth >= 780;
            final petBoxSize = (screenWidth - 48).clamp(280.0, 420.0);
            final canvasSize = Size(petBoxSize, petBoxSize);

            final hasFood = _isSatisfied(pet.lastFedAt, 4);
            final hasWater = _isSatisfied(pet.lastWateredAt, 4);

            final petContainerWidget = DragTarget<FruitInfo>(
              onWillAcceptWithDetails: (details) {
                setState(() => _isFeedingMouthHovered = true);
                return true;
              },
              onLeave: (_) {
                setState(() => _isFeedingMouthHovered = false);
              },
              onAcceptWithDetails: (details) {
                _feedPetDirectly(pet, details.data);
              },
              builder: (context, candidateData, rejectedData) {
                return AnimatedBuilder(
                  animation: Listenable.merge([_bounceAnimation, _squashController]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, pet.isSleeping ? 0.0 : _bounceAnimation.value),
                      child: Transform.scale(
                        scaleX: _scaleXAnimation.value,
                        scaleY: _scaleYAnimation.value,
                        child: child,
                      ),
                    );
                  },
                  child: GestureDetector(
                    onTapDown: (details) {
                      if (_heldFruit != null) {
                        _feedPetDirectly(pet, _heldFruit!);
                      } else {
                        _triggerPetReaction(pet, tapOffset: details.localPosition);
                      }
                    },
                    onPanUpdate: (details) => _onPetStroke(pet, details.localPosition),
                    child: Container(
                      key: _petContainerKey,
                      width: canvasSize.width,
                      height: canvasSize.height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isFeedingMouthHovered ? GarabuTheme.primaryBrown : GarabuTheme.warmSand,
                          width: _isFeedingMouthHovered ? 2.5 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _isFeedingMouthHovered
                                ? GarabuTheme.primaryBrown.withValues(alpha: 0.25)
                                : Colors.black.withValues(alpha: 0.06),
                            blurRadius: _isFeedingMouthHovered ? 24 : 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Stack(
                        children: [
                          // 1. Fondo (Fondo personalizado dibujado o cuaderno clásico)
                          if (pet.backgroundUrl != null && pet.backgroundUrl!.isNotEmpty)
                            GarabuImage(
                              imageUrl: pet.backgroundUrl,
                              width: canvasSize.width,
                              height: canvasSize.height,
                              fit: BoxFit.cover,
                            )
                          else
                            const NotebookBackground(),

                          // Filtro de luz apagada (Noche / Modo dormir)
                          if (pet.isSleeping)
                            Container(
                              color: const Color(0xCC121824),
                              width: canvasSize.width,
                              height: canvasSize.height,
                            ),

                          // 2. Cuerpo dibujado
                          GarabuImage(
                            imageUrl: pet.bodyImageUrl,
                            width: canvasSize.width,
                            height: canvasSize.height,
                            fit: BoxFit.contain,
                          ),

                          // 3. Ojos con parpadeo SIMULTÁNEO coordinado
                          AnimatedBuilder(
                            animation: _blinkController,
                            builder: (context, _) {
                              final double progress = pet.isSleeping ? 1.0 : _blinkController.value;
                              return Stack(
                                children: [
                                  StaticEyeOverlay(
                                    position: pet.eyesConfig.leftEye,
                                    canvasSize: canvasSize,
                                    color: Color(pet.eyesConfig.color),
                                    hasEyelashes: pet.eyesConfig.hasEyelashes,
                                    isLeft: true,
                                    blinkProgress: progress,
                                    isHappy: _isPetHappy,
                                  ),
                                  StaticEyeOverlay(
                                    position: pet.eyesConfig.rightEye,
                                    canvasSize: canvasSize,
                                    color: Color(pet.eyesConfig.color),
                                    hasEyelashes: pet.eyesConfig.hasEyelashes,
                                    isLeft: false,
                                    blinkProgress: progress,
                                    isHappy: _isPetHappy,
                                  ),
                                ],
                              );
                            },
                          ),

                          // 3.5 Boca expresiva reactiva a la comida y caricias
                          _buildPetMouth(pet, canvasSize),

                          // 4. Prenda activa del Clóset anclada al cuerpo
                          if (pet.clothesImageUrl != null && pet.clothesImageUrl!.isNotEmpty)
                            GarabuImage(
                              imageUrl: pet.clothesImageUrl,
                              width: canvasSize.width,
                              height: canvasSize.height,
                              fit: BoxFit.contain,
                            ),

                      // 5. Partículas flotantes de caricias
                      ..._particles.map(
                        (p) => _ParticleWidget(
                          key: p.key,
                          particle: p,
                          onDismissed: () {
                            setState(() => _particles.removeWhere((item) => item.key == p.key));
                          },
                        ),
                      ),

                      // 6. Globo de diálogo o Zzz si duerme
                      if (_speechBubbleText != null || pet.isSleeping)
                        Positioned(
                          top: 12,
                          left: 16,
                          right: 16,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: pet.isSleeping ? const Color(0xFF1E2638) : Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: pet.isSleeping ? const Color(0xFF5C6BC0) : GarabuTheme.primaryBrown,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                pet.isSleeping ? 'Zzz...' : _speechBubbleText!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: pet.isSleeping ? const Color(0xFFC5CAE9) : GarabuTheme.deepEspresso,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );

            final needsPanelWidget = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GarabuTheme.warmSand),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Estado',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Comida
                  _buildStatusRow(
                    icon: Icons.restaurant_outlined,
                    label: 'Comida',
                    value: hasFood ? 'Satisfecho' : 'Hambre',
                    isGood: hasFood,
                  ),
                  const SizedBox(height: 10),
                  // Sed
                  _buildStatusRow(
                    icon: Icons.water_drop_outlined,
                    label: 'Sed',
                    value: hasWater ? 'Hidratado' : 'Con sed',
                    isGood: hasWater,
                  ),
                  const SizedBox(height: 10),
                  // Sueño
                  _buildStatusRow(
                    icon: pet.isSleeping ? Icons.bedtime_rounded : Icons.wb_sunny_outlined,
                    label: 'Sueño',
                    value: pet.isSleeping ? 'Durmiendo' : 'Despierto',
                    isGood: !pet.isSleeping,
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: GarabuTheme.warmSand),
                  const SizedBox(height: 14),
                  // Interruptor de Luz (Apagar / Encender la luz)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: pet.isSleeping ? const Color(0xFF1E2638) : Colors.white,
                        foregroundColor: pet.isSleeping ? Colors.white : GarabuTheme.deepEspresso,
                        side: BorderSide(
                          color: pet.isSleeping ? const Color(0xFF5C6BC0) : GarabuTheme.warmSand,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => _toggleLight(pet),
                      icon: Icon(
                        pet.isSleeping ? Icons.lightbulb : Icons.lightbulb_outline_rounded,
                        size: 18,
                        color: pet.isSleeping ? const Color(0xFFFFD54F) : GarabuTheme.primaryBrown,
                      ),
                      label: Text(
                        pet.isSleeping ? 'Encender la luz' : 'Apagar la luz',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );

            return MouseRegion(
              onHover: (event) {
                if (_heldFruit != null) {
                  setState(() => _pointerPosition = event.position);
                  _checkMouthHover(event.position);
                }
              },
              child: Listener(
                behavior: HitTestBehavior.translucent,
                onPointerDown: (event) {
                  if (_heldFruit != null) {
                    setState(() => _pointerPosition = event.position);
                    _checkMouthHover(event.position);
                  }
                },
                onPointerMove: (event) {
                  if (_heldFruit != null) {
                    setState(() => _pointerPosition = event.position);
                    _checkMouthHover(event.position);
                  }
                },
                onPointerUp: (event) {
                  if (_heldFruit != null) {
                    _checkFeedHit(event.position, pet);
                  }
                },
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      child: Column(
                        children: [
                          // Nombre de la Mascota
                          Text(
                            pet.name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: GarabuTheme.deepEspresso,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Contenido principal (En PC en 2 columnas, en Móvil en columna única)
                          if (isWideScreen) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                petContainerWidget,
                                const SizedBox(width: 28),
                                SizedBox(width: 220, child: needsPanelWidget),
                              ],
                            ),
                            if (_showFoodTray) ...[
                              const SizedBox(height: 20),
                              Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(maxWidth: 680),
                                  child: _buildFoodTray(pet),
                                ),
                              ),
                            ],
                          ] else ...[
                            petContainerWidget,
                            if (_showFoodTray) ...[
                              const SizedBox(height: 16),
                              _buildFoodTray(pet),
                            ],
                            const SizedBox(height: 16),
                            needsPanelWidget,
                          ],

                          const SizedBox(height: 24),

                          // Botones de acción principales (Alimentar, Clóset, Buzón, Fondos)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // 1. Alimentar
                              _buildActionButton(
                                icon: Icons.restaurant_rounded,
                                label: 'Alimentar',
                                badgeText: '${pet.drawnFruits.length}/6',
                                isSelected: _showFoodTray,
                                onTap: () {
                                  setState(() {
                                    _showFoodTray = !_showFoodTray;
                                  });
                                },
                              ),

                              // 2. Clóset
                              _buildActionButton(
                                icon: Icons.checkroom_rounded,
                                label: 'Clóset',
                                badgeText: '${pet.closet.length}/5',
                                onTap: () => ClosetBottomSheet.show(context, currentCouple, pet),
                              ),

                              // 3. Buzón de cartas
                              _buildActionButton(
                                icon: Icons.mark_email_unread_outlined,
                                label: 'Buzón',
                                badgeText: unreadLettersCount > 0 ? '$unreadLettersCount' : null,
                                badgeColor: unreadLettersCount > 0 ? const Color(0xFFE53935) : null,
                                onTap: () => MailboxBottomSheet.show(context, currentCouple),
                              ),

                              // 4. Fondos
                              _buildActionButton(
                                icon: Icons.wallpaper_rounded,
                                label: 'Fondos',
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => BackgroundCanvasScreen(pet: pet),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Barra flotante de guía al sostener comida
                    if (_heldFruit != null)
                      Positioned(
                        top: 10,
                        left: 16,
                        right: 16,
                        child: SafeArea(
                          child: Material(
                            elevation: 6,
                            borderRadius: BorderRadius.circular(20),
                            color: GarabuTheme.paperWhite,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Row(
                                children: [
                                  Text(_heldFruit!.emoji, style: const TextStyle(fontSize: 22)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Lleva la ${_heldFruit!.name.toLowerCase()} a la boca de ${pet.name}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: GarabuTheme.deepEspresso,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Cancelar',
                                    icon: const Icon(Icons.close_rounded, size: 20, color: GarabuTheme.textSecondary),
                                    onPressed: () {
                                      setState(() {
                                        _heldFruit = null;
                                        _isFeedingMouthHovered = false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Fruta dibujada a mano que se queda pegada al mouse / toque táctil
                    if (_heldFruit != null)
                      Positioned(
                        left: _pointerPosition.dx - 32,
                        top: _pointerPosition.dy - 32,
                        child: IgnorePointer(
                          child: Material(
                            color: Colors.transparent,
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: GarabuTheme.primaryBrown.withValues(alpha: 0.35),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: pet.drawnFruits[_heldFruit!.key] != null
                                  ? GarabuImage(
                                      imageUrl: pet.drawnFruits[_heldFruit!.key]!,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.contain,
                                    )
                                  : Center(
                                      child: Text(
                                        _heldFruit!.emoji,
                                        style: const TextStyle(fontSize: 42),
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFoodTray(PetModel pet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: GarabuTheme.warmSand, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('🍎', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    'Comida para ${pet.name}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _onWaterGiven(pet),
                    icon: const Text('💧', style: TextStyle(fontSize: 15)),
                    label: const Text('Dar Agua', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    tooltip: 'Ver todas en lista',
                    icon: const Icon(Icons.list_alt_rounded, size: 18, color: GarabuTheme.textSecondary),
                    onPressed: () => FeedBottomSheet.show(
                      context: context,
                      pet: pet,
                      onFruitFed: (fruit) => _onFruitFed(pet, fruit),
                      onWaterGiven: () => _onWaterGiven(pet),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar comida',
                    icon: const Icon(Icons.close_rounded, size: 18, color: GarabuTheme.textSecondary),
                    onPressed: () => setState(() => _showFoodTray = false),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'Toca o arrastra una fruta hacia la boca de tu mascota',
            style: TextStyle(
              fontSize: 12,
              color: GarabuTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 116,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: kAvailableFruits.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final fruit = kAvailableFruits[index];
                final isDrawn = pet.drawnFruits.containsKey(fruit.key);
                final imageUrl = pet.drawnFruits[fruit.key];

                if (isDrawn && imageUrl != null) {
                  final fruitCard = Container(
                    width: 86,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: GarabuTheme.paperWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GarabuTheme.primaryBrown, width: 1.5),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: GarabuImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                fruit.name,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: GarabuTheme.deepEspresso,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Botón para editar la fruta dibujada
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FruitCanvasScreen(pet: pet, fruit: fruit),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: GarabuTheme.warmSand.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 13,
                                  color: GarabuTheme.primaryBrown,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );

                  return Draggable<FruitInfo>(
                    data: fruit,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: GarabuTheme.primaryBrown.withValues(alpha: 0.35),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: GarabuImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.4,
                      child: fruitCard,
                    ),
                    child: GestureDetector(
                      onTapDown: (details) {
                        _holdFruit(fruit, details.globalPosition);
                      },
                      child: fruitCard,
                    ),
                  );
                } else {
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => FruitCanvasScreen(pet: pet, fruit: fruit),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 86,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: GarabuTheme.paperWhite.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: GarabuTheme.warmSand),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            fruit.emoji,
                            style: TextStyle(
                              fontSize: 26,
                              color: Colors.grey.withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fruit.name,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: GarabuTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: GarabuTheme.warmSand.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              '+ Dibujar',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: GarabuTheme.primaryBrown,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isGood,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: GarabuTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: GarabuTheme.textSecondary),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isGood ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: isGood ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    String? badgeText,
    Color? badgeColor,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? GarabuTheme.warmSand.withValues(alpha: 0.25) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? GarabuTheme.primaryBrown : GarabuTheme.warmSand,
            width: isSelected ? 2.0 : 1.0,
          ),
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
                Icon(icon, color: GarabuTheme.primaryBrown, size: 24),
                if (badgeText != null)
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeColor ?? GarabuTheme.warmSand,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: badgeColor != null ? Colors.white : GarabuTheme.deepEspresso,
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
                fontSize: 12,
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

class _PetSmilePainter extends CustomPainter {
  final Color color;
  final bool isHappy;

  _PetSmilePainter({required this.color, required this.isHappy});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = isHappy ? 2.5 : 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.2);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height * 0.2,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PetSmilePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.isHappy != isHappy;
}

