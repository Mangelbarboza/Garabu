import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/garabu_theme.dart';
import '../../../core/utils/flood_fill.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/widgets/notebook_background.dart';
import '../../dashboard/presentation/widgets/shop_bottom_sheet.dart' show kCatalogBackgrounds;
import '../../pet/data/pet_repository.dart';
import '../../pet/domain/pet_model.dart';
import 'widgets/drawing_canvas.dart';
import 'widgets/canvas_toolbar.dart';

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
  double _selectedStrokeWidth = 4.0;
  BucketPower _selectedBucketPower = BucketPower.medium;
  int _selectedSlot = 0;
  Uint8List? _initialSlotBytes;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _selectedSlot = widget.pet.activeBackgroundSlotIndex.clamp(0, 2);
    _loadBytesForSlot(_selectedSlot);
  }

  Future<void> _loadBytesForSlot(int slotIndex) async {
    String? url;
    if (slotIndex < widget.pet.backgroundSlots.length) {
      url = widget.pet.backgroundSlots[slotIndex];
    }
    url ??= (slotIndex == 0 ? widget.pet.backgroundUrl : null);

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('assets/')) {
        try {
          final data = await rootBundle.load(url);
          _initialSlotBytes = data.buffer.asUint8List();
        } catch (_) {
          _initialSlotBytes = null;
        }
      } else {
        _initialSlotBytes = decodeDataUri(url);
      }
    } else {
      _initialSlotBytes = null;
    }
  }

  Future<void> _onSwitchSlot(int slotIndex) async {
    if (_selectedSlot == slotIndex) return;
    setState(() => _selectedSlot = slotIndex);
    await _loadBytesForSlot(slotIndex);
    if (mounted) {
      if (_initialSlotBytes != null) {
        _canvasController?.loadRasterImage(_initialSlotBytes!);
      } else {
        _canvasController?.clear();
      }
    }
  }

  Future<void> _showTemplatePicker() async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GarabuTheme.paperWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Cargar Boceto Base',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: GarabuTheme.deepEspresso,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: kCatalogBackgrounds.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final bg = kCatalogBackgrounds[i];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(bg.assetPath, width: 44, height: 44, fit: BoxFit.cover),
                ),
                title: Text(bg.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(bg.description, style: const TextStyle(fontSize: 11)),
                onTap: () => Navigator.of(ctx).pop(bg.assetPath),
              );
            },
          ),
        ),
      ),
    );

    if (chosen != null) {
      try {
        final data = await rootBundle.load(chosen);
        final bytes = data.buffer.asUint8List();
        _canvasController?.loadRasterImage(bytes);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Boceto cargado en el lienzo! Ahora puedes colorearlo o personalizarlo.'),
              backgroundColor: GarabuTheme.primaryBrown,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al cargar boceto: $e')),
          );
        }
      }
    }
  }

  Future<void> _saveBackground() async {
    if (_canvasController == null || _isExporting) return;

    setState(() => _isExporting = true);

    try {
      final bgBytes = await _canvasController!.exportTransparentPng();
      if (bgBytes == null) {
        throw Exception('No se pudo generar el fondo.');
      }

      final petRepo = ref.read(petRepositoryProvider);
      await petRepo.updateBackgroundSlot(
        petId: widget.pet.id,
        coupleId: widget.pet.coupleId,
        slotIndex: _selectedSlot,
        backgroundBytes: bgBytes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Fondo guardado en Slot #${_selectedSlot + 1} con éxito!'),
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
    await petRepo.updateBackgroundSlot(
      petId: widget.pet.id,
      coupleId: widget.pet.coupleId,
      slotIndex: _selectedSlot,
      backgroundBytes: null,
    );
    _canvasController?.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Slot #${_selectedSlot + 1} restaurado a cuaderno'),
          backgroundColor: GarabuTheme.primaryBrown,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final availableHeight = size.height - 300.0;
    final availableWidth = size.width - 32.0;
    final canvasDimension = min(availableHeight, availableWidth).clamp(220.0, 440.0);
    final canvasSize = Size(canvasDimension, canvasDimension);

    return Scaffold(
      backgroundColor: GarabuTheme.background,
      appBar: AppBar(
        title: const Text('Fondos (3 Slots)'),
        actions: [
          IconButton(
            tooltip: 'Cargar boceto base',
            icon: const Icon(Icons.collections_bookmark_rounded, color: GarabuTheme.primaryBrown),
            onPressed: _showTemplatePicker,
          ),
          IconButton(
            tooltip: 'Restaurar slot a cuaderno blanco',
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
            // Selector de los 3 Slots de Fondo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: GarabuTheme.paperWhite,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Slot de Fondo:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                  const SizedBox(width: 12),
                  for (int i = 0; i < 3; i++) ...[
                    GestureDetector(
                      onTap: () => _onSwitchSlot(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: _selectedSlot == i
                              ? GarabuTheme.primaryBrown
                              : GarabuTheme.warmSand.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedSlot == i
                                ? GarabuTheme.primaryBrown
                                : GarabuTheme.warmSand,
                          ),
                        ),
                        child: Text(
                          'Slot ${i + 1}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _selectedSlot == i ? Colors.white : GarabuTheme.deepEspresso,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Canvas de Fondo
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
                        initialImageBytes: _initialSlotBytes,
                        onControllerReady: (c) {
                          _canvasController = c;
                          if (_initialSlotBytes != null) {
                            c.loadRasterImage(_initialSlotBytes!);
                          }
                          _canvasController?.setColor(_selectedDrawColor);
                        },
                        onColorPicked: (color) {
                          setState(() => _selectedDrawColor = color);
                        },
                        backgroundWidget: const NotebookBackground(),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Barra de herramientas completa
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
  }
}
