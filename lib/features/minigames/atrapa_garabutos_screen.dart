import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/garabu_theme.dart';
import '../../core/widgets/garabu_image.dart';
import '../../core/widgets/notebook_background.dart';
import '../pet/data/pet_repository.dart';
import '../pet/domain/pet_model.dart';

enum GarabutoType {
  apple,
  orange,
  banana,
  grape,
  star,
  heart,
}

class FallingGarabuto {
  final UniqueKey id = UniqueKey();
  final GarabutoType type;
  double x; // Posición horizontal (0.0 a 1.0)
  double y; // Posición vertical (0.0 a 1.0)
  final double speed;
  final double rotation;

  FallingGarabuto({
    required this.type,
    required this.x,
    required this.y,
    required this.speed,
    required this.rotation,
  });

  int get points {
    switch (type) {
      case GarabutoType.apple:
      case GarabutoType.orange:
      case GarabutoType.banana:
      case GarabutoType.grape:
        return 10;
      case GarabutoType.heart:
        return 15;
      case GarabutoType.star:
        return 25;
    }
  }

  Color get color {
    switch (type) {
      case GarabutoType.apple:
        return const Color(0xFFE53935);
      case GarabutoType.orange:
        return const Color(0xFFFB8C00);
      case GarabutoType.banana:
        return const Color(0xFFFBC02D);
      case GarabutoType.grape:
        return const Color(0xFF8E24AA);
      case GarabutoType.heart:
        return const Color(0xFFE91E63);
      case GarabutoType.star:
        return const Color(0xFFFFB300);
    }
  }

  IconData get icon {
    switch (type) {
      case GarabutoType.apple:
      case GarabutoType.orange:
      case GarabutoType.banana:
      case GarabutoType.grape:
        return Icons.eco_rounded;
      case GarabutoType.heart:
        return Icons.favorite_rounded;
      case GarabutoType.star:
        return Icons.star_rounded;
    }
  }
}

class ScorePopup {
  final UniqueKey id = UniqueKey();
  final Offset position;
  final String text;
  final Color color;
  double opacity = 1.0;
  double offsetY = 0.0;

  ScorePopup({
    required this.position,
    required this.text,
    required this.color,
  });
}

class AtrapaGarabutosScreen extends ConsumerStatefulWidget {
  final PetModel pet;

  const AtrapaGarabutosScreen({
    super.key,
    required this.pet,
  });

  @override
  ConsumerState<AtrapaGarabutosScreen> createState() => _AtrapaGarabutosScreenState();
}

