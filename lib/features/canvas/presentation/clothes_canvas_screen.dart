import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/garabu_theme.dart';
import '../../../core/widgets/notebook_background.dart';
import '../../../core/widgets/garabu_image.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../lobby/data/lobby_repository.dart';
import '../../lobby/domain/couple_model.dart';
import '../../pet/data/pet_repository.dart';
import '../../pet/domain/pet_model.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/eye_widget.dart';

class ClothesCanvasScreen extends ConsumerStatefulWidget {
  final CoupleModel couple;
  final String? editingGarmentId;
  final String? initialGarmentName;

  const ClothesCanvasScreen({
    super.key,
    required this.couple,
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
  bool _isExporting = false;

  final List<Color> _paletteColors = GarabuTheme.canvasPalette;

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

      // Si viene desde el clóset (pareja ya en estado 'ready' o editando)
      if (widget.couple.status == 'ready' || widget.editingGarmentId != null) {
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

    // Si aún no está listo el cuerpo, mostrar pantalla de espera requerida
    if (currentCouple.status != 'drawing_clothes' || currentCouple.petId == null) {
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

    final petAsync = ref.watch(currentPetProvider(currentCouple.petId!));
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
                        : (widget.couple.status == 'ready'
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

                // Canvas con cuerpo y ojos fijados en el fondo (NO editables)
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
                            onControllerReady: (c) => _canvasController = c,
                            backgroundWidget: Stack(
                              children: [
                                // 1. Hoja de cuaderno
                                const NotebookBackground(),

                                // 2. Silueta de fondo a baja opacidad (Maniquí para calcar y ajustar la prenda)
                                Opacity(
                                  opacity: 0.30,
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

                // Barra de Herramientas para Usuario 2 (Lápiz, Balde, Deshacer, Limpiar)
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

                      // Paleta de Colores
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
