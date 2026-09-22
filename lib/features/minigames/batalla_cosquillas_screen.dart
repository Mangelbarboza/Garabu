import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/data/auth_repository.dart';
import '../../core/theme/garabu_theme.dart';
import '../../core/widgets/garabu_image.dart';
import '../../core/widgets/notebook_background.dart';
import '../lobby/data/lobby_repository.dart';
import '../lobby/domain/couple_model.dart';
import '../canvas/presentation/widgets/eye_widget.dart';
import '../pet/data/pet_repository.dart';
import '../pet/domain/pet_model.dart';

class BatallaCosquillasScreen extends ConsumerStatefulWidget {
  final PetModel pet;
  final CoupleModel? couple;

  const BatallaCosquillasScreen({
    super.key,
    required this.pet,
    this.couple,
  });

  @override
  ConsumerState<BatallaCosquillasScreen> createState() => _BatallaCosquillasScreenState();
}

class _TickleFlea {
  final String id;
  Offset normalizedPos; // 0.1 a 0.9 dentro de la mascota
  final bool isGolden;

  _TickleFlea({
    required this.id,
    required this.normalizedPos,
    this.isGolden = false,
  });
}

class _FloatingBurst {
  final Key key = UniqueKey();
  final Offset position;
  final String text;
  final Color color;

  _FloatingBurst({
    required this.position,
    required this.text,
    required this.color,
  });
}