class _AtrapaGarabutosScreenState extends ConsumerState<AtrapaGarabutosScreen>
    with SingleTickerProviderStateMixin {
  final Random _random = Random();
  Timer? _gameTimer;
  Timer? _spawnTimer;

  int _score = 0;
  int _timeLeft = 35; // Segundos por partida
  bool _isPlaying = true;
  double _basketNormalizedX = 0.5; // Posición horizontal del cesto (0.0 a 1.0)
  final List<FallingGarabuto> _items = [];
  final List<ScorePopup> _popups = [];

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _score = 0;
    _timeLeft = 35;
    _isPlaying = true;
    _items.clear();
    _popups.clear();

    // Loop de actualización física del juego (60 FPS)
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 20), (timer) {
      if (!_isPlaying) return;
      _updatePhysics();
    });

    // Spawner de garabutos
    _spawnTimer?.cancel();
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 550), (timer) {
      if (!_isPlaying) return;
      _spawnGarabuto();
    });

    // Countdown timer de 1 segundo
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_timeLeft > 0 && _isPlaying) {
        setState(() => _timeLeft--);
      } else if (_timeLeft <= 0 && _isPlaying) {
        timer.cancel();
        _endGame();
      }
    });
  }

  void _spawnGarabuto() {
    const types = GarabutoType.values;
    final chosenType = types[_random.nextInt(types.length)];
    final speed = 0.008 + (_random.nextDouble() * 0.007);
    final rotation = (_random.nextDouble() - 0.5) * 0.3;

    setState(() {
      _items.add(FallingGarabuto(
        type: chosenType,
        x: 0.1 + (_random.nextDouble() * 0.8),
        y: -0.05,
        speed: speed,
        rotation: rotation,
      ));
    });
  }

  void _updatePhysics() {
    if (!mounted) return;

    final caughtIndices = <int>[];
    final expiredIndices = <int>[];

    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      item.y += item.speed;

      // Colisión con la canasta (cerca del fondo, y: 0.85 a 0.92)
      if (item.y >= 0.82 && item.y <= 0.93) {
        final distanceX = (item.x - _basketNormalizedX).abs();
        if (distanceX < 0.13) {
          caughtIndices.add(i);
          _score += item.points;

          _popups.add(ScorePopup(
            position: Offset(item.x, 0.82),
            text: '+${item.points}',
            color: item.color,
          ));
        }
      } else if (item.y > 1.05) {
        expiredIndices.add(i);
      }
    }

    // Actualizar popups flotantes
    for (final p in _popups) {
      p.offsetY -= 0.004;
      p.opacity = (p.opacity - 0.035).clamp(0.0, 1.0);
    }
    _popups.removeWhere((p) => p.opacity <= 0.05);

    // Eliminar atrapados y caídos
    final toRemove = {...caughtIndices, ...expiredIndices}.toList()
      ..sort((a, b) => b.compareTo(a));
    for (final idx in toRemove) {
      if (idx < _items.length) {
        _items.removeAt(idx);
      }
    }

    setState(() {});
  }

  Future<void> _endGame() async {
    setState(() => _isPlaying = false);
    _gameTimer?.cancel();
    _spawnTimer?.cancel();

    // Recompensa en monedas Garabu🪙 (mínimo 10, proporcional a la puntuación)
    final earnedCoins = max(10, (_score / 2.5).round());
    final petRepo = ref.read(petRepositoryProvider);
    await petRepo.addCoins(petId: widget.pet.id, amount: earnedCoins);
    await petRepo.petAnimal(petId: widget.pet.id); // Aumenta felicidad

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: GarabuTheme.paperWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Color(0xFFFFA000), size: 28),
            SizedBox(width: 8),
            Text(
              '¡Tiempo Terminado!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
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
              'Puntos alcanzados',
              style: TextStyle(fontSize: 13, color: GarabuTheme.textSecondary),
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
                    '+$earnedCoins Monedas Garabu',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE65100),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¡La felicidad de ${widget.pet.name} aumentó!',
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

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: GarabuTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Fondo de cuaderno
            const NotebookBackground(),

            // Controles de movimiento táctil / mouse
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanUpdate: (details) {
                final normalized = (details.localPosition.dx / size.width).clamp(0.08, 0.92);
                setState(() => _basketNormalizedX = normalized);
              },
              child: MouseRegion(
                onHover: (event) {
                  final normalized = (event.localPosition.dx / size.width).clamp(0.08, 0.92);
                  setState(() => _basketNormalizedX = normalized);
                },
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: Stack(
                    children: [
                      // Ítems cayendo
                      for (final item in _items)
                        Positioned(
                          left: item.x * size.width - 18,
                          top: item.y * size.height - 18,
                          child: Transform.rotate(
                            angle: item.rotation,
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: item.color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(color: item.color, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: item.color.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(item.icon, color: item.color, size: 20),
                              ),
                            ),
                          ),
                        ),

                      // Popups flotantes de puntuación
                      for (final popup in _popups)
                        Positioned(
                          left: popup.position.dx * size.width - 20,
                          top: (popup.position.dy + popup.offsetY) * size.height,
                          child: Opacity(
                            opacity: popup.opacity,
                            child: Text(
                              popup.text,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: popup.color,
                                shadows: [
                                  Shadow(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Canasta / Mascota recolectora
                      Positioned(
                        left: (_basketNormalizedX * size.width) - 44,
                        top: (size.height * 0.83) - 20,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Silueta pequeña de la mascota
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: GarabuImage(
                                imageUrl: widget.pet.bodyImageUrl,
                                width: 44,
                                height: 44,
                                fit: BoxFit.contain,
                              ),
                            ),
                            // Canasta recolectora estilo dibujo
                            Container(
                              width: 88,
                              height: 32,
                              decoration: BoxDecoration(
                                color: const Color(0xFFD7CCC8),
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
                                border: Border.all(color: GarabuTheme.primaryBrown, width: 2.2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.shopping_basket_rounded, size: 16, color: GarabuTheme.primaryBrown),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.pet.name,
                                    style: const TextStyle(
                                      fontSize: 11,
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
                    ],
                  ),
                ),
              ),
            ),

            // Barra Superior de HUD (Puntuación, Tiempo y Salir)
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón Salir
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GarabuTheme.deepEspresso),
                    onPressed: () => Navigator.of(context).pop(),
                  ),

                  // Tiempo restante
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: _timeLeft <= 10 ? Colors.red : GarabuTheme.warmSand,
                        width: _timeLeft <= 10 ? 2 : 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_rounded,
                          size: 16,
                          color: _timeLeft <= 10 ? Colors.red : GarabuTheme.primaryBrown,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_timeLeft}s',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _timeLeft <= 10 ? Colors.red : GarabuTheme.deepEspresso,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Puntuación
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: GarabuTheme.warmSand, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 18, color: Color(0xFFFFA000)),
                        const SizedBox(width: 4),
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
          ],
        ),
      ),
    );
  }
}
