import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/data/auth_repository.dart';
import '../../core/theme/garabu_theme.dart';
import '../../core/widgets/notebook_background.dart';
import '../lobby/data/lobby_repository.dart';
import '../lobby/domain/couple_model.dart';
import '../pet/data/pet_repository.dart';
import '../pet/domain/pet_model.dart';

class PinturilloWord {
  final String word;
  final String category;
  final String difficulty;

  const PinturilloWord({
    required this.word,
    required this.category,
    required this.difficulty,
  });
}

class DrawnStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  DrawnStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class DibujaAdivinaScreen extends ConsumerStatefulWidget {
  final PetModel pet;
  final CoupleModel? couple;

  const DibujaAdivinaScreen({
    super.key,
    required this.pet,
    this.couple,
  });

  @override
  ConsumerState<DibujaAdivinaScreen> createState() => _DibujaAdivinaScreenState();
}

class _DibujaAdivinaScreenState extends ConsumerState<DibujaAdivinaScreen> {
  final Random _random = Random();
  final TextEditingController _guessController = TextEditingController();

  static const List<PinturilloWord> wordPool = [
    PinturilloWord(word: 'GATO', category: 'Animales', difficulty: 'Facil'),
    PinturilloWord(word: 'PERRO', category: 'Animales', difficulty: 'Facil'),
    PinturilloWord(word: 'SOL', category: 'Naturaleza', difficulty: 'Facil'),
    PinturilloWord(word: 'LUNA', category: 'Naturaleza', difficulty: 'Facil'),
    PinturilloWord(word: 'CASA', category: 'Objetos', difficulty: 'Facil'),
    PinturilloWord(word: 'PIZZA', category: 'Comida', difficulty: 'Facil'),
    PinturilloWord(word: 'MANZANA', category: 'Comida', difficulty: 'Facil'),
    PinturilloWord(word: 'CORAZON', category: 'Simbolos', difficulty: 'Facil'),
    PinturilloWord(word: 'ESTRELLA', category: 'Simbolos', difficulty: 'Facil'),
    PinturilloWord(word: 'FLOR', category: 'Naturaleza', difficulty: 'Facil'),
    PinturilloWord(word: 'BARCO', category: 'Vehiculos', difficulty: 'Medio'),
    PinturilloWord(word: 'AVION', category: 'Vehiculos', difficulty: 'Medio'),
    PinturilloWord(word: 'RELOJ', category: 'Objetos', difficulty: 'Medio'),
    PinturilloWord(word: 'GUITARRA', category: 'Musica', difficulty: 'Medio'),
    PinturilloWord(word: 'SOMBRERO', category: 'Moda', difficulty: 'Medio'),
    PinturilloWord(word: 'ZAPATO', category: 'Moda', difficulty: 'Medio'),
    PinturilloWord(word: 'PASTEL', category: 'Comida', difficulty: 'Medio'),
    PinturilloWord(word: 'HELADO', category: 'Comida', difficulty: 'Medio'),
    PinturilloWord(word: 'MARIPOSA', category: 'Animales', difficulty: 'Medio'),
    PinturilloWord(word: 'CASTILLO', category: 'Lugares', difficulty: 'Dificil'),
  ];

  // Estado del dibujante
  bool _isDrawingMode = true;
  String _currentWord = 'PIZZA';
  Color _selectedColor = const Color(0xFF2C2420);
  final double _strokeWidth = 4.0;
  final List<DrawnStroke> _strokes = [];
  DrawnStroke? _activeStroke;
  int _drawTimeLeft = 60;
  Timer? _drawTimer;

  // Estado del adivinador
  final List<String> _guessAttempts = [];
  bool _hasGuessedCorrectly = false;

  @override
  void initState() {
    super.initState();
    _initGameMode();
  }

