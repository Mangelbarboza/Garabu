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

class TriviaQuestion {
  final String category;
  final String question;
  final List<String> Function(String user1, String user2) optionsBuilder;
  final int bonusPoints;

  TriviaQuestion({
    required this.category,
    required this.question,
    required this.optionsBuilder,
    this.bonusPoints = 20,
  });
}

class TriviaParejaScreen extends ConsumerStatefulWidget {
  final PetModel pet;
  final CoupleModel? couple;

  const TriviaParejaScreen({
    super.key,
    required this.pet,
    this.couple,
  });

  @override
  ConsumerState<TriviaParejaScreen> createState() => _TriviaParejaScreenState();
}

class _TriviaParejaScreenState extends ConsumerState<TriviaParejaScreen>
    with TickerProviderStateMixin {
  final Random _random = Random();

  late AnimationController _bounceController;
  late AnimationController _heartController;

  int _currentIndex = 0;
  int _score = 0;
  int? _selectedOptionIndex;
  bool _isRoundFinished = false;

  late List<TriviaQuestion> _roundQuestions;

  // Banco de preguntas
  final List<TriviaQuestion> _allQuestions = [
    TriviaQuestion(
      category: '💑 ¿Quién es más...?',
      question: '¿Quién es más probable que se quede dormido a mitad de una película?',
      optionsBuilder: (u1, u2) => [
        '¡$u1 sin duda! 😴',
        '¡$u2 totalmente! 🍿',
        '¡Los dos caemos rendidos! 😂',
        '¡Ninguno, vemos maratones! 🎬',
      ],
      bonusPoints: 20,
    ),
    TriviaQuestion(
      category: '🐾 Cuidado de Garabu',
      question: '¿Qué le gusta más a Garabu después de comer frutitas?',
      optionsBuilder: (u1, u2) => [
        '¡Que le hagan muchas caricias! 🥰',
        '¡Dormir su siesta bien calientito! 💤',
        '¡Ponerse sus prendas favoritas! 👗',
        '¡Jugar a atrapar garabutos! 🎮',
      ],
      bonusPoints: 25,
    ),
    TriviaQuestion(
      category: '💑 ¿Quién es más...?',
      question: '¿Quién tarda más tiempo en arreglarse antes de salir?',
      optionsBuilder: (u1, u2) => [
        '¡$u1 se toma todo su tiempo! 👗',
        '¡$u2 tarda un siglo entero! ⏱️',
        '¡Ambos somos súper rápidos! ⚡',
        '¡Garabu tarda más cambiándose! 🎀',
      ],
      bonusPoints: 20,
    ),
    TriviaQuestion(
      category: '💌 Amor & Pareja',
      question: '¿Cuál es el plan perfecto para un fin de semana juntos?',
      optionsBuilder: (u1, u2) => [
        'Peli, cobijitas y consentir a Garabu 🛋️',
        'Salir a cenar algo delicioso 🍕',
        'Aventuras, caminatas y fotos juntos 📸',
        'Dormir 12 horas seguidas sin alarma 😴',
      ],
      bonusPoints: 25,
    ),
    TriviaQuestion(
      category: '💑 ¿Quién es más...?',
      question: '¿Quién suele tener hambre primero o pedir snacks a media noche?',
      optionsBuilder: (u1, u2) => [
        '¡$u1 siempre tiene antojitos! 🍓',
        '¡$u2 asalta el refrigerador! 🍰',
        '¡Los dos compartimos comida! 🍫',
        '¡Garabu exige su banquete! 🍇',
      ],
      bonusPoints: 20,
    ),
    TriviaQuestion(
      category: '🐾 Curiosidad Garabu',
      question: '¿Qué sucede si Garabu no duerme en toda la noche?',
      optionsBuilder: (u1, u2) => [
        '¡Se le baja la energía y puede enfermar! 🤒',
        '¡Se vuelve una estrella del rock! 🎸',
        '¡Aprende a cocinar galletitas! 🍪',
        '¡Le crecen alitas de mariposa! 🦋',
      ],
      bonusPoints: 25,
    ),
    TriviaQuestion(
      category: '💑 ¿Quién es más...?',
      question: '¿Quién es más cariñoso y da más abrazos durante el día?',
      optionsBuilder: (u1, u2) => [
        '¡$u1 es puro amor y abrazos! 💕',
        '¡$u2 no me suelta nunca! 🤗',
        '¡Empate técnico de mimos! 💏',
        '¡Garabu nos abraza a ambos! 🐾',
      ],
      bonusPoints: 20,
    ),
    TriviaQuestion(
      category: '💌 Recuerdos de Pareja',
      question: '¿Quién recuerda más los detalles y fechas especiales?',
      optionsBuilder: (u1, u2) => [
        '¡$u1 tiene memoria de elefante! 📅',
        '¡$u2 lleva la cuenta exacta! 🧠',
        '¡El buzón de Garabu nos ayuda! 💌',
        '¡Lo celebramos todos los días! ✨',
      ],
      bonusPoints: 25,
    ),
    TriviaQuestion(
      category: '🐾 Moda Garabu',
      question: '¿Cuántas prendas y accesorios puede tener equipados Garabu al mismo tiempo?',
      optionsBuilder: (u1, u2) => [
        '¡Hasta 5 prendas fabulosas! 👑',
        '¡Solo una camisa! 👕',
        '¡100 sombreros a la vez! 🎩',
        '¡Ninguna, le gusta estar libre! 🍃',
      ],
      bonusPoints: 30,
    ),
    TriviaQuestion(
      category: '💑 ¿Quién es más...?',
      question: '¿Quién hace reír más al otro con ocurrencias o bromas?',
      optionsBuilder: (u1, u2) => [
        '¡$u1 es el comediante oficial! 😂',
        '¡$u2 me mata de risa siempre! 🤣',
        '¡Nos reímos de puras tonterías juntos! 💖',
        '¡Las caras que hace Garabu! 🤪',
      ],
      bonusPoints: 20,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _initRound();
  }

  void _initRound() {
    final shuffled = List<TriviaQuestion>.from(_allQuestions)..shuffle(_random);
    _roundQuestions = shuffled.take(5).toList();
    _currentIndex = 0;
    _score = 0;
    _selectedOptionIndex = null;
    _isRoundFinished = false;
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _heartController.dispose();
    super.dispose();
  }

  void _onSelectOption(int index) {
    if (_selectedOptionIndex != null) return; // Evitar doble click

    setState(() {
      _selectedOptionIndex = index;
      _score += _roundQuestions[_currentIndex].bonusPoints;
    });

    // Salto feliz de Garabu
    _bounceController.forward(from: 0.0);

    // Pequeño retardo para avanzar automáticamente
    Future.delayed(const Duration(milliseconds: 950), () {
      if (!mounted) return;
      if (_currentIndex + 1 < _roundQuestions.length) {
        setState(() {
          _currentIndex++;
          _selectedOptionIndex = null;
        });
      } else {
        _finishRound();
      }
    });
  }

  Future<void> _finishRound() async {
    setState(() {
      _isRoundFinished = true;
    });

    try {
      final petRepo = ref.read(petRepositoryProvider);
      // Recompensas: Monedas, Felicidad completa y +50 EXP
      final coinsEarned = max(18, (_score / 4).round());
      await petRepo.addCoins(petId: widget.pet.id, amount: coinsEarned);
      await petRepo.petAnimal(petId: widget.pet.id);
      await petRepo.addExperience(petId: widget.pet.id, expDelta: 50);

      // Guardar récord de pareja
      if (widget.couple != null) {
        final authUser = ref.read(currentUserProvider);
        final userId = authUser?.id ?? widget.couple!.user1Id;
        await ref.read(lobbyRepositoryProvider).recordGameScore(
              coupleId: widget.couple!.id,
              gameKey: 'trivia_pareja',
              userId: userId,
              score: _score,
            );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final u1 = widget.couple?.user1Name ?? 'Uno';
    final u2 = widget.couple?.user2Name ?? 'El otro';

    // Récords existentes
    final recU1 = widget.couple?.gameRecords['trivia_pareja_${widget.couple?.user1Id}'] ?? 0;
    final recU2 = widget.couple?.gameRecords['trivia_pareja_${widget.couple?.user2Id}'] ?? 0;

    return Scaffold(
      backgroundColor: GarabuTheme.background,
      body: NotebookBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Barra superior
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GarabuTheme.deepEspresso),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trivia de Pareja 💑',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: GarabuTheme.deepEspresso,
                            ),
                          ),
                          Text(
                            '¡Descubran su complicidad y ganen EXP!',
                            style: TextStyle(fontSize: 11, color: GarabuTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Puntos acumulados en la ronda
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFB74D)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.favorite_rounded, color: Color(0xFFE91E63), size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '$_score pts',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFD81B60)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Chip de récords mutuos de pareja
              if (widget.couple != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: GarabuTheme.paperWhite.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GarabuTheme.warmSand.withValues(alpha: 0.8)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFA000), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '$u1: $recU1 pts  |  $u2: $recU2 pts',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: GarabuTheme.deepEspresso,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Barra de progreso de preguntas
              if (!_isRoundFinished)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pregunta ${_currentIndex + 1} de ${_roundQuestions.length}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso),
                          ),
                          AnimatedBuilder(
                            animation: _heartController,
                            builder: (context, _) {
                              return Transform.scale(
                                scale: 1.0 + (_heartController.value * 0.15),
                                child: const Icon(Icons.favorite, color: Color(0xFFE91E63), size: 18),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / _roundQuestions.length,
                          backgroundColor: GarabuTheme.warmSand.withValues(alpha: 0.4),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE91E63)),
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                ),

              // Contenido principal: o la ronda activa o la pantalla de resultados
              Expanded(
                child: _isRoundFinished
                    ? _buildFinishedView(u1, u2)
                    : _buildQuestionView(u1, u2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionView(String u1, String u2) {
    final currentQ = _roundQuestions[_currentIndex];
    final options = currentQ.optionsBuilder(u1, u2);
    final eyeColor = Color(widget.pet.eyesConfig.color);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Garabu animado y reactivo
          AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              final val = _bounceController.value;
              final jumpOffset = sin(val * pi) * -20.0;
              final squash = 1.0 + sin(val * pi) * 0.08;
              return Transform.translate(
                offset: Offset(0, jumpOffset),
                child: Transform.scale(
                  scaleY: squash,
                  child: child,
                ),
              );
            },
            child: SizedBox(
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Círculo decorativo
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFCE4EC).withValues(alpha: 0.6),
                      border: Border.all(color: const Color(0xFFF48FB1).withValues(alpha: 0.5), width: 1.5),
                    ),
                  ),

                  // Cuerpo del Garabu
                  if (widget.pet.bodyImageUrl.isNotEmpty)
                    GarabuImage(
                      imageUrl: widget.pet.bodyImageUrl,
                      width: 110,
                      height: 110,
                      fit: BoxFit.contain,
                    )
                  else
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: GarabuTheme.warmSand.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🐾', style: TextStyle(fontSize: 40)),
                      ),
                    ),

                  // Ojos de Garabu (felices si seleccionó respuesta)
                  Positioned(
                    top: 48,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        EyeWidget(
                          size: 16,
                          color: eyeColor,
                          isLeft: true,
                          isHappy: _selectedOptionIndex != null,
                          blinkProgress: 0.0,
                          lookDirection: Offset.zero,
                        ),
                        const SizedBox(width: 18),
                        EyeWidget(
                          size: 16,
                          color: eyeColor,
                          isLeft: false,
                          isHappy: _selectedOptionIndex != null,
                          blinkProgress: 0.0,
                          lookDirection: Offset.zero,
                        ),
                      ],
                    ),
                  ),

                  // Boca sonriente
                  Positioned(
                    top: 68,
                    child: MouthWidget(
                      isOpen: _selectedOptionIndex != null,
                      emotion: _selectedOptionIndex != null ? PetEmotion.happy : PetEmotion.neutral,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Tarjeta de la Pregunta
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: GarabuTheme.paperWhite,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE91E63).withValues(alpha: 0.3), width: 1.8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE91E63).withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    currentQ.category,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC2185B),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  currentQ.question,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GarabuTheme.deepEspresso,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Opciones de respuesta
          Column(
            children: List.generate(options.length, (idx) {
              final isSelected = _selectedOptionIndex == idx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFCE4EC)
                          : GarabuTheme.paperWhite,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFE91E63)
                            : GarabuTheme.warmSand.withValues(alpha: 0.8),
                        width: isSelected ? 2.2 : 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? const Color(0xFFE91E63).withValues(alpha: 0.15)
                              : Colors.black.withValues(alpha: 0.02),
                          blurRadius: isSelected ? 8 : 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => _onSelectOption(idx),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? const Color(0xFFE91E63)
                                      : GarabuTheme.warmSand.withValues(alpha: 0.25),
                                ),
                                child: Center(
                                  child: isSelected
                                      ? const Icon(Icons.favorite_rounded, color: Colors.white, size: 16)
                                      : Text(
                                          String.fromCharCode(65 + idx),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: GarabuTheme.deepEspresso,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  options[idx],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected
                                        ? const Color(0xFFC2185B)
                                        : GarabuTheme.deepEspresso,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFinishedView(String u1, String u2) {
    final earnedCoins = max(18, (_score / 4).round());

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: GarabuTheme.paperWhite,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE91E63), width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 6),
              const Text(
                '¡Ronda Completada!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: GarabuTheme.deepEspresso,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '¡$u1 y $u2 tienen una conexión mágica!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: GarabuTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              // Puntos obtenidos y porcentaje de amor
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE4EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite_rounded, color: Color(0xFFE91E63), size: 28),
                        const SizedBox(width: 8),
                        Text(
                          '$_score Puntos de Amor',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC2185B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '100% Amor y Complicidad Cósmica ✨',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFAD1457)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Recompensas ganadas
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFA000), size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '+$earnedCoins',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFE65100)),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Icon(Icons.star_rounded, color: Color(0xFF43A047), size: 20),
                        SizedBox(width: 4),
                        Text(
                          '+50 EXP',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2E7D32)),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Icon(Icons.mood_rounded, color: Color(0xFFE91E63), size: 20),
                        SizedBox(width: 4),
                        Text(
                          'Felicidad ❤️',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFC2185B)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Botones de acción
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _initRound();
                    });
                  },
                  icon: const Icon(Icons.replay_rounded, size: 20),
                  label: const Text('Jugar Otra Ronda', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Volver con Garabu',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
