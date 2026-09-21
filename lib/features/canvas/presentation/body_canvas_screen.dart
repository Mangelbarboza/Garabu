import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/garabu_theme.dart';
import '../../../core/widgets/notebook_background.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../lobby/data/lobby_repository.dart';
import '../../lobby/domain/couple_model.dart';
import '../../pet/data/pet_repository.dart';
import '../../pet/domain/pet_model.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/eye_widget.dart';

class BodyCanvasScreen extends ConsumerStatefulWidget {
  final CoupleModel couple;
  final String petName;
  final PetModel? existingPet;

  const BodyCanvasScreen({
    super.key,
    required this.couple,
    required this.petName,
    this.existingPet,
  });

  @override
  ConsumerState<BodyCanvasScreen> createState() => _BodyCanvasScreenState();
}

class _BodyCanvasScreenState extends ConsumerState<BodyCanvasScreen> {
  DrawingCanvasController? _canvasController;
  CanvasTool _selectedTool = CanvasTool.pencil;
  Color _selectedDrawColor = const Color(0xFF2C2420);
  Uint8List? _existingBodyBytes;

  // Configuración de Ojos y Boca
  late RelativePoint _leftEyePos;
  late RelativePoint _rightEyePos;
  late RelativePoint _mouthPos;
  late Color _selectedEyeColor;
  late bool _hasEyelashes;

  bool _isExporting = false;
  bool _isWaitingClothes = false;

  final List<Color> _paletteColors = GarabuTheme.canvasPalette;