  void _initGameMode() {
    final couple = widget.couple;
    final currentUserId = ref.read(currentUserProvider)?.id ?? couple?.user1Id ?? 'user_1';
    final activeP = couple?.activePinturillo;

    if (activeP != null &&
        activeP['status'] == 'waiting_guess' &&
        activeP['artistId'] != currentUserId) {
      // Si la pareja dejó un dibujo pendiente para que yo adivine
      _isDrawingMode = false;
      _currentWord = activeP['word'] ?? 'SOL';
    } else {
      // Modo dibujar: escoger palabra
      _isDrawingMode = true;
      _pickRandomWord();
      _startDrawTimer();
    }
  }

  void _pickRandomWord() {
    final randomWord = wordPool[_random.nextInt(wordPool.length)];
    setState(() {
      _currentWord = randomWord.word;
      _strokes.clear();
      _drawTimeLeft = 60;
    });
  }

  void _startDrawTimer() {
    _drawTimer?.cancel();
    _drawTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_drawTimeLeft > 0) {
        setState(() => _drawTimeLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _drawTimer?.cancel();
    _guessController.dispose();
    super.dispose();
  }

  Future<void> _sendDrawingToPartner() async {
    if (widget.couple == null) return;
    final currentUserId = ref.read(currentUserProvider)?.id ?? widget.couple!.user1Id;
    final currentUserName = currentUserId == widget.couple!.user1Id
        ? widget.couple!.user1Name
        : (widget.couple!.user2Name ?? 'Pareja');

    // Serializar trazos como datos de dibujo
    final strokesData = _strokes.map((s) {
      return {
        'points': s.points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'color': s.color.toARGB32(),
        'width': s.strokeWidth,
      };
    }).toList();

    final pinturilloData = {
      'drawingId': 'pinturillo_${DateTime.now().millisecondsSinceEpoch}',
      'artistId': currentUserId,
      'artistName': currentUserName,
      'word': _currentWord,
      'strokes': strokesData,
      'status': 'waiting_guess',
      'createdAt': DateTime.now().toIso8601String(),
    };

    await ref.read(lobbyRepositoryProvider).updateActivePinturillo(
          coupleId: widget.couple!.id,
          pinturilloData: pinturilloData,
        );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dibujo enviado a tu pareja. Podra adivinarlo al entrar al juego.'),
        duration: Duration(seconds: 3),
      ),
    );