class _BatallaCosquillasScreenState extends ConsumerState<BatallaCosquillasScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();

  // Estados del juego
  int _score = 0;
  int _fleasCaught = 0;
  int _timeLeft = 30;
  bool _isPlaying = false;
  double _laughMeter = 0.0; // 0.0 a 1.0
  bool _isFeverMode = false;
  Timer? _feverTimer;

  // Lista de pulguitas activas y efectos de estallido
  final List<_TickleFlea> _fleas = [];
  final List<_FloatingBurst> _bursts = [];

  // Temporizadores
  Timer? _countdownTimer;
  Timer? _fleaSpawnTimer;
  Timer? _fleaJumpTimer;

  // Animación de cosquilleo de la mascota (meneíto alegre)
  late AnimationController _wiggleController;
  late Animation<double> _wiggleAngle;

  // Animación de pulguitas rebotando
  late AnimationController _fleaBounceController;

  // Llave para obtener dimensiones reales del contenedor de la mascota
  final GlobalKey _petContainerKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    _wiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );

    _wiggleAngle = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(parent: _wiggleController, curve: Curves.easeInOut),
    );

    _fleaBounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);

    _startGame();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _fleaSpawnTimer?.cancel();
    _fleaJumpTimer?.cancel();
    _feverTimer?.cancel();
    _wiggleController.dispose();
    _fleaBounceController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _score = 0;
      _fleasCaught = 0;
      _timeLeft = 30;
      _isPlaying = true;
      _laughMeter = 0.0;
      _isFeverMode = false;
      _fleas.clear();
      _bursts.clear();
    });

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_timeLeft <= 1) {
        timer.cancel();
        _endGame();
      } else {
        setState(() {
          _timeLeft--;
          if (_isFeverMode && _laughMeter > 0.0) {
            _laughMeter = max(0.0, _laughMeter - 0.18);
            if (_laughMeter <= 0.0) {
              _isFeverMode = false;
            }
          }
        });
      }
    });

    _fleaSpawnTimer?.cancel();
    _fleaSpawnTimer = Timer.periodic(const Duration(milliseconds: 750), (_) {
      if (!_isPlaying || !mounted) return;
      _spawnFlea();
    });

    _fleaJumpTimer?.cancel();
    _fleaJumpTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!_isPlaying || !mounted) return;
      _jumpFleas();
    });

    // Spawn inicial de 3 pulguitas
    for (int i = 0; i < 3; i++) {
      _spawnFlea();
    }
  }

  void _spawnFlea() {
    if (_fleas.length >= 7) return;

    final isGolden = _random.nextDouble() < 0.20; // 20% doradas
    final newFlea = _TickleFlea(
      id: 'flea_${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(999)}',
      normalizedPos: Offset(
        0.18 + _random.nextDouble() * 0.64,
        0.20 + _random.nextDouble() * 0.60,
      ),
      isGolden: isGolden,
    );

    setState(() => _fleas.add(newFlea));
  }

  void _jumpFleas() {
    setState(() {
      for (final flea in _fleas) {
        flea.normalizedPos = Offset(
          (flea.normalizedPos.dx + (_random.nextDouble() - 0.5) * 0.35).clamp(0.15, 0.85),
          (flea.normalizedPos.dy + (_random.nextDouble() - 0.5) * 0.35).clamp(0.18, 0.82),
        );
      }
    });
  }

  void _handleScratchAt(Offset globalPos) {
    if (!_isPlaying) return;

    final renderBox = _petContainerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = renderBox.globalToLocal(globalPos);
    final size = renderBox.size;
    final normalizedTouch = Offset(
      localPos.dx / size.width,
      localPos.dy / size.height,
    );

    // Mueve la animación de meneíto alegre de la mascota
    if (!_wiggleController.isAnimating) {
      _wiggleController.repeat(reverse: true);
      Future.delayed(const Duration(milliseconds: 320), () {
        if (mounted && _wiggleController.isAnimating) {
          _wiggleController.stop();
          _wiggleController.reset();
        }
      });
    }

    // Comprobar colisión precisa por toque/click individual
    final hitIndices = <int>[];
    for (int i = 0; i < _fleas.length; i++) {
      final flea = _fleas[i];
      final dist = (flea.normalizedPos - normalizedTouch).distance;
      if (dist < 0.12) {
        hitIndices.add(i);
      }
    }

    if (hitIndices.isNotEmpty) {
      // Orden inverso para remover
      hitIndices.sort((a, b) => b.compareTo(a));

      for (final idx in hitIndices) {
        final hitFlea = _fleas.removeAt(idx);
        _fleasCaught++;

        final points = hitFlea.isGolden
            ? (_isFeverMode ? 60 : 30)
            : (_isFeverMode ? 20 : 10);

        _score += points;

        // Aumentar medidor de risa
        if (!_isFeverMode) {
          _laughMeter = (_laughMeter + (hitFlea.isGolden ? 0.28 : 0.16)).clamp(0.0, 1.0);
          if (_laughMeter >= 1.0) {
            _activateFeverMode();
          }
        }

        // Crear efecto de estallido / risas
        final burstPos = Offset(
          hitFlea.normalizedPos.dx * size.width,
          hitFlea.normalizedPos.dy * size.height,
        );

        final burst = _FloatingBurst(
          position: burstPos,
          text: hitFlea.isGolden ? '¡JAJAJA +$points! ✨' : '¡Ji-ji +$points! 😂',
          color: hitFlea.isGolden ? const Color(0xFFFFB300) : const Color(0xFFE91E63),
        );

        _bursts.add(burst);
        Future.delayed(const Duration(milliseconds: 650), () {
          if (mounted) {
            setState(() => _bursts.remove(burst));
          }
        });
      }

      setState(() {});
    }
  }

  void _activateFeverMode() {
    _isFeverMode = true;
    _feverTimer?.cancel();

    // Notificación en ráfaga
    final renderBox = _petContainerKey.currentContext?.findRenderObject() as RenderBox?;
    final centerPos = renderBox != null
        ? Offset(renderBox.size.width / 2, renderBox.size.height / 3)
        : const Offset(140, 100);

    final burst = _FloatingBurst(
      position: centerPos,
      text: '¡FIEBRE DE CARCAJADAS! x2 💥🎉',
      color: const Color(0xFFFF5722),
    );
    _bursts.add(burst);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _bursts.remove(burst));
    });

    // Añadir más pulguitas para aprovechar la fiebre
    for (int i = 0; i < 4; i++) {
      _spawnFlea();
    }
  }

  Future<void> _endGame() async {
    setState(() => _isPlaying = false);
    _countdownTimer?.cancel();
    _fleaSpawnTimer?.cancel();
    _fleaJumpTimer?.cancel();
    _feverTimer?.cancel();

    // Recompensa en monedas Garabu🪙 (mínimo 12, proporcional a la puntuación)
    final earnedCoins = max(12, (_score / 2.2).round());
    final petRepo = ref.read(petRepositoryProvider);
    await petRepo.addCoins(petId: widget.pet.id, amount: earnedCoins);
    await petRepo.petAnimal(petId: widget.pet.id); // Aumenta felicidad
    await petRepo.addExperience(petId: widget.pet.id, expDelta: 45); // +45 EXP

    // Guardar récord del usuario en la pareja
    if (widget.couple != null) {
      final authUser = ref.read(currentUserProvider);
      final userId = authUser?.id ?? widget.couple!.user1Id;
      await ref.read(lobbyRepositoryProvider).recordGameScore(
            coupleId: widget.couple!.id,
            gameKey: 'batalla_cosquillas',
            userId: userId,
            score: _score,
          );
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: GarabuTheme.paperWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.sentiment_very_satisfied_rounded, color: Color(0xFFE91E63), size: 28),
            SizedBox(width: 8),
            Text(
              '¡Ataque de Risa!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: GarabuTheme.deepEspresso,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$_score',
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.bold,
                color: GarabuTheme.primaryBrown,
              ),
            ),
            const Text(
              'Puntos de cosquillas',
              style: TextStyle(fontSize: 13, color: GarabuTheme.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              '$_fleasCaught garabu-pulguitas rascadas',
              style: const TextStyle(fontSize: 12.5, color: GarabuTheme.primaryBrown, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD54F)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFA000), size: 22),
                  const SizedBox(width: 8),
                  Text(
                    '+$earnedCoins Monedas | +45 EXP',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡${widget.pet.name} no para de reír de felicidad!',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Volver a Casa', style: TextStyle(color: GarabuTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _startGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GarabuTheme.primaryBrown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Jugar de Nuevo', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildEquippedGarments(Size canvasSize) {
    final equippedIds = widget.pet.resolvedEquippedGarmentIds;
    if (equippedIds.isEmpty) {
      if (widget.pet.clothesImageUrl != null && widget.pet.clothesImageUrl!.isNotEmpty) {
        return [
          GarabuImage(
            imageUrl: widget.pet.clothesImageUrl,
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
      final garment = widget.pet.closet.cast<GarmentItem?>().firstWhere(
        (g) => g?.id == id,
        orElse: () => null,
      );
      if (garment != null && garment.imageUrl.isNotEmpty) {
        widgets.add(
          Transform.translate(
            offset: Offset(garment.offsetX, garment.offsetY),
            child: GarabuImage(
              imageUrl: garment.imageUrl,
              width: canvasSize.width,
              height: canvasSize.height,
              fit: BoxFit.contain,
            ),
          ),
        );
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final petDim = min(size.width * 0.78, 300.0);
    final canvasSize = Size(petDim, petDim);

    return Scaffold(
      backgroundColor: GarabuTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Fondo de libreta
            const NotebookBackground(),

            // 2. Contenido principal
            Column(
              children: [
                // Barra superior: Salir, Tiempo, Puntuación
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Botón Salir
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded, color: GarabuTheme.deepEspresso),
                        tooltip: 'Salir',
                      ),

                      // Temporizador
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: _timeLeft <= 5 ? const Color(0xFFFFEBEE) : GarabuTheme.paperWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _timeLeft <= 5 ? Colors.redAccent : GarabuTheme.warmSand,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.timer_rounded,
                              size: 18,
                              color: _timeLeft <= 5 ? Colors.redAccent : GarabuTheme.primaryBrown,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_timeLeft}s',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _timeLeft <= 5 ? Colors.redAccent : GarabuTheme.deepEspresso,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Puntuación
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: GarabuTheme.paperWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: GarabuTheme.warmSand, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Color(0xFFFFA000), size: 18),
                            const SizedBox(width: 6),
                            Text(
                              '$_score',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: GarabuTheme.deepEspresso,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Récords competitivos de la pareja
                if (widget.couple != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: GarabuTheme.warmSand.withValues(alpha: 0.8)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events_rounded, size: 14, color: Color(0xFFFFA000)),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.couple!.user1Name}: ${widget.couple!.gameRecords['batalla_cosquillas_${widget.couple!.user1Id}'] ?? 0} pts',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso),
                            ),
                            if (widget.couple!.user2Name != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                '|  ${widget.couple!.user2Name}: ${widget.couple!.gameRecords['batalla_cosquillas_${widget.couple!.user2Id}'] ?? 0} pts',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE91E63)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                // Medidor de Carcajadas (Fiebre)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isFeverMode ? Icons.local_fire_department_rounded : Icons.mood_rounded,
                                size: 16,
                                color: _isFeverMode ? const Color(0xFFFF5722) : const Color(0xFFE91E63),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isFeverMode ? '¡FIEBRE DE CARCAJADAS! (x2)' : 'Medidor de Risa',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _isFeverMode ? const Color(0xFFFF5722) : GarabuTheme.deepEspresso,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(_laughMeter * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: _isFeverMode ? const Color(0xFFFF5722) : GarabuTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _laughMeter,
                          minHeight: 10,
                          backgroundColor: GarabuTheme.warmSand.withValues(alpha: 0.35),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isFeverMode ? const Color(0xFFFF5722) : const Color(0xFFE91E63),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),
                const Text(
                  '¡Haz click o toca directamente sobre cada pulguita para atraparla!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: GarabuTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Mascota interactiva con pulguitas sobre ella
                Expanded(
                  child: Center(
                    child: Listener(
                      behavior: HitTestBehavior.opaque,
                      onPointerDown: (e) => _handleScratchAt(e.position),
                      child: AnimatedBuilder(
                        animation: _wiggleController,
                        builder: (context, child) {
                          final angle = _wiggleController.isAnimating ? _wiggleAngle.value : 0.0;
                          return Transform.rotate(
                            angle: angle,
                            alignment: Alignment.center,
                            child: child,
                          );
                        },
                        child: Container(
                          key: _petContainerKey,
                          width: canvasSize.width,
                          height: canvasSize.height,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: _isFeverMode ? const Color(0xFFFF5722) : GarabuTheme.warmSand,
                              width: _isFeverMode ? 2.5 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _isFeverMode
                                    ? const Color(0xFFFF5722).withValues(alpha: 0.25)
                                    : Colors.black.withValues(alpha: 0.05),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Silueta de la mascota
                              GarabuImage(
                                imageUrl: widget.pet.bodyImageUrl,
                                width: canvasSize.width,
                                height: canvasSize.height,
                                fit: BoxFit.contain,
                              ),

                              // Ojitos riendo / felices
                              StaticEyeOverlay(
                                position: widget.pet.eyesConfig.leftEye,
                                canvasSize: canvasSize,
                                color: Color(widget.pet.eyesConfig.color),
                                hasEyelashes: widget.pet.eyesConfig.hasEyelashes,
                                isLeft: true,
                                eyeSize: 24,
                                emotion: PetEmotion.happy,
                              ),
                              StaticEyeOverlay(
                                position: widget.pet.eyesConfig.rightEye,
                                canvasSize: canvasSize,
                                color: Color(widget.pet.eyesConfig.color),
                                hasEyelashes: widget.pet.eyesConfig.hasEyelashes,
                                isLeft: false,
                                eyeSize: 24,
                                emotion: PetEmotion.happy,
                              ),

                              // Ropa equipada
                              ..._buildEquippedGarments(canvasSize),

                              // Boca sonriendo/riendo
                              Positioned(
                                left: (widget.pet.eyesConfig.resolvedMouth.x * canvasSize.width) - 12,
                                top: (widget.pet.eyesConfig.resolvedMouth.y * canvasSize.height) - 8,
                                child: const MouthWidget(
                                  size: 24,
                                  isOpen: true,
                                  emotion: PetEmotion.happy,
                                ),
                              ),

                              // Pulguitas de garabato
                              AnimatedBuilder(
                                animation: _fleaBounceController,
                                builder: (context, _) {
                                  final bounce = _fleaBounceController.value * 5.0;
                                  return Stack(
                                    children: _fleas.map((flea) {
                                      final fleaX = flea.normalizedPos.dx * canvasSize.width;
                                      final fleaY = flea.normalizedPos.dy * canvasSize.height;

                                      return Positioned(
                                        left: fleaX - 22,
                                        top: (fleaY - 22) - bounce,
                                        child: _FleaWidget(isGolden: flea.isGolden),
                                      );
                                    }).toList(),
                                  );
                                },
                              ),

                              // Efectos de estallido / carcajadas flotantes
                              ..._bursts.map((b) => Positioned(
                                    key: b.key,
                                    left: b.position.dx - 40,
                                    top: b.position.dy - 30,
                                    child: _BurstBubbleWidget(burst: b),
                                  )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget visual para las pulguitas estilo boceto
class _FleaWidget extends StatelessWidget {
  final bool isGolden;

  const _FleaWidget({required this.isGolden});

  @override
  Widget build(BuildContext context) {
    final baseColor = isGolden ? const Color(0xFFFFB300) : GarabuTheme.deepEspresso;
    final bgColor = isGolden ? const Color(0xFFFFF8E1) : const Color(0xFFECEFF1);

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: baseColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: isGolden ? 0.45 : 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          isGolden ? Icons.bug_report_rounded : Icons.pest_control_rounded,
          color: baseColor,
          size: 26,
        ),
      ),
    );
  }
}

/// Widget para las burbujas flotantes de risa
class _BurstBubbleWidget extends StatefulWidget {
  final _FloatingBurst burst;

  const _BurstBubbleWidget({required this.burst});

  @override
  State<_BurstBubbleWidget> createState() => _BurstBubbleWidgetState();
}

class _BurstBubbleWidgetState extends State<_BurstBubbleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        final dy = -24 * _anim.value;
        final opacity = (1.0 - _anim.value).clamp(0.0, 1.0);
        final scale = 0.8 + 0.4 * _anim.value;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.burst.color, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: widget.burst.color.withValues(alpha: 0.25),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Text(
                  widget.burst.text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: widget.burst.color,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
