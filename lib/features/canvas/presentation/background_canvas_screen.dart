import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/garabu_theme.dart';
import '../../../core/widgets/notebook_background.dart';
import '../../pet/data/pet_repository.dart';
import '../../pet/domain/pet_model.dart';
import 'widgets/drawing_canvas.dart';

class BackgroundCanvasScreen extends ConsumerStatefulWidget {
  final PetModel pet;

  const BackgroundCanvasScreen({
    super.key,
    required this.pet,
  });

  @override
  ConsumerState<BackgroundCanvasScreen> createState() => _BackgroundCanvasScreenState();
}

class _BackgroundCanvasScreenState extends ConsumerState<BackgroundCanvasScreen> {
  DrawingCanvasController? _canvasController;
  CanvasTool _selectedTool = CanvasTool.pencil;
  Color _selectedDrawColor = const Color(0xFFC19A6B);
  bool _isExporting = false;

  final List<Color> _paletteColors = GarabuTheme.canvasPalette;

  Future<void> _saveBackground() async {
    if (_canvasController == null || _isExporting) return;

    setState(() => _isExporting = true);

    try {
      final bgBytes = await _canvasController!.exportTransparentPng();
      if (bgBytes == null) {
        throw Exception('No se pudo generar el fondo.');
      }

      final petRepo = ref.read(petRepositoryProvider);
      await petRepo.updateBackground(
        petId: widget.pet.id,
        coupleId: widget.pet.coupleId,
        backgroundBytes: bgBytes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Fondo actualizado con éxito!'),
            backgroundColor: GarabuTheme.primaryBrown,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar fondo: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _resetToNotebook() async {
    final petRepo = ref.read(petRepositoryProvider);
    await petRepo.updateBackground(
      petId: widget.pet.id,
      coupleId: widget.pet.coupleId,
      backgroundBytes: null,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Restaurado al fondo clásico de cuaderno'),
          backgroundColor: GarabuTheme.primaryBrown,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final availableHeight = size.height - 280.0;
    final availableWidth = size.width - 32.0;
    final canvasDimension = min(availableHeight, availableWidth).clamp(220.0, 440.0);
    final canvasSize = Size(canvasDimension, canvasDimension);

    return Scaffold(
      backgroundColor: GarabuTheme.background,
      appBar: AppBar(
        title: const Text('Dibuja un Fondo'),
        actions: [
          IconButton(
            tooltip: 'Usar fondo clásico',
            icon: const Icon(Icons.restart_alt_rounded, color: GarabuTheme.textSecondary),
            onPressed: _resetToNotebook,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon(
              onPressed: _isExporting ? null : _saveBackground,
              icon: _isExporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: GarabuTheme.primaryBrown),
                    )
                  : const Icon(Icons.check_circle_outline, color: GarabuTheme.primaryBrown),
              label: const Text(
                'Guardar',
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
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: GarabuTheme.paperWhite,
              child: const Text(
                'Dibuja una habitación, paisaje o decoración que se verá detrás de su mascota',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: GarabuTheme.deepEspresso,
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Container(
                      width: canvasSize.width,
                      height: canvasSize.height,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: GarabuTheme.warmSand, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: DrawingCanvas(
                        canvasSize: canvasSize,
                        onControllerReady: (c) {
                          _canvasController = c;
                          _canvasController?.setColor(_selectedDrawColor);
                        },
                        backgroundWidget: const NotebookBackground(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                        label: 'Relleno',
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
                  const Divider(height: 14, color: GarabuTheme.warmSand),
                  SizedBox(
                    height: 38,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