    Navigator.of(context).pop();
  }

  void _onCheckGuess(String targetWord) async {
    final text = _guessController.text.trim().toUpperCase();
    if (text.isEmpty) return;

    _guessController.clear();
    setState(() {
      _guessAttempts.add(text);
    });

    if (text == targetWord.toUpperCase()) {
      setState(() => _hasGuessedCorrectly = true);

      // Recompensas al adivinar
      final petRepo = ref.read(petRepositoryProvider);
      await petRepo.addCoins(petId: widget.pet.id, amount: 25);
      await petRepo.petAnimal(petId: widget.pet.id);
      await petRepo.addExperience(petId: widget.pet.id, expDelta: 50);

      if (widget.couple != null) {
        final currentUserId = ref.read(currentUserProvider)?.id ?? widget.couple!.user1Id;
        await ref.read(lobbyRepositoryProvider).recordGameScore(
              coupleId: widget.couple!.id,
              gameKey: 'dibuja_adivina',
              userId: currentUserId,
              score: 50,
            );

        // Actualizar estado de pinturillo
        final updatedData = Map<String, dynamic>.from(widget.couple?.activePinturillo ?? {});
        updatedData['status'] = 'guessed';
        await ref.read(lobbyRepositoryProvider).updateActivePinturillo(
              coupleId: widget.couple!.id,
              pinturilloData: updatedData,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final coupleAsync = widget.couple != null
        ? ref.watch(currentCoupleProvider(widget.couple!.id))
        : null;
    final currentCouple = coupleAsync?.value ?? widget.couple;
    final activeP = currentCouple?.activePinturillo;
    final currentUserId = ref.read(currentUserProvider)?.id ?? currentCouple?.user1Id ?? 'user_1';

    final hasPendingToGuess = activeP != null &&
        activeP['status'] == 'waiting_guess' &&
        activeP['artistId'] != currentUserId;

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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dibuja y Adivina',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: GarabuTheme.deepEspresso,
                            ),
                          ),
                          Text(
                            _isDrawingMode ? 'Dibuja la palabra secreta' : 'Adivina que dibujo tu pareja',
                            style: const TextStyle(fontSize: 11, color: GarabuTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Selector rapido de modo (Dibujar o Adivinar)
                    Container(
                      decoration: BoxDecoration(
                        color: GarabuTheme.paperWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GarabuTheme.warmSand),
                      ),
                      child: Row(
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _isDrawingMode = true),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              color: _isDrawingMode ? GarabuTheme.primaryBrown.withValues(alpha: 0.15) : Colors.transparent,
                              child: Text(
                                'Dibujar',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _isDrawingMode ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _isDrawingMode = false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              color: !_isDrawingMode ? GarabuTheme.primaryBrown.withValues(alpha: 0.15) : Colors.transparent,
                              child: Text(
                                'Adivinar',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: !_isDrawingMode ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Contenido principal
              Expanded(
                child: _isDrawingMode
                    ? _buildArtistView()
                    : _buildGuesserView(activeP, hasPendingToGuess),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- VISTA DIBUJANTE ---
  Widget _buildArtistView() {
    return Column(
      children: [
        // Palabra asignada y temporizador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: GarabuTheme.paperWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: GarabuTheme.primaryBrown, width: 1.5),
                ),
                child: Text(
                  'Palabra: $_currentWord',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: GarabuTheme.deepEspresso,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _pickRandomWord,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: GarabuTheme.textSecondary),
                label: const Text('Cambiar palabra', style: TextStyle(fontSize: 11, color: GarabuTheme.textSecondary)),
              ),
            ],
          ),
        ),

        // Lienzo de dibujo interactivo
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GarabuTheme.primaryBrown, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  final renderBox = context.findRenderObject() as RenderBox?;
                  if (renderBox == null) return;
                  final localPos = details.localPosition;
                  setState(() {
                    _activeStroke = DrawnStroke(
                      points: [localPos],
                      color: _selectedColor,
                      strokeWidth: _strokeWidth,
                    );
                    _strokes.add(_activeStroke!);
                  });
                },
                onPanUpdate: (details) {
                  if (_activeStroke == null) return;
                  setState(() {
                    _activeStroke!.points.add(details.localPosition);
                  });
                },
                onPanEnd: (_) => _activeStroke = null,
                child: CustomPaint(
                  painter: _PinturilloPainter(strokes: _strokes),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),

        // Barra de herramientas: colores, grosor y borrador
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Colores
              Row(
                children: [
                  const Color(0xFF2C2420),
                  const Color(0xFFE53935),
                  const Color(0xFF1E88E5),
                  const Color(0xFF43A047),
                  const Color(0xFFFB8C00),
                  const Color(0xFF8E24AA),
                ].map((c) {
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: isSelected
                            ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 4)]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Botones de deshacer y limpiar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.undo_rounded, size: 20),
                    onPressed: _strokes.isEmpty
                        ? null
                        : () => setState(() => _strokes.removeLast()),
                    tooltip: 'Deshacer trazo',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, size: 20),
                    onPressed: _strokes.isEmpty
                        ? null
                        : () => setState(() => _strokes.clear()),
                    tooltip: 'Limpiar lienzo',
                  ),
                ],
              ),
            ],
          ),
        ),

        // Boton de envio
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _strokes.isEmpty ? null : _sendDrawingToPartner,
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Enviar Dibujo a Pareja', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: GarabuTheme.primaryBrown,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- VISTA ADIVINADOR ---
  Widget _buildGuesserView(Map<String, dynamic>? activeP, bool hasPending) {
    // Si hay un dibujo guardado de la pareja, renderizar sus trazos
    List<DrawnStroke> remoteStrokes = [];
    String targetWord = _currentWord;
    String artistName = 'Tu pareja';

    if (activeP != null && activeP['strokes'] is List) {
      targetWord = activeP['word'] ?? _currentWord;
      artistName = activeP['artistName'] ?? 'Tu pareja';
      final list = activeP['strokes'] as List<dynamic>;
      for (final s in list) {
        final rawPts = (s['points'] as List<dynamic>?) ?? [];
        final pts = rawPts.map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())).toList();
        final cVal = (s['color'] as num?)?.toInt() ?? 0xFF2C2420;
        final wVal = (s['width'] as num?)?.toDouble() ?? 4.0;
        remoteStrokes.add(DrawnStroke(points: pts, color: Color(cVal), strokeWidth: wVal));
      }
    } else {
      remoteStrokes = _strokes;
    }

    // Pista con letras ocultas (ej: P _ Z Z _)
    final maskedHint = targetWord.split('').map((char) {
      if (_hasGuessedCorrectly) return char;
      return '_';
    }).join(' ');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: [
          // Titulo de estado
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: GarabuTheme.paperWhite,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: GarabuTheme.warmSand),
            ),
            child: Row(
              children: [
                const Icon(Icons.palette_rounded, size: 18, color: GarabuTheme.primaryBrown),
                const SizedBox(width: 8),
                Text(
                  'Dibujado por: $artistName',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso),
                ),
                const Spacer(),
                Text(
                  '${targetWord.length} letras',
                  style: const TextStyle(fontSize: 12, color: GarabuTheme.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Lienzo con el dibujo recibido
          Container(
            width: double.infinity,
            height: 260,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: GarabuTheme.primaryBrown, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: remoteStrokes.isEmpty
                ? const Center(
                    child: Text(
                      'No hay dibujo activo todavia.\nElige Dibujar arriba o dile a tu pareja que te envie uno.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.5, color: GarabuTheme.textSecondary),
                    ),
                  )
                : CustomPaint(
                    painter: _PinturilloPainter(strokes: remoteStrokes),
                    size: const Size(double.infinity, 260),
                  ),
          ),
          const SizedBox(height: 14),

          // Pista de letras
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _hasGuessedCorrectly ? const Color(0xFFE8F5E9) : GarabuTheme.paperWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _hasGuessedCorrectly ? const Color(0xFF43A047) : GarabuTheme.warmSand,
                width: 1.5,
              ),
            ),
            child: Text(
              _hasGuessedCorrectly ? 'CORRECTO: $targetWord' : maskedHint,
              style: TextStyle(
                fontSize: 20,
                letterSpacing: 4,
                fontWeight: FontWeight.bold,
                color: _hasGuessedCorrectly ? const Color(0xFF2E7D32) : GarabuTheme.deepEspresso,
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (_hasGuessedCorrectly) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 22),
                  SizedBox(width: 8),
                  Text(
                    '¡Adivinaste la palabra! +25 Monedas y +50 EXP',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2E7D32)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _hasGuessedCorrectly = false;
                    _guessAttempts.clear();
                    _isDrawingMode = true;
                    _pickRandomWord();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: GarabuTheme.primaryBrown,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Ahora me toca Dibujar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ] else ...[
            // Entrada de texto para adivinar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _guessController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'Escribe tu respuesta...',
                      hintStyle: const TextStyle(fontSize: 13, color: GarabuTheme.textSecondary),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: GarabuTheme.paperWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: GarabuTheme.warmSand),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: GarabuTheme.warmSand),
                      ),
                    ),
                    onSubmitted: (_) => _onCheckGuess(targetWord),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _onCheckGuess(targetWord),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GarabuTheme.primaryBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  ),
                  child: const Text('Adivinar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PinturilloPainter extends CustomPainter {
  final List<DrawnStroke> strokes;

  _PinturilloPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.isEmpty) continue;
      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, stroke.strokeWidth / 2, paint..style = PaintingStyle.fill);
        continue;
      }

      final path = Path();
      path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (int i = 1; i < stroke.points.length; i++) {
        path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PinturilloPainter oldDelegate) => true;
}
