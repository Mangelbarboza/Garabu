import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/data/auth_repository.dart';
import '../../core/theme/garabu_theme.dart';
import '../../core/widgets/garabu_image.dart';
import '../../core/widgets/notebook_background.dart';
import '../lobby/data/lobby_repository.dart';
import '../lobby/domain/couple_model.dart';
import '../pet/data/pet_repository.dart';
import '../pet/domain/pet_model.dart';

class TriviaQuestionData {
  final String category;
  final String question;
  final List<String> Function(String user1, String user2) optionsBuilder;

  TriviaQuestionData({
    required this.category,
    required this.question,
    required this.optionsBuilder,
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

  int _currentIndex = 0;
  int? _selectedOptionIndex;
  final List<int> _myAnswers = [];

  // Banco amplio de preguntas sin emojis
  static final List<TriviaQuestionData> questionBank = [
    TriviaQuestionData(
      category: 'Quien es mas probable que',
      question: 'Quien es mas probable que se quede dormido a mitad de una pelicula?',
      optionsBuilder: (u1, u2) => [
        'Definitivamente $u1',
        'Sin duda alguna $u2',
        'Ambos caemos rendidos por igual',
        'Ninguno, vemos la pelicula completa',
      ],
    ),
    TriviaQuestionData(
      category: 'Quien es mas probable que',
      question: 'Quien tarda mas tiempo en arreglarse antes de salir?',
      optionsBuilder: (u1, u2) => [
        'Claramente $u1',
        'Sin duda $u2 tarda mas',
        'Tardamos exactamente lo mismo',
        'Somos bastante rapidos los dos',
      ],
    ),
    TriviaQuestionData(
      category: 'Quien es mas probable que',
      question: 'Quien suele tener hambre primero o buscar comida a media noche?',
      optionsBuilder: (u1, u2) => [
        '$u1 siempre tiene apetito',
        '$u2 es quien busca snacks',
        'Los dos nos antojamos juntos',
        'Rara vez comemos tan tarde',
      ],
    ),
    TriviaQuestionData(
      category: 'Quien es mas probable que',
      question: 'Quien es mas detallista y recuerda las fechas especiales con anticipacion?',
      optionsBuilder: (u1, u2) => [
        '$u1 tiene mejor memoria para fechas',
        '$u2 siempre esta al pendiente',
        'Ambos nos recordamos mutuamente',
        'Usamos recordatorios o calendarios',
      ],
    ),
    TriviaQuestionData(
      category: 'Quien es mas probable que',
      question: 'Quien hace reir mas al otro con ocurrencias o anecdotas diarias?',
      optionsBuilder: (u1, u2) => [
        '$u1 siempre saca carcajadas',
        '$u2 tiene un humor increible',
        'Nos complementamos y reimos juntos',
        'Ambos somos muy serios en el fondo',
      ],
    ),
    TriviaQuestionData(
      category: 'Planes y momentos',
      question: 'Cual seria el plan ideal para una tarde tranquila juntos?',
      optionsBuilder: (u1, u2) => [
        'Ver series o peliculas con comida rica',
        'Pasear al aire libre o tomar un cafe',
        'Cocinar algo nuevo y escuchar musica',
        'Descansar y jugar con Garabu',
      ],
    ),
    TriviaQuestionData(
      category: 'Planes y momentos',
      question: 'Si pudieran hacer una escapada de fin de semana, que preferirian?',
      optionsBuilder: (u1, u2) => [
        'Cabaña acogedora en clima frio o montaña',
        'Playa con sol y brisa marina',
        'Pueblo magico con buena gastronomia',
        'Quedarse en casa sin alarmas ni pendientes',
      ],
    ),
    TriviaQuestionData(
      category: 'Gustos y estilo',
      question: 'Al momento de pedir comida para compartir, como deciden?',
      optionsBuilder: (u1, u2) => [
        'Uno propone y el otro acepta de inmediato',
        'Tardamos un buen rato debatiendo opciones',
        'Pedimos dos cosas distintas para probar ambas',
        'Siempre terminamos pidiendo lo clasico',
      ],
    ),
    TriviaQuestionData(
      category: 'Mundo de Garabu',
      question: 'Que creen que prefiere Garabu antes de ir a dormir?',
      optionsBuilder: (u1, u2) => [
        'Que le apaguen la luz y le den mimos',
        'Un snack o frutita de media noche',
        'Estar equipado con sus mejores accesorios',
        'Una partida rapida para gastar energia',
      ],
    ),
    TriviaQuestionData(
      category: 'Mundo de Garabu',
      question: 'Cual es el mayor secreto para mantener la racha de dias juntos?',
      optionsBuilder: (u1, u2) => [
        'Entrar a diario y saludarse con caricias',
        'Compartir tiempo y enviarse cartitas',
        'Comprar accesorios y vestir al personaje',
        'Ganar monedas en la sala de juegos',
      ],
    ),
    TriviaQuestionData(
      category: 'Quien es mas probable que',
      question: 'Quien propone primero iniciar una nueva aventura o proyecto?',
      optionsBuilder: (u1, u2) => [
        '$u1 toma la iniciativa',
        '$u2 es quien tiene las ideas',
        'Casi siempre surge en conversaciones mutuas',
        'Lo pensamos mucho antes de actuar',
      ],
    ),
    TriviaQuestionData(
      category: 'Gustos y estilo',
      question: 'Que musica disfrutan mas escuchar cuando estan juntos en el auto o casa?',
      optionsBuilder: (u1, u2) => [
        'Pop o musica tranquila en español',
        'Rock o clasicos para cantar fuerte',
        'Reggaeton o ritmos para bailar',
        'Listas variadas y lo que salga en aleatorio',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  String _getCurrentUserId() {
    final authUser = ref.read(currentUserProvider);
    return authUser?.id ?? widget.couple?.user1Id ?? 'user_1';
  }

  String _getPartnerUserId() {
    final currentId = _getCurrentUserId();
    if (widget.couple == null) return 'user_2';
    return widget.couple!.user1Id == currentId
        ? (widget.couple!.user2Id ?? 'user_2')
        : widget.couple!.user1Id;
  }

  Map<String, dynamic> _getOrCreateTriviaRound(CoupleModel couple) {
    if (couple.activeTrivia != null &&
        couple.activeTrivia!['questionIndices'] is List &&
        (couple.activeTrivia!['questionIndices'] as List).length == 5) {
      return Map<String, dynamic>.from(couple.activeTrivia!);
    }

    // Generar nueva ronda con 5 preguntas aleatorias del banco
    final indices = List.generate(questionBank.length, (i) => i)..shuffle(_random);
    final selectedIndices = indices.take(5).toList();

    return {
      'roundId': 'trivia_${DateTime.now().millisecondsSinceEpoch}',
      'questionIndices': selectedIndices,
      'answers': <String, dynamic>{},
      'status': 'active',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> _submitAnswers(Map<String, dynamic> activeTrivia) async {
    if (widget.couple == null) return;
    final currentUserId = _getCurrentUserId();
    final partnerUserId = _getPartnerUserId();

    final answersMap = Map<String, dynamic>.from(activeTrivia['answers'] ?? {});
    answersMap[currentUserId] = _myAnswers;
    activeTrivia['answers'] = answersMap;

    final partnerAnswers = answersMap[partnerUserId] as List<dynamic>?;
    final bothCompleted = partnerAnswers != null && partnerAnswers.length == 5;

    if (bothCompleted) {
      activeTrivia['status'] = 'completed';
      // Calcular coincidencias (Match)
      int matches = 0;
      for (int i = 0; i < 5; i++) {
        if (_myAnswers[i] == partnerAnswers[i]) {
          matches++;
        }
      }
      activeTrivia['matches'] = matches;

      // Recompensas: Monedas, EXP y Felicidad
      final earnedCoins = 15 + (matches * 5);
      final petRepo = ref.read(petRepositoryProvider);
      await petRepo.addCoins(petId: widget.pet.id, amount: earnedCoins);
      await petRepo.petAnimal(petId: widget.pet.id);
      await petRepo.addExperience(petId: widget.pet.id, expDelta: 50);

      // Guardar récord
      await ref.read(lobbyRepositoryProvider).recordGameScore(
            coupleId: widget.couple!.id,
            gameKey: 'trivia_pareja',
            userId: currentUserId,
            score: matches * 20,
          );
    }

    await ref.read(lobbyRepositoryProvider).updateActiveTrivia(
          coupleId: widget.couple!.id,
          triviaData: activeTrivia,
        );
  }

  Future<void> _startNewRound() async {
    if (widget.couple == null) return;
    final indices = List.generate(questionBank.length, (i) => i)..shuffle(_random);
    final selectedIndices = indices.take(5).toList();

    final newTrivia = {
      'roundId': 'trivia_${DateTime.now().millisecondsSinceEpoch}',
      'questionIndices': selectedIndices,
      'answers': <String, dynamic>{},
      'status': 'active',
      'createdAt': DateTime.now().toIso8601String(),
    };

    setState(() {
      _currentIndex = 0;
      _selectedOptionIndex = null;
      _myAnswers.clear();
    });

    await ref.read(lobbyRepositoryProvider).updateActiveTrivia(
          coupleId: widget.couple!.id,
          triviaData: newTrivia,
        );
  }

  void _onOptionChosen(int optionIdx, Map<String, dynamic> activeTrivia) {
    if (_selectedOptionIndex != null) return;

    setState(() {
      _selectedOptionIndex = optionIdx;
      _myAnswers.add(optionIdx);
    });

    _bounceController.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      if (_currentIndex + 1 < 5) {
        setState(() {
          _currentIndex++;
          _selectedOptionIndex = null;
        });
      } else {
        await _submitAnswers(activeTrivia);
        if (mounted) setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = widget.couple != null
        ? ref.watch(currentCoupleProvider(widget.couple!.id))
        : null;
    final currentCouple = coupleAsync?.value ?? widget.couple;

    final u1 = currentCouple?.user1Name ?? 'Pareja 1';
    final u2 = currentCouple?.user2Name ?? 'Pareja 2';
    final currentUserId = _getCurrentUserId();
    final partnerUserId = _getPartnerUserId();
    final partnerName = currentUserId == currentCouple?.user1Id ? u2 : u1;

    if (currentCouple == null) {
      return const Scaffold(
        body: Center(child: Text('Cargando trivia...')),
      );
    }

    final activeTrivia = _getOrCreateTriviaRound(currentCouple);
    final answersMap = (activeTrivia['answers'] as Map<dynamic, dynamic>?) ?? {};
    final mySubmittedAnswers = answersMap[currentUserId] as List<dynamic>?;
    final partnerSubmittedAnswers = answersMap[partnerUserId] as List<dynamic>?;

    final iHaveFinished = mySubmittedAnswers != null && mySubmittedAnswers.length == 5;
    final partnerHasFinished = partnerSubmittedAnswers != null && partnerSubmittedAnswers.length == 5;

    // Récords mutuos
    final recU1 = currentCouple.gameRecords['trivia_pareja_${currentCouple.user1Id}'] ?? 0;
    final recU2 = currentCouple.gameRecords['trivia_pareja_${currentCouple.user2Id}'] ?? 0;

    return Scaffold(
      backgroundColor: GarabuTheme.background,
      body: NotebookBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Barra superior limpia sin emojis
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
                            'Trivia de Pareja',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: GarabuTheme.deepEspresso,
                            ),
                          ),
                          Text(
                            'Respondan por separado y descubran sus coincidencias',
                            style: TextStyle(fontSize: 11, color: GarabuTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: GarabuTheme.paperWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GarabuTheme.warmSand),
                      ),
                      child: Text(
                        'Récords: $recU1 | $recU2',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso),
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido dinámico según el estado de la ronda
              Expanded(
                child: () {
                  if (iHaveFinished && partnerHasFinished) {
                    // Ambos han terminado: mostrar resultados de coincidencia (Match)
                    return _buildMatchResultsView(
                      currentCouple,
                      activeTrivia,
                      mySubmittedAnswers,
                      partnerSubmittedAnswers,
                      u1,
                      u2,
                    );
                  } else if (iHaveFinished && !partnerHasFinished) {
                    // Yo ya terminé, esperando a la pareja
                    return _buildWaitingPartnerView(partnerName);
                  } else {
                    // Jugando la ronda de 5 preguntas
                    return _buildAnsweringView(activeTrivia, u1, u2);
                  }
                }(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Vista 1: Respondiendo las preguntas
  Widget _buildAnsweringView(Map<String, dynamic> activeTrivia, String u1, String u2) {
    final questionIndices = (activeTrivia['questionIndices'] as List<dynamic>).cast<int>();
    final qIndex = questionIndices[_currentIndex];
    final currentQ = questionBank[qIndex % questionBank.length];
    final options = currentQ.optionsBuilder(u1, u2);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          // Progreso
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pregunta ${_currentIndex + 1} de 5',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso),
              ),
              Text(
                currentQ.category,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: GarabuTheme.primaryBrown),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_currentIndex + 1) / 5.0,
              backgroundColor: GarabuTheme.warmSand.withValues(alpha: 0.35),
              valueColor: const AlwaysStoppedAnimation<Color>(GarabuTheme.primaryBrown),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),

          // Silueta pequeña de Garabu
          AnimatedBuilder(
            animation: _bounceController,
            builder: (context, child) {
              final val = _bounceController.value;
              final jump = sin(val * pi) * -12.0;
              return Transform.translate(
                offset: Offset(0, jump),
                child: child,
              );
            },
            child: SizedBox(
              width: 100,
              height: 100,
              child: GarabuImage(
                imageUrl: widget.pet.bodyImageUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Tarjeta de la Pregunta (Limpia, tipografía cuidada sin emojis)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: GarabuTheme.paperWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GarabuTheme.warmSand, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              currentQ.question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: GarabuTheme.deepEspresso,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Opciones de respuesta
          Column(
            children: List.generate(options.length, (idx) {
              final isSelected = _selectedOptionIndex == idx;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  width: double.infinity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GarabuTheme.primaryBrown.withValues(alpha: 0.1)
                          : GarabuTheme.paperWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? GarabuTheme.primaryBrown : GarabuTheme.warmSand.withValues(alpha: 0.8),
                        width: isSelected ? 2.0 : 1.2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _onOptionChosen(idx, activeTrivia),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 26,
                                height: 26,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? GarabuTheme.primaryBrown
                                      : GarabuTheme.warmSand.withValues(alpha: 0.3),
                                ),
                                child: Center(
                                  child: Text(
                                    String.fromCharCode(65 + idx),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : GarabuTheme.deepEspresso,
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
                                    color: isSelected ? GarabuTheme.primaryBrown : GarabuTheme.deepEspresso,
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

  // Vista 2: En espera de que la pareja responda
  Widget _buildWaitingPartnerView(String partnerName) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: GarabuTheme.paperWhite,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: GarabuTheme.warmSand, width: 1.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: GarabuImage(
                  imageUrl: widget.pet.bodyImageUrl,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tus respuestas han sido guardadas',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: GarabuTheme.deepEspresso,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: GarabuTheme.warmSand.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'En espera de que $partnerName responda...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: GarabuTheme.primaryBrown,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'En cuanto ambos hayan respondido la misma ronda de preguntas, podran entrar aqui para ver en cuantas hicieron coincidencia.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: GarabuTheme.textSecondary, height: 1.35),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GarabuTheme.primaryBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Volver a Casa', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Vista 3: Resultados de Match entre ambos
  Widget _buildMatchResultsView(
    CoupleModel couple,
    Map<String, dynamic> activeTrivia,
    List<dynamic> myAnswers,
    List<dynamic> partnerAnswers,
    String u1,
    String u2,
  ) {
    final questionIndices = (activeTrivia['questionIndices'] as List<dynamic>).cast<int>();
    final currentUserId = _getCurrentUserId();
    final user1Answers = currentUserId == couple.user1Id ? myAnswers : partnerAnswers;
    final user2Answers = currentUserId == couple.user1Id ? partnerAnswers : myAnswers;

    int matchCount = 0;
    for (int i = 0; i < 5; i++) {
      if (user1Answers[i] == user2Answers[i]) {
        matchCount++;
      }
    }
    final matchPercent = (matchCount / 5.0 * 100).round();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Resumen de Coincidencias
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GarabuTheme.paperWhite,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: GarabuTheme.primaryBrown, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Resultados de Coincidencia',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: GarabuTheme.deepEspresso,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$matchCount de 5 respuestas coincidieron ($matchPercent% Match)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: GarabuTheme.primaryBrown,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD54F)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        '+${15 + (matchCount * 5)} Monedas',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFFE65100)),
                      ),
                      const Text(
                        '+50 EXP',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF2E7D32)),
                      ),
                      const Text(
                        'Felicidad al 100%',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFFC2185B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Desglose de cada una de las 5 preguntas
          ...List.generate(5, (idx) {
            final qIndex = questionIndices[idx];
            final q = questionBank[qIndex % questionBank.length];
            final options = q.optionsBuilder(u1, u2);
            final ans1 = user1Answers[idx] as int;
            final ans2 = user2Answers[idx] as int;
            final isMatch = ans1 == ans2;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMatch ? const Color(0xFFE8F5E9) : GarabuTheme.paperWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isMatch ? const Color(0xFF81C784) : GarabuTheme.warmSand.withValues(alpha: 0.8),
                  width: isMatch ? 1.8 : 1.0,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isMatch ? const Color(0xFF2E7D32) : GarabuTheme.textSecondary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isMatch ? 'COINCIDENCIA' : 'DIFERENTES',
                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Pregunta ${idx + 1}',
                        style: const TextStyle(fontSize: 11, color: GarabuTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    q.question,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso),
                  ),
                  const SizedBox(height: 8),
                  if (isMatch)
                    Text(
                      'Ambos eligieron: ${options[ans1]}',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)),
                    )
                  else ...[
                    Text('$u1: ${options[ans1]}', style: const TextStyle(fontSize: 12, color: GarabuTheme.deepEspresso)),
                    const SizedBox(height: 2),
                    Text('$u2: ${options[ans2]}', style: const TextStyle(fontSize: 12, color: GarabuTheme.deepEspresso)),
                  ],
                ],
              ),
            );
          }),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _startNewRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: GarabuTheme.primaryBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text('Iniciar Nueva Ronda de Trivia', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Volver a Casa', style: TextStyle(color: GarabuTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}
