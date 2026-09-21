import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/garabu_theme.dart';
import '../../../core/utils/flood_fill.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/notebook_background.dart';
import '../../../core/widgets/garabu_image.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../lobby/data/lobby_repository.dart';
import '../../lobby/domain/couple_model.dart';
import '../../pet/data/pet_repository.dart';
import '../../pet/domain/pet_model.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/canvas_toolbar.dart';
import 'widgets/eye_widget.dart';

class ClothesCanvasScreen extends ConsumerStatefulWidget {
  final CoupleModel couple;
  final PetModel? pet;
  final String? editingGarmentId;
  final String? initialGarmentName;

  const ClothesCanvasScreen({
    super.key,
    required this.couple,
    this.pet,
    this.editingGarmentId,
    this.initialGarmentName,
  });

  @override
  ConsumerState<ClothesCanvasScreen> createState() => _ClothesCanvasScreenState();
}

class _ClothesCanvasScreenState extends ConsumerState<ClothesCanvasScreen> {
  DrawingCanvasController? _canvasController;
  CanvasTool _selectedTool = CanvasTool.pencil;
  Color _selectedDrawColor = const Color(0xFF2C2420);
  double _selectedStrokeWidth = 4.0;
  BucketPower _selectedBucketPower = BucketPower.medium;
  Uint8List? _existingGarmentBytes;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    if (widget.editingGarmentId != null && widget.pet != null) {
      final garment = widget.pet!.closet.cast<GarmentItem?>().firstWhere(
            (g) => g?.id == widget.editingGarmentId,
            orElse: () => null,
          );
      if (garment != null && garment.imageUrl.isNotEmpty) {
        _existingGarmentBytes = decodeDataUri(garment.imageUrl);
      }
    }
  }

  Future<String?> _promptGarmentName(BuildContext context, int defaultIndex) async {
    final controller = TextEditingController(
      text: widget.initialGarmentName ?? 'Prenda #$defaultIndex',
    );
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: GarabuTheme.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          widget.editingGarmentId != null ? 'Editar Prenda 👗' : 'Nueva Prenda 👗',
          style: const TextStyle(color: GarabuTheme.deepEspresso, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nombra tu creación:', style: TextStyle(color: GarabuTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Ej. Sombrero, Bufanda...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar', style: TextStyle(color: GarabuTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  Future<void> _finishClothes(PetModel pet) async {
    if (_canvasController == null || _isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      // Exportar solo la prenda como PNG con transparencia
      final clothesBytes = await _canvasController!.exportTransparentPng();
      if (clothesBytes == null) {
        throw Exception('No se pudo generar la imagen de la prenda.');
      }

      final petRepo = ref.read(petRepositoryProvider);

      // Si viene desde el clóset (pareja ya en estado 'ready', editando o con pet suministrado)
      if (widget.couple.status == 'ready' ||
          widget.editingGarmentId != null ||
          widget.pet != null) {
        if (!mounted) return;
        final name = await _promptGarmentName(context, pet.closet.length + 1);
        if (name == null || name.isEmpty) {
          if (mounted) setState(() => _isExporting = false);
          return;
        }

        if (widget.editingGarmentId != null) {
          await petRepo.updateGarment(
            petId: pet.id,
            coupleId: widget.couple.id,
            garmentId: widget.editingGarmentId!,
            clothesBytes: clothesBytes,
            newName: name,
          );
        } else {
          await petRepo.addGarment(
            petId: pet.id,
            coupleId: widget.couple.id,
            clothesBytes: clothesBytes,
            name: name,
          );
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
        return;
      }

      // Flujo inicial de emparejamiento
      await petRepo.updateClothes(
        petId: pet.id,
        coupleId: widget.couple.id,
        clothesBytes: clothesBytes,
      );

      final lobbyRepo = ref.read(lobbyRepositoryProvider);
      await lobbyRepo.updateCoupleStatus(widget.couple.id, 'ready');

      if (mounted) {
        // Redirigir al Dashboard Principal
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DashboardScreen(couple: widget.couple),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar prenda: $e')),
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
    final coupleAsync = ref.watch(currentCoupleProvider(widget.couple.id));
    final currentCouple = coupleAsync.value ?? widget.couple;
    final petId = widget.pet?.id ?? currentCouple.petId;

    // Solo mostrar pantalla de espera si estamos en onboarding inicial (esperando a que se dibuje el cuerpo)
    final isWaitingForInitialBody = (currentCouple.status == 'waiting_partner' ||
            currentCouple.status == 'drawing_body') &&
        widget.pet == null &&
        widget.editingGarmentId == null;

    if (isWaitingForInitialBody || petId == null) {
      return Scaffold(
        backgroundColor: GarabuTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: GarabuTheme.primaryBrown,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Esperando a que ${currentCouple.user1Name} dibuje el cuerpo...',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: GarabuTheme.deepEspresso,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Cuando termine, tu lienzo se abrirá automáticamente para diseñarle su primera ropita.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: GarabuTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final petAsync = ref.watch(currentPetProvider(petId));
    return petAsync.when(
      loading: () => const Scaffold(
        backgroundColor: GarabuTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: GarabuTheme.primaryBrown),
        ),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (pet) {
        if (pet == null) {
          return const Scaffold(
            body: Center(child: Text('Cargando mascota...')),
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
            title: Text('Viste a ${pet.name}'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: TextButton.icon(
                  onPressed: _isExporting ? null : () => _finishClothes(pet),
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
                    widget.editingGarmentId != null
                        ? 'Edita la prenda de ${pet.name}'
                        : (widget.couple.status == 'ready' || widget.pet != null || currentCouple.status == 'ready'
                            ? 'Diseña una nueva prenda para el clóset de ${pet.name}'
                            : 'Dibuja UNA prenda para ${pet.name}'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                ),

                // Canvas con cuerpo y ojos fijados en el fondo (NO editables y totalmente inmóviles)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Container(
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
                            initialImageBytes: _existingGarmentBytes,
                            onControllerReady: (c) {
                              _canvasController = c;
                              if (_existingGarmentBytes != null) {
                                c.loadRasterImage(_existingGarmentBytes!);
                              }
                            },
                            onColorPicked: (color) {
                              setState(() => _selectedDrawColor = color);
                            },
                            backgroundWidget: Stack(
                              children: [
                                // 1. Hoja de cuaderno
                                const NotebookBackground(),

                                // 2. Silueta de fondo estática a opacidad óptima (Maniquí para calcar)
                                Opacity(
                                  opacity: 0.38,
                                  child: Stack(
                                    children: [
                                      GarabuImage(
                                        imageUrl: pet.bodyImageUrl,
                                        width: canvasSize.width,
                                        height: canvasSize.height,
                                        fit: BoxFit.contain,
                                      ),
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
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Barra de herramientas completa con gotero, balde débil/medio/fuerte y 5 puntas
                CanvasToolbar(
                  selectedTool: _selectedTool,
                  selectedColor: _selectedDrawColor,
                  selectedStrokeWidth: _selectedStrokeWidth,
                  selectedBucketPower: _selectedBucketPower,
                  onToolChanged: (tool) {
                    setState(() => _selectedTool = tool);
                    _canvasController?.setTool(tool);
                  },
                  onColorChanged: (color) {
                    setState(() => _selectedDrawColor = color);
                    _canvasController?.setColor(color);
                  },
                  onStrokeWidthChanged: (width) {
                    setState(() => _selectedStrokeWidth = width);
                    _canvasController?.setStrokeWidth(width);
                  },
                  onBucketPowerChanged: (power) {
                    setState(() => _selectedBucketPower = power);
                    _canvasController?.setBucketPower(power);
                  },
                  onUndo: () => _canvasController?.undo(),
                  onClear: () => _canvasController?.clear(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