  final List<Color> _eyePaletteColors = const [
    Color(0xFF2C2420), // Carbón / Negro suave
    Color(0xFF5D4037), // Avellana
    Color(0xFF3E505B), // Azul pizarra
    Color(0xFF4A6B5B), // Verde esmeralda suave
    Color(0xFF9C4A6B), // Rosa mora
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingPet != null) {
      final config = widget.existingPet!.eyesConfig;
      _leftEyePos = config.leftEye;
      _rightEyePos = config.rightEye;
      _mouthPos = config.resolvedMouth;
      _selectedEyeColor = Color(config.color);
      _hasEyelashes = config.hasEyelashes;

      // Cargar los bytes del cuerpo actual para montarlo en la capa del lienzo
      final raw = widget.existingPet!.bodyImageUrl;
      if (raw.contains('base64,')) {
        try {
          final clean = raw.split('base64,').last.replaceAll(RegExp(r'\s+'), '');
          _existingBodyBytes = base64Decode(clean);
        } catch (_) {}
      }
    } else {
      _leftEyePos = const RelativePoint(x: 0.38, y: 0.42);
      _rightEyePos = const RelativePoint(x: 0.62, y: 0.42);
      _mouthPos = const RelativePoint(x: 0.50, y: 0.50);
      _selectedEyeColor = const Color(0xFF2C2420);
      _hasEyelashes = false;
    }
  }

  Future<void> _finishBody() async {
    if (_canvasController == null || _isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      // 1. Exportar el lienzo como PNG con transparencia
      final pngBytes = await _canvasController!.exportTransparentPng();
      if (pngBytes == null) {
        throw Exception('No se pudo generar la imagen del cuerpo.');
      }

      final eyesConfig = EyesConfig(
        leftEye: _leftEyePos,
        rightEye: _rightEyePos,
        mouth: _mouthPos,
        color: _selectedEyeColor.toARGB32(),
        hasEyelashes: _hasEyelashes,
      );

      final petRepo = ref.read(petRepositoryProvider);

      if (widget.existingPet != null) {
        // Modo Edición: Actualizar mascota existente
        await petRepo.updatePetBody(
          petId: widget.existingPet!.id,
          coupleId: widget.couple.id,
          bodyBytes: pngBytes,
          eyesConfig: eyesConfig,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('¡Cuerpo y carita actualizados!')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // 2. Modo Creación: Subir a Storage y crear registro en Firestore
      final pet = await petRepo.createPet(
        coupleId: widget.couple.id,
        name: widget.petName,
        bodyBytes: pngBytes,
        eyesConfig: eyesConfig,
      );

      final lobbyRepo = ref.read(lobbyRepositoryProvider);

      // Si ya existía el Slot 1, este personaje nuevo se asigna al Slot 2
      if (widget.couple.resolvedUser1PetId != null) {
        await lobbyRepo.assignPetToSlot(
          coupleId: widget.couple.id,
          slotNumber: 2,
          petId: pet.id,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('¡Personaje ${widget.petName} creado para el Slot 2!')),
          );
          Navigator.of(context).pop();
        }
        return;
      }

      // 3. Flujo inicial de Onboarding: Notificar en Firestore que el cuerpo está listo y le toca a Usuario 2
      await lobbyRepo.updateCoupleStatus(
        widget.couple.id,
        'drawing_clothes',
        petId: pet.id,
      );

      setState(() {
        _isWaitingClothes = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si ya terminamos el cuerpo, escuchamos cuando el Usuario 2 termine las prendas
    if (_isWaitingClothes) {
      ref.listen<AsyncValue<CoupleModel?>>(
        currentCoupleProvider(widget.couple.id),
        (previous, next) {
          final updated = next.value;
          if (updated != null && updated.status == 'ready' && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => DashboardScreen(couple: updated),
              ),
            );
          }
        },
      );

      return Scaffold(
        backgroundColor: GarabuTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: GarabuTheme.primaryBrown,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  '¡Cuerpo de ${widget.petName} guardado!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: GarabuTheme.deepEspresso,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Esperando a que ${widget.couple.user2Name ?? 'tu pareja'} le diseñe su primera prenda...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: GarabuTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final size = MediaQuery.of(context).size;
    final availableHeight = size.height - 290.0;
    final availableWidth = size.width - 32.0;
    final canvasDimension = min(availableHeight, availableWidth).clamp(220.0, 440.0);
    final canvasSize = Size(canvasDimension, canvasDimension);

    return Scaffold(
      backgroundColor: GarabuTheme.background,
      appBar: AppBar(
        title: Text(widget.petName),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _isExporting ? null : _finishBody,
              icon: _isExporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: GarabuTheme.primaryBrown),
                    )
                  : const Icon(Icons.check_circle_outline, color: GarabuTheme.primaryBrown),
              label: const Text(
                'Terminar',
                style: TextStyle(
                  color: GarabuTheme.primaryBrown,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Instrucción requerida
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: GarabuTheme.paperWhite,
              child: Text(
                widget.existingPet != null
                    ? 'Redibuja la forma de tu mascota o ajusta sus ojitos y boca'
                    : 'Dibuja a tu mascota de frente (solo el cuerpo, sin prendas)',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: GarabuTheme.deepEspresso,
                ),
              ),
            ),

            // Área central con Lienzo adaptado
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Contenedor del Lienzo con fondo de cuaderno y ojos/boca arrastrables
                        Container(
                          width: canvasSize.width,
                          height: canvasSize.height,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: DrawingCanvas(
                            canvasSize: canvasSize,
                            initialImageBytes: _existingBodyBytes,
                            onControllerReady: (c) {
                              _canvasController = c;
                              if (_existingBodyBytes != null) {
                                c.loadRasterImage(_existingBodyBytes!);
                              }
                            },
                            backgroundWidget: const NotebookBackground(),
                            overlayWidget: Stack(
                              children: [
                                // Ojo Izquierdo interactivo
                                DraggableEye(
                                  position: _leftEyePos,
                                  canvasSize: canvasSize,
                                  color: _selectedEyeColor,
                                  hasEyelashes: _hasEyelashes,
                                  isLeft: true,
                                  onPositionChanged: (pos) => setState(() => _leftEyePos = pos),
                                ),
                                // Ojo Derecho interactivo
                                DraggableEye(
                                  position: _rightEyePos,
                                  canvasSize: canvasSize,
                                  color: _selectedEyeColor,
                                  hasEyelashes: _hasEyelashes,
                                  isLeft: false,
                                  onPositionChanged: (pos) => setState(() => _rightEyePos = pos),
                                ),
                                // Boca interactiva
                                DraggableMouth(
                                  position: _mouthPos,
                                  canvasSize: canvasSize,
                                  onPositionChanged: (pos) => setState(() => _mouthPos = pos),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Instrucción para arrastrar ojos y boca
                        const Text(
                          'Arrastra los ojos y la boca para ubicarlos en el cuerpo',
                          style: TextStyle(
                            fontSize: 12,
                            color: GarabuTheme.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Panel de Herramientas y Controles
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fila de Herramientas (Lápiz, Balde, Deshacer, Limpiar)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildToolButton(
                        icon: Icons.edit_rounded,
                        label: 'Lápiz',
                        isSelected: _selectedTool == CanvasTool.pencil,
                        onTap: () {
                          setState(() => _selectedTool = CanvasTool.pencil);
                          _canvasController?.setTool(CanvasTool.pencil);
                        },
                      ),
                      _buildToolButton(
                        icon: Icons.format_color_fill_rounded,
                        label: 'Balde',
                        isSelected: _selectedTool == CanvasTool.bucket,
                        onTap: () {
                          setState(() => _selectedTool = CanvasTool.bucket);
                          _canvasController?.setTool(CanvasTool.bucket);
                        },
                      ),
                      _buildToolButton(
                        icon: Icons.undo_rounded,
                        label: 'Deshacer',
                        isSelected: false,
                        onTap: () => _canvasController?.undo(),
                      ),
                      _buildToolButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Limpiar',
                        isSelected: false,
                        onTap: () => _canvasController?.clear(),
                      ),
                    ],
                  ),
                  const Divider(height: 16, color: GarabuTheme.warmSand),

                  // Paleta de Colores de Trazo y Relleno
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _paletteColors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final color = _paletteColors[index];
                        final isSelected = _selectedDrawColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedDrawColor = color);
                            _canvasController?.setColor(color);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? GarabuTheme.primaryBrown
                                    : GarabuTheme.warmSand,
                                width: isSelected ? 2.5 : 1.2,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Fila de Controles de Ojos (Color y Switch de Pestañas)
                  Row(
                    children: [
                      const Text(
                        'Ojos:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: GarabuTheme.deepEspresso,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Mini selector de color de ojos
                      ..._eyePaletteColors.map((c) {
                        final isSelected = _selectedEyeColor == c;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedEyeColor = c),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.black : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      const Spacer(),
                      // Switch de Pestañas
                      const Text(
                        'Pestañas',
                        style: TextStyle(fontSize: 13, color: GarabuTheme.textSecondary),
                      ),
                      Transform.scale(
                        scale: 0.8,
                        child: Switch(
                          value: _hasEyelashes,
                          activeThumbColor: GarabuTheme.primaryBrown,
                          onChanged: (val) => setState(() => _hasEyelashes = val),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? GarabuTheme.warmSand.withValues(alpha: 0.5) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: GarabuTheme.primaryBrown) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? GarabuTheme.primaryBrown : GarabuTheme.deepEspresso,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
