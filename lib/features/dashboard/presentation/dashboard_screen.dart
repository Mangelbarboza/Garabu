import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/garabu_theme.dart';
import '../../../core/widgets/notebook_background.dart';
import '../../../core/widgets/garabu_image.dart';
import '../../auth/data/auth_repository.dart';
import '../../canvas/presentation/background_canvas_screen.dart';
import '../../canvas/presentation/body_canvas_screen.dart';
import '../../canvas/presentation/fruit_canvas_screen.dart';
import '../../canvas/presentation/widgets/eye_widget.dart';
import '../../lobby/data/lobby_repository.dart';
import '../../lobby/domain/couple_model.dart';
import '../../mailbox/data/mailbox_repository.dart';
import '../../pet/data/pet_repository.dart';
import '../../pet/domain/pet_model.dart';
import 'widgets/closet_bottom_sheet.dart';
import 'widgets/feed_bottom_sheet.dart';
import 'widgets/game_center_bottom_sheet.dart';
import 'widgets/language_bottom_sheet.dart';
import 'widgets/mailbox_bottom_sheet.dart';
import 'widgets/pet_vital_bars.dart';
import 'widgets/shop_bottom_sheet.dart';
import '../../settings/presentation/settings_bottom_sheet.dart';

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
  // Animación de respiración suave y flotación
  late AnimationController _animController;
  late Animation<double> _bounceAnimation;

  // Animación de Squash & Stretch para masticar / saltito
  late AnimationController _squashController;
  late Animation<double> _scaleXAnimation;
  late Animation<double> _scaleYAnimation;

  // Animación continua y fluida de ronroneo al acariciar (purr)
  late AnimationController _purrController;
  late Animation<double> _purrScaleAnimation;
  late Animation<double> _purrRotateAnimation;

  // Controlador único de parpadeo sincronizado simultáneo
  late AnimationController _blinkController;
  Timer? _blinkTimer;

  // Estados interactivos
  bool _isPetHappy = false;
  String? _speechBubbleText;
  Timer? _happyResetTimer;
  Timer? _happyStopTimer;
  final ValueNotifier<List<_SketchParticleData>> _particlesNotifier =
      ValueNotifier<List<_SketchParticleData>>([]);
  final Random _random = Random();
  int _lastParticleTime = 0;
  int _lastPettedDbTime = 0;

  // Desplegable de estadísticas en móviles
  bool _showStatsDrawer = false;

  // Alimentación interactiva (pegado al cursor / táctil)
  FruitInfo? _heldFruit;
  Offset _pointerPosition = Offset.zero;
  bool _isFeedingMouthHovered = false;
  bool _isChewing = false;
  final GlobalKey _petContainerKey = GlobalKey();

  final List<String> _cutePurrMessages = [
    '¡Ronroneos de felicidad!',
    '¡Qué ricas caricias!',
    '¡Te quiero mucho!',
    '¡Qué cosquillas tan suaves!',
  ];

  @override
  void initState() {
    super.initState();

    // 1. Respiración suave
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0.0, end: -6.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    // 2. Squash & Stretch para comer
    _squashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _scaleXAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.12).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.95).chain(CurveTween(curve: Curves.easeInOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
    ]).animate(_squashController);

    _scaleYAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.05).chain(CurveTween(curve: Curves.easeInOut)), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0).chain(CurveTween(curve: Curves.easeOut)), weight: 25),
    ]).animate(_squashController);

    // 3. Ronroneo continuo y fluido al acariciar (sin tirones)
    _purrController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _purrScaleAnimation = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _purrController, curve: Curves.easeInOut),
    );

    _purrRotateAnimation = Tween<double>(begin: -0.015, end: 0.015).animate(
      CurvedAnimation(parent: _purrController, curve: Curves.easeInOut),
    );

    // 4. Parpadeo sincronizado simultáneo
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 130),
    );
    _scheduleSimultaneousBlink();

    // 5. Verificar y actualizar racha diaria del calendario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(lobbyRepositoryProvider).verifyAndUpdateDailyStreak(widget.couple.id);
      }
    });
  }

  void _triggerInteraction() {
    final user = ref.read(currentUserProvider);
    if (user != null) {
      ref.read(lobbyRepositoryProvider).recordUserInteraction(
        coupleId: widget.couple.id,
        userId: user.id,
      );
    }
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
    _purrController.dispose();
    _blinkController.dispose();
    _particlesNotifier.dispose();
    _blinkTimer?.cancel();
    _happyResetTimer?.cancel();
    _happyStopTimer?.cancel();
    super.dispose();
  }

  void _spawnSketchParticle(Offset origin) {
    const colors = [
      Color(0xFFE57373), // Rosa rojizo suave
      Color(0xFFF06292), // Rosa pastel
      Color(0xFFFBC02D), // Dorado estrella
      Color(0xFFFFB74D), // Ámbar cálido
    ];

    final isHeart = _random.nextBool();
    final particle = _SketchParticleData(
      key: UniqueKey(),
      startOffset: origin + Offset(_random.nextDouble() * 30 - 15, _random.nextDouble() * 16 - 8),
      type: isHeart ? _ParticleType.heart : _ParticleType.star,
      driftX: _random.nextDouble() * 40 - 20,
      color: colors[_random.nextInt(colors.length)],
    );

    final current = List<_SketchParticleData>.from(_particlesNotifier.value);
    current.add(particle);
    if (current.length > 12) {
      current.removeAt(0);
    }
    _particlesNotifier.value = current;
  }

  void _onPetStroke(PetModel pet, Offset localPosition) {
    if (pet.isSleeping) return;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Generar partículas fluidas cada 140ms
    if (now - _lastParticleTime > 140) {
      _lastParticleTime = now;
      _spawnSketchParticle(localPosition);
    }

    // Iniciar oscilación fluida de ronroneo si no está activa
    if (!_purrController.isAnimating) {
      _purrController.repeat(reverse: true);
    }

    _happyStopTimer?.cancel();
    if (!_isPetHappy) {
      String phrase;
      if (pet.customPhrases.isNotEmpty && _random.nextDouble() < 0.6) {
        phrase = pet.customPhrases[_random.nextInt(pet.customPhrases.length)];
      } else {
        phrase = _cutePurrMessages[_random.nextInt(_cutePurrMessages.length)];
      }
      setState(() {
        _isPetHappy = true;
        _speechBubbleText = phrase;
      });
    }

    // Detener suavemente cuando el usuario suelta el dedo
    _happyStopTimer = Timer(const Duration(milliseconds: 650), () {
      if (mounted) {
        _purrController.animateTo(0.0, duration: const Duration(milliseconds: 180));

        // Actualizar Firestore SOLO al finalizar la sesión de caricias (debounce 12s)
        final strokeDoneNow = DateTime.now().millisecondsSinceEpoch;
        if (strokeDoneNow - _lastPettedDbTime > 12000) {
          _lastPettedDbTime = strokeDoneNow;
          ref.read(petRepositoryProvider).petAnimal(petId: pet.id);
          _triggerInteraction();
        }

        _happyResetTimer?.cancel();
        _happyResetTimer = Timer(const Duration(milliseconds: 1200), () {
          if (mounted) {
            setState(() {
              _isPetHappy = false;
              _speechBubbleText = null;
            });
          }
        });
      }
    });
  }

  void _onFruitFed(PetModel pet, FruitInfo fruit) {
    // Al seleccionar una fruta de la mochila, se queda pegada al cursor/toque para dársela en la boca
    final renderBox = _petContainerKey.currentContext?.findRenderObject() as RenderBox?;
    Offset center = const Offset(200, 300);
    if (renderBox != null) {
      center = renderBox.localToGlobal(renderBox.size.bottomCenter(Offset.zero) - const Offset(0, 40));
    }
    _holdFruit(fruit, center);
  }

  void _holdFruit(FruitInfo fruit, Offset initialPosition) {
    setState(() {
      _heldFruit = fruit;
      _pointerPosition = initialPosition;
      _isFeedingMouthHovered = false;
      _speechBubbleText = '¡Mmm, qué rica ${fruit.name.toLowerCase()}!';
    });
  }

  void _checkMouthHover(Offset globalPos, PetModel pet) {
    final renderBox = _petContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final localPos = renderBox.globalToLocal(globalPos);
      final size = renderBox.size;
      final mouthPos = Offset(
        pet.eyesConfig.resolvedMouth.x * size.width,
        pet.eyesConfig.resolvedMouth.y * size.height,
      );
      final distance = (localPos - mouthPos).distance;
      final isHovering = distance < 70.0;
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

    String fedPhrase;
    if (pet.customPhrases.isNotEmpty && _random.nextDouble() < 0.5) {
      fedPhrase = pet.customPhrases[_random.nextInt(pet.customPhrases.length)];
    } else if (fruit.key == 'agua') {
      fedPhrase = '¡Glup glup! ¡Qué frescura!';
    } else {
      fedPhrase = '¡Ñam! ¡Crunch crunch!';
    }

    setState(() {
      _isChewing = true;
      _isPetHappy = true;
      _speechBubbleText = fedPhrase;
    });

    // Masticar con 2 rebotes
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
    _triggerInteraction();

    _spawnSketchParticle(const Offset(160, 160));
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

  void _onWaterGiven(PetModel pet) async {
    final petRepo = ref.read(petRepositoryProvider);
    await petRepo.waterPet(petId: pet.id);
    _triggerInteraction();

    setState(() {
      _isPetHappy = true;
      _speechBubbleText = '¡Glup glup! Bien hidratado';
    });

    _spawnSketchParticle(const Offset(160, 160));
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

  void _toggleLight(PetModel pet) async {
    final petRepo = ref.read(petRepositoryProvider);
    final willSleep = !pet.isSleeping;
    await petRepo.toggleSleep(petId: pet.id, isSleeping: willSleep);
    _triggerInteraction();

    setState(() {
      _speechBubbleText = willSleep ? 'Zzz... Buenas noches' : '¡Buenos días!';
    });

    _happyResetTimer?.cancel();
    _happyResetTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) setState(() => _speechBubbleText = null);
    });
  }

  PetEmotion _resolvePetEmotion(PetModel pet) {
    if (pet.isSleeping) return PetEmotion.sleeping;
    if (_isChewing || _isFeedingMouthHovered) return PetEmotion.eating;
    if (pet.isSick) return PetEmotion.sad;
    if (_isPetHappy) return PetEmotion.happy;
    if (pet.hunger < 0.15) return PetEmotion.hungry;
    if (pet.thirst < 0.15) return PetEmotion.thirsty;
    if (pet.happiness < 0.15 || pet.energy < 0.15) return PetEmotion.sad;
    return PetEmotion.neutral;
  }

  Offset _calculateLookDirection(Size canvasSize) {
    if (_heldFruit == null) return Offset.zero;
    final renderBox = _petContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;
    final localPos = renderBox.globalToLocal(_pointerPosition);
    final petCenterX = canvasSize.width * 0.5;
    final petCenterY = canvasSize.height * 0.45;
    final dx = ((localPos.dx - petCenterX) / (canvasSize.width * 0.35)).clamp(-1.0, 1.0);
    final dy = ((localPos.dy - petCenterY) / (canvasSize.height * 0.35)).clamp(-1.0, 1.0);
    return Offset(dx, dy);
  }

  Widget _buildPetMouth(PetModel pet, Size canvasSize, PetEmotion emotion) {
    final mouthPoint = pet.eyesConfig.resolvedMouth;
    final mouthX = mouthPoint.x * canvasSize.width;
    final mouthY = mouthPoint.y * canvasSize.height;

    return Positioned(
      left: mouthX - 16,
      top: mouthY - 8,
      child: MouthWidget(
        size: 32,
        isOpen: _isFeedingMouthHovered || _isChewing,
        isChewing: _isChewing,
        emotion: emotion,
      ),
    );
  }

  List<Widget> _buildEquippedGarments(PetModel pet, Size canvasSize) {
    final equippedIds = pet.resolvedEquippedGarmentIds;
    if (equippedIds.isEmpty) {
      if (pet.clothesImageUrl != null && pet.clothesImageUrl!.isNotEmpty) {
        return [
          GarabuImage(
            imageUrl: pet.clothesImageUrl,
            width: canvasSize.width,
            height: canvasSize.height,
            fit: BoxFit.contain,
          ),
        ];
      }
      return const [];
    }

    final widgets = <Widget>[];
    for (final id in equippedIds) {
      final garment = pet.closet.cast<GarmentItem?>().firstWhere(
        (g) => g?.id == id,
        orElse: () => null,
      );
      if (garment != null && garment.imageUrl.isNotEmpty) {
        widgets.add(
          Transform.translate(
            offset: Offset(garment.offsetX, garment.offsetY),
            child: Transform.rotate(
              angle: garment.rotation,
              child: Transform.scale(
                scale: garment.scale,
                child: GarabuImage(
                  imageUrl: garment.imageUrl,
                  width: canvasSize.width,
                  height: canvasSize.height,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildCoupleStreakHearts(CoupleModel couple) {
    final hasU1 = couple.hasUser1InteractedToday();
    final hasU2 = couple.hasUser2InteractedToday();

    // Color de la racha (fuego naranja si activa, azul hielo si congelada)
    final streakColor = couple.isStreakFrozen
        ? const Color(0xFF0288D1)
        : const Color(0xFFFF7043);

    return InkWell(
      onTap: () => _showStreakDetailsDialog(context, couple),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Corazón Persona 1
            _buildPersonHeart(
              name: couple.user1Name,
              hasInteracted: hasU1,
              streakColor: streakColor,
            ),
            const SizedBox(width: 8),

            // Corazón Persona 2
            _buildPersonHeart(
              name: couple.user2Name ?? 'Pareja',
              hasInteracted: hasU2,
              streakColor: streakColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonHeart({
    required String name,
    required bool hasInteracted,
    required Color streakColor,
  }) {
    return Tooltip(
      message: '$name: ${hasInteracted ? "Interactuó hoy ❤️" : "Falta interactuar hoy ⏳"}',
      child: Icon(
        hasInteracted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 16,
        color: hasInteracted ? streakColor : const Color(0xFFBDBDBD),
      ),
    );
  }

  void _showStreakDetailsDialog(BuildContext context, CoupleModel couple) {
    final hasU1 = couple.hasUser1InteractedToday();
    final hasU2 = couple.hasUser2InteractedToday();
    final bothDone = couple.hasBothInteractedToday();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(
              couple.isStreakFrozen
                  ? Icons.ac_unit_rounded
                  : Icons.local_fire_department_rounded,
              color: couple.isStreakFrozen
                  ? const Color(0xFF0288D1)
                  : const Color(0xFFFF7043),
              size: 26,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                couple.isStreakFrozen
                    ? 'Racha Congelada (${couple.streak} días)'
                    : 'Racha de ${couple.streak} días',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: GarabuTheme.deepEspresso,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bothDone
                  ? '¡Excelente! Ambos han interactuado con Garabu hoy y la racha se mantendrá ardiendo con fuerza. 🔥'
                  : 'Para mantener la racha viva y evitar que se enfríe, ambos miembros de la pareja deben interactuar con la mascota cada día.',
              style: const TextStyle(
                fontSize: 13.5,
                color: GarabuTheme.deepEspresso,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),

            // Estado de Usuario 1
            _buildPartnerStreakStatusTile(
              name: couple.user1Name,
              hasInteracted: hasU1,
            ),
            const SizedBox(height: 8),

            // Estado de Usuario 2
            _buildPartnerStreakStatusTile(
              name: couple.user2Name ?? 'Pareja',
              hasInteracted: hasU2,
            ),

            if (couple.isStreakFrozen) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE1F5FE),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF81D4FA)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF0288D1), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'La racha se enfrió porque faltó la interacción de uno de los dos. ¡Puedes descongelarla gratis!',
                        style: TextStyle(fontSize: 12, color: Color(0xFF01579B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (couple.isStreakFrozen)
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.of(ctx).pop();
                await ref.read(lobbyRepositoryProvider).restoreFrozenStreak(couple.id);
                if (mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('¡Racha descongelada con éxito! A seguir cuidando de Garabu 🔥'),
                      backgroundColor: Color(0xFFFF7043),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF7043),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Descongelar Gratis ✨', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar', style: TextStyle(color: GarabuTheme.primaryBrown)),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerStreakStatusTile({
    required String name,
    required bool hasInteracted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasInteracted
            ? const Color(0xFFFFF3E0)
            : GarabuTheme.warmSand.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasInteracted
              ? const Color(0xFFFFB74D)
              : GarabuTheme.warmSand.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasInteracted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            size: 18,
            color: hasInteracted ? const Color(0xFFFF7043) : const Color(0xFF9E9E9E),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: GarabuTheme.deepEspresso,
              ),
            ),
          ),
          Text(
            hasInteracted ? 'Completado hoy 🔥' : 'Falta interactuar ⏳',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: hasInteracted ? const Color(0xFFE65100) : const Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = ref.watch(currentCoupleProvider(widget.couple.id));
    final currentCouple = coupleAsync.value ?? widget.couple;
    final activePetId = currentCouple.resolvedActivePetId;

    if (activePetId == null) {
      return const Scaffold(
        body: Center(child: Text('Buscando mascota...')),
      );
    }

    final petAsync = ref.watch(currentPetProvider(activePetId));
    final lettersAsync = ref.watch(lettersProvider(currentCouple.id));
    final unreadLettersCount = lettersAsync.value
            ?.where((l) => !l.isRead && l.senderId != ref.read(currentUserProvider)?.id)
            .length ??
        0;

    return Scaffold(
      backgroundColor: GarabuTheme.background,
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

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth >= 760;
                final availableHeight = constraints.maxHeight - 160.0;
                final availableWidth = isWideScreen
                    ? (constraints.maxWidth - 280.0)
                    : (constraints.maxWidth - 32.0);

                final petBoxDimension = min(availableHeight, availableWidth).clamp(240.0, 420.0);
                final canvasSize = Size(petBoxDimension, petBoxDimension);

                final petEmotion = _resolvePetEmotion(pet);

                // Widget de la mascota interactiva
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
                    return GestureDetector(
                      onTapDown: (details) {
                        if (_heldFruit != null) {
                          _feedPetDirectly(pet, _heldFruit!);
                        } else {
                          _onPetStroke(pet, details.localPosition);
                        }
                      },
                      onPanUpdate: (details) => _onPetStroke(pet, details.localPosition),
                      child: Container(
                        key: _petContainerKey,
                        width: canvasSize.width,
                        height: canvasSize.height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: _isFeedingMouthHovered
                                ? GarabuTheme.primaryBrown
                                : GarabuTheme.warmSand,
                            width: _isFeedingMouthHovered ? 2.8 : 1.5,
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
                            // 1. Fondo estático (NO se mueve con la respiración/ronroneo del muñeco)
                            if (pet.resolvedBackgroundUrl != null && pet.resolvedBackgroundUrl!.isNotEmpty)
                              GarabuImage(
                                imageUrl: pet.resolvedBackgroundUrl,
                                width: canvasSize.width,
                                height: canvasSize.height,
                                fit: BoxFit.cover,
                              )
                            else
                              const NotebookBackground(),

                            // 2. Capa animada exclusiva para el muñeco y su ropita anclada
                            AnimatedBuilder(
                              animation: Listenable.merge([
                                _bounceAnimation,
                                _squashController,
                                _purrController,
                              ]),
                              builder: (context, child) {
                                final bounce = pet.isSleeping ? 0.0 : _bounceAnimation.value;
                                final purrScale = _purrScaleAnimation.value;
                                final purrRot = _purrRotateAnimation.value;
                                final squashX = _scaleXAnimation.value;
                                final squashY = _scaleYAnimation.value;

                                return Transform.translate(
                                  offset: Offset(0, bounce),
                                  child: Transform.rotate(
                                    angle: purrRot,
                                    alignment: Alignment.bottomCenter,
                                    child: Transform.scale(
                                      scaleX: squashX * purrScale,
                                      scaleY: squashY * purrScale,
                                      alignment: Alignment.bottomCenter,
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  // Silueta / Cuerpo de la mascota
                                  GarabuImage(
                                    imageUrl: pet.bodyImageUrl,
                                    width: canvasSize.width,
                                    height: canvasSize.height,
                                    fit: BoxFit.contain,
                                  ),

                                  // Ojos sincronizados simultáneos
                                  AnimatedBuilder(
                                    animation: _blinkController,
                                    builder: (context, _) {
                                      final double progress = pet.isSleeping ? 1.0 : _blinkController.value;
                                      final lookDir = _calculateLookDirection(canvasSize);
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
                                            emotion: petEmotion,
                                            lookDirection: lookDir,
                                          ),
                                          StaticEyeOverlay(
                                            position: pet.eyesConfig.rightEye,
                                            canvasSize: canvasSize,
                                            color: Color(pet.eyesConfig.color),
                                            hasEyelashes: pet.eyesConfig.hasEyelashes,
                                            isLeft: false,
                                            blinkProgress: progress,
                                            isHappy: _isPetHappy,
                                            emotion: petEmotion,
                                            lookDirection: lookDir,
                                          ),
                                        ],
                                      );
                                    },
                                  ),

                                  // Boca interactiva anclada
                                  _buildPetMouth(pet, canvasSize, petEmotion),

                                  // Prendas activas del Clóset (hasta 5 prendas con sus offsets y transformaciones)
                                  ..._buildEquippedGarments(pet, canvasSize),
                                ],
                              ),
                            ),

                            // Modo Noche (Luz apagada): Cubre y oscurece todo el cuarto y la mascota armónicamente
                            if (pet.isSleeping)
                              Positioned.fill(
                                child: IgnorePointer(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xC70B1020),
                                      borderRadius: BorderRadius.circular(24),
                                    ),
                                  ),
                                ),
                              ),

                            // 4. Partículas de caricias aisladas en ValueListenableBuilder
                            ValueListenableBuilder<List<_SketchParticleData>>(
                              valueListenable: _particlesNotifier,
                              builder: (context, particles, _) {
                                return Stack(
                                  children: particles.map((p) => _SketchParticleWidget(
                                    key: p.key,
                                    particle: p,
                                    onDismissed: () {
                                      final current = List<_SketchParticleData>.from(_particlesNotifier.value)
                                        ..removeWhere((item) => item.key == p.key);
                                      _particlesNotifier.value = current;
                                    },
                                  )).toList(),
                                );
                              },
                            ),

                            // 5. Globo de diálogo o Zzz si duerme
                            if (_speechBubbleText != null || pet.isSleeping)
                              Positioned(
                                top: 12,
                                left: 16,
                                right: 16,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: pet.isSleeping
                                          ? const Color(0xFF1E2638)
                                          : Colors.white.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: pet.isSleeping
                                            ? const Color(0xFF5C6BC0)
                                            : GarabuTheme.primaryBrown,
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      pet.isSleeping ? 'Zzz...' : _speechBubbleText!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: pet.isSleeping
                                            ? const Color(0xFFC5CAE9)
                                            : GarabuTheme.deepEspresso,
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
                );

                return MouseRegion(
                  onHover: (event) {
                    if (_heldFruit != null) {
                      setState(() => _pointerPosition = event.position);
                      _checkMouthHover(event.position, pet);
                    }
                  },
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (event) {
                      if (_heldFruit != null) {
                        setState(() => _pointerPosition = event.position);
                        _checkMouthHover(event.position, pet);
                      }
                    },
                    onPointerMove: (event) {
                      if (_heldFruit != null) {
                        setState(() => _pointerPosition = event.position);
                        _checkMouthHover(event.position, pet);
                      }
                    },
                    onPointerUp: (event) {
                      if (_heldFruit != null) {
                        _checkFeedHit(event.position, pet);
                      }
                    },
                    child: Stack(
                      children: [
                        // Contenido Principal Nativo (Sin scroll de página web en móvil)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                          child: Column(
                            children: [
                              // 1. Barra Superior Nativa (Racha, Nombre de mascota, Lenguaje, Modo Noche, Editar Cuerpo, Salir)
                              Row(
                                children: [
                                  // Racha de Pareja: Llama superior + Corazones individuales abajo
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Chip de Llama y Racha
                                      GestureDetector(
                                        onTap: () => _showStreakDetailsDialog(context, currentCouple),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: currentCouple.isStreakFrozen
                                                ? const Color(0xFFE1F5FE)
                                                : Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(
                                              color: currentCouple.isStreakFrozen
                                                  ? const Color(0xFF0288D1)
                                                  : (currentCouple.hasBothInteractedToday()
                                                      ? const Color(0xFFFF7043)
                                                      : GarabuTheme.warmSand),
                                              width: currentCouple.isStreakFrozen || currentCouple.hasBothInteractedToday() ? 1.6 : 1.0,
                                            ),
                                            boxShadow: [
                                              if (currentCouple.hasBothInteractedToday() && !currentCouple.isStreakFrozen)
                                                BoxShadow(
                                                  color: const Color(0xFFFF7043).withValues(alpha: 0.18),
                                                  blurRadius: 6,
                                                  offset: const Offset(0, 2),
                                                ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                currentCouple.isStreakFrozen
                                                    ? Icons.ac_unit_rounded
                                                    : Icons.local_fire_department_rounded,
                                                color: currentCouple.isStreakFrozen
                                                    ? const Color(0xFF0288D1)
                                                    : const Color(0xFFFF7043),
                                                size: 17,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${currentCouple.streak}',
                                                style: TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: currentCouple.isStreakFrozen
                                                      ? const Color(0xFF0277BD)
                                                      : GarabuTheme.deepEspresso,
                                                ),
                                              ),
                                              if (currentCouple.isStreakFrozen) ...[
                                                const SizedBox(width: 3),
                                                const Icon(
                                                  Icons.touch_app_rounded,
                                                  color: Color(0xFF0288D1),
                                                  size: 13,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 3),

                                      // Dos corazones: Uno para cada persona + puntito verde de presencia en línea
                                      _buildCoupleStreakHearts(currentCouple),
                                    ],
                                  ),
                                  const SizedBox(width: 8),

                                  // Nombre de la Mascota compartido y centrado
                                  Expanded(
                                    child: Center(
                                      child: Text(
                                        pet.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: GarabuTheme.deepEspresso,
                                          letterSpacing: -0.3,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),

                                  // Botón de Enseñar Lenguaje
                                  IconButton(
                                    tooltip: 'Enseñar frases a ${pet.name}',
                                    icon: const Icon(
                                      Icons.record_voice_over_rounded,
                                      color: GarabuTheme.primaryBrown,
                                      size: 22,
                                    ),
                                    onPressed: () => LanguageBottomSheet.show(context, pet),
                                  ),

                                  // Botón de Apagar / Encender la luz
                                  IconButton(
                                    tooltip: pet.isSleeping ? 'Encender la luz' : 'Apagar la luz (Dormir)',
                                    icon: Icon(
                                      pet.isSleeping ? Icons.lightbulb : Icons.lightbulb_outline_rounded,
                                      color: pet.isSleeping ? const Color(0xFFFFD54F) : GarabuTheme.primaryBrown,
                                      size: 22,
                                    ),
                                    onPressed: () => _toggleLight(pet),
                                  ),

                                  // Botón para editar la forma del cuerpo y carita
                                  IconButton(
                                    tooltip: 'Editar cuerpo de ${pet.name}',
                                    icon: const Icon(
                                      Icons.edit_note_rounded,
                                      color: GarabuTheme.primaryBrown,
                                      size: 24,
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => BodyCanvasScreen(
                                            couple: currentCouple,
                                            petName: pet.name,
                                            existingPet: pet,
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                  // Botón de Ajustes (Audio, Custodia, Cuenta)
                                  IconButton(
                                    tooltip: 'Ajustes',
                                    icon: const Icon(Icons.settings_rounded, color: GarabuTheme.primaryBrown, size: 22),
                                    onPressed: () => SettingsBottomSheet.show(
                                      context: context,
                                      couple: currentCouple,
                                      pet: pet,
                                    ),
                                  ),
                                ],
                              ),

                              // Barras de estadísticas compactas en móvil o toggle
                              const SizedBox(height: 6),
                              if (!isWideScreen)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    PetVitalBars(pet: pet, isCompact: true),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () => setState(() => _showStatsDrawer = !_showStatsDrawer),
                                      borderRadius: BorderRadius.circular(12),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.8),
                                          shape: BoxShape.circle,
                                          border: Border.all(color: GarabuTheme.warmSand),
                                        ),
                                        child: Icon(
                                          _showStatsDrawer ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                          size: 16,
                                          color: GarabuTheme.primaryBrown,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                              // 2. Área Central del Héroe
                              Expanded(
                                child: Center(
                                  child: isWideScreen
                                      ? Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            petContainerWidget,
                                            const SizedBox(width: 28),
                                            Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                PetVitalBars(pet: pet),
                                              ],
                                            ),
                                          ],
                                        )
                                      : petContainerWidget,
                                ),
                              ),

                              // 3. Dock Flotante de Acciones Inferior
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: GarabuTheme.warmSand.withValues(alpha: 0.8)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    // 1. Alimentar / Mochila
                                    _buildDockButton(
                                      icon: Icons.restaurant_rounded,
                                      label: 'Comida',
                                      badgeText: '${pet.foodInventory.values.fold(0, (a, b) => a + b)}',
                                      onTap: () => FeedBottomSheet.show(
                                        context: context,
                                        pet: pet,
                                        onFruitFed: (fruit) => _onFruitFed(pet, fruit),
                                        onWaterGiven: () => _onWaterGiven(pet),
                                      ),
                                    ),

                                    // 2. Tienda de Alimentos
                                    _buildDockButton(
                                      icon: Icons.storefront_rounded,
                                      label: 'Tienda',
                                      onTap: () => ShopBottomSheet.show(context: context, pet: pet),
                                    ),

                                    // 3. Clóset
                                    _buildDockButton(
                                      icon: Icons.checkroom_rounded,
                                      label: 'Clóset',
                                      badgeText: '${pet.closet.length}/5',
                                      onTap: () => ClosetBottomSheet.show(context, currentCouple, pet),
                                    ),

                                    // 4. Buzón de cartas
                                    _buildDockButton(
                                      icon: Icons.mail_outline_rounded,
                                      label: 'Buzón',
                                      badgeText: unreadLettersCount > 0 ? '$unreadLettersCount' : null,
                                      badgeColor: const Color(0xFFE53935),
                                      onTap: () => MailboxBottomSheet.show(context, currentCouple),
                                    ),

                                    // 5. Fondos
                                    _buildDockButton(
                                      icon: Icons.wallpaper_rounded,
                                      label: 'Fondo',
                                      onTap: () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => BackgroundCanvasScreen(pet: pet),
                                        ),
                                      ),
                                    ),

                                    // 6. Minijuegos en pareja
                                    _buildDockButton(
                                      icon: Icons.sports_esports_rounded,
                                      label: 'Juegos',
                                      onTap: () => GameCenterBottomSheet.show(context, pet, currentCouple),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Desplegable de estadísticas detalladas en móvil si está abierto
                        if (!isWideScreen && _showStatsDrawer)
                          Positioned(
                            top: 80,
                            left: 20,
                            right: 20,
                            child: Center(
                              child: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(20),
                                child: PetVitalBars(pet: pet),
                              ),
                            ),
                          ),

                        // Barra flotante de guía al sostener comida
                        if (_heldFruit != null)
                          Positioned(
                            top: 12,
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
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: _heldFruit!.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
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

                        // Fruta dibujada a mano que se queda pegada al cursor o dedo
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
                                        color: _heldFruit!.color.withValues(alpha: 0.35),
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
                                      : Container(
                                          decoration: BoxDecoration(
                                            color: _heldFruit!.color,
                                            shape: BoxShape.circle,
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
            );
          },
        ),
      ),
    );
  }

  Widget _buildDockButton({
    required IconData icon,
    required String label,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: GarabuTheme.primaryBrown, size: 22),
                if (badgeText != null && badgeText != '0')
                  Positioned(
                    right: -10,
                    top: -6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: badgeColor ?? GarabuTheme.primaryBrown,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeText,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
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

enum _ParticleType { heart, star }

class _SketchParticleData {
  final Key key;
  final Offset startOffset;
  final _ParticleType type;
  final double driftX;
  final Color color;

  _SketchParticleData({
    required this.key,
    required this.startOffset,
    required this.type,
    required this.driftX,
    required this.color,
  });
}

class _SketchParticleWidget extends StatefulWidget {
  final _SketchParticleData particle;
  final VoidCallback onDismissed;

  const _SketchParticleWidget({
    super.key,
    required this.particle,
    required this.onDismissed,
  });

  @override
  State<_SketchParticleWidget> createState() => _SketchParticleWidgetState();
}

class _SketchParticleWidgetState extends State<_SketchParticleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _translateYAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1050),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.55, 1.0, curve: Curves.easeOut)),
    );

    _translateYAnimation = Tween<double>(begin: 0.0, end: -65.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.1).chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 0.9).chain(CurveTween(curve: Curves.easeInOut)), weight: 60),
    ]).animate(_controller);

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
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: SizedBox(
                width: 22,
                height: 22,
                child: CustomPaint(
                  painter: widget.particle.type == _ParticleType.heart
                      ? _SketchHeartPainter(color: widget.particle.color)
                      : _SketchStarPainter(color: widget.particle.color),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SketchHeartPainter extends CustomPainter {
  final Color color;
  const _SketchHeartPainter({this.color = const Color(0xFFE57373)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(w * 0.5, h * 0.85);
    path.cubicTo(w * 0.1, h * 0.55, 0, h * 0.3, w * 0.25, h * 0.12);
    path.cubicTo(w * 0.42, 0, w * 0.5, h * 0.25, w * 0.5, h * 0.25);
    path.cubicTo(w * 0.5, h * 0.25, w * 0.58, 0, w * 0.75, h * 0.12);
    path.cubicTo(w, h * 0.3, w * 0.9, h * 0.55, w * 0.5, h * 0.85);

    canvas.drawPath(path, paint);

    final sketchPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final sketchPath = Path();
    sketchPath.moveTo(w * 0.48, h * 0.8);
    sketchPath.cubicTo(w * 0.14, h * 0.5, w * 0.06, h * 0.26, w * 0.26, h * 0.16);
    canvas.drawPath(sketchPath, sketchPaint);
  }

  @override
  bool shouldRepaint(covariant _SketchHeartPainter oldDelegate) => false;
}

class _SketchStarPainter extends CustomPainter {
  final Color color;
  const _SketchStarPainter({this.color = const Color(0xFFFBC02D)});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    final path = Path();
    path.moveTo(cx, cy - r);
    path.quadraticBezierTo(cx, cy, cx + r, cy);
    path.quadraticBezierTo(cx, cy, cx, cy + r);
    path.quadraticBezierTo(cx, cy, cx - r, cy);
    path.quadraticBezierTo(cx, cy, cx, cy - r);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), 1.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _SketchStarPainter oldDelegate) => false;
}
