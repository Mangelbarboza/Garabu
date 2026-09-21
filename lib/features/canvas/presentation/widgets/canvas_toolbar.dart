import 'package:flutter/material.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../../core/utils/flood_fill.dart';
import 'drawing_canvas.dart';

class CanvasToolbar extends StatefulWidget {
  final CanvasTool selectedTool;
  final Color selectedColor;
  final double selectedStrokeWidth;
  final BucketPower selectedBucketPower;
  final ValueChanged<CanvasTool> onToolChanged;
  final ValueChanged<Color> onColorChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final ValueChanged<BucketPower> onBucketPowerChanged;
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final Widget? extraControls; // Por ejemplo controles de ojos en BodyCanvas

  const CanvasToolbar({
    super.key,
    required this.selectedTool,
    required this.selectedColor,
    required this.selectedStrokeWidth,
    required this.selectedBucketPower,
    required this.onToolChanged,
    required this.onColorChanged,
    required this.onStrokeWidthChanged,
    required this.onBucketPowerChanged,
    required this.onUndo,
    required this.onClear,
    this.extraControls,
  });

  @override
  State<CanvasToolbar> createState() => _CanvasToolbarState();
}

class _CanvasToolbarState extends State<CanvasToolbar> {
  final List<Color> _palette = GarabuTheme.canvasPalette;

  // Paleta de espectro extendida para el selector libre
  static const List<Color> _extendedSpectrum = [
    Color(0xFF000000), Color(0xFF2C2420), Color(0xFF424242), Color(0xFF757575), Color(0xFFBDBDBD), Color(0xFFFFFFFF),
    Color(0xFFD32F2F), Color(0xFFE53935), Color(0xFFEF5350), Color(0xFFFFCDD2),
    Color(0xFFE64A19), Color(0xFFF4511E), Color(0xFFFF7043), Color(0xFFFFCCBC),
    Color(0xFFF57C00), Color(0xFFFB8C00), Color(0xFFFFB74D), Color(0xFFFFE0B2),
    Color(0xFFFBC02D), Color(0xFFFDD835), Color(0xFFFFF176), Color(0xFFFFF9C4),
    Color(0xFF388E3C), Color(0xFF43A047), Color(0xFF81C784), Color(0xFFC8E6C9),
    Color(0xFF00897B), Color(0xFF26A69A), Color(0xFF80CBC4), Color(0xFFE0F2F1),
    Color(0xFF0288D1), Color(0xFF03A9F4), Color(0xFF4FC3F7), Color(0xFFB3E5FC),
    Color(0xFF3949AB), Color(0xFF5C6BC0), Color(0xFF9FA8DA), Color(0xFFE8EAF6),
    Color(0xFF8E24AA), Color(0xFFAB47BC), Color(0xFFCE93D8), Color(0xFFF3E5F5),
    Color(0xFFD81B60), Color(0xFFEC407A), Color(0xFFF48FB1), Color(0xFFFCE4EC),
    Color(0xFF5D4037), Color(0xFF795548), Color(0xFFA1887F), Color(0xFFD7CCC8),
    Color(0xFFC19A6B), Color(0xFFEAD8C0), Color(0xFFFDFBF7), Color(0xFFFFF59D),
  ];

  void _openColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GarabuTheme.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.palette_rounded, color: GarabuTheme.primaryBrown),
            SizedBox(width: 8),
            Text(
              'Seleccionar Color',
              style: TextStyle(
                color: GarabuTheme.deepEspresso,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 320,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Elige cualquier tono de la paleta cromática libre:',
                style: TextStyle(fontSize: 12.5, color: GarabuTheme.textSecondary),
              ),
              const SizedBox(height: 14),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _extendedSpectrum.length,
                  itemBuilder: (context, i) {
                    final color = _extendedSpectrum[i];
                    final isSel = widget.selectedColor == color;
                    return GestureDetector(
                      onTap: () {
                        widget.onColorChanged(color);
                        Navigator.of(ctx).pop();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSel ? GarabuTheme.primaryBrown : GarabuTheme.warmSand,
                            width: isSel ? 3.0 : 1.2,
                          ),
                          boxShadow: isSel
                              ? [
                                  BoxShadow(
                                    color: GarabuTheme.primaryBrown.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cerrar', style: TextStyle(color: GarabuTheme.textSecondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Barra de Herramientas Principales
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildToolButton(
                icon: Icons.edit_rounded,
                label: 'Lápiz',
                isSelected: widget.selectedTool == CanvasTool.pencil,
                onTap: () => widget.onToolChanged(CanvasTool.pencil),
              ),
              _buildToolButton(
                icon: Icons.format_color_fill_rounded,
                label: 'Balde',
                isSelected: widget.selectedTool == CanvasTool.bucket,
                onTap: () => widget.onToolChanged(CanvasTool.bucket),
              ),
              _buildToolButton(
                icon: Icons.colorize_rounded,
                label: 'Gotero',
                isSelected: widget.selectedTool == CanvasTool.eyedropper,
                onTap: () => widget.onToolChanged(CanvasTool.eyedropper),
              ),
              _buildToolButton(
                icon: Icons.undo_rounded,
                label: 'Deshacer',
                isSelected: false,
                onTap: widget.onUndo,
              ),
              _buildToolButton(
                icon: Icons.delete_outline_rounded,
                label: 'Limpiar',
                isSelected: false,
                onTap: widget.onClear,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 2. Subpanel contextual según herramienta activa
          if (widget.selectedTool == CanvasTool.pencil) ...[
            // 5 Tamaños de Puntas de Lápiz
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Punta:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: GarabuTheme.deepEspresso,
                  ),
                ),
                const SizedBox(width: 10),
                ...kPencilStrokeWidths.map((width) {
                  final isSelected = widget.selectedStrokeWidth == width;
                  return GestureDetector(
                    onTap: () => widget.onStrokeWidthChanged(width),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? GarabuTheme.warmSand.withValues(alpha: 0.35)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? GarabuTheme.primaryBrown : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: (width * 0.85).clamp(4.0, 18.0),
                          height: (width * 0.85).clamp(4.0, 18.0),
                          decoration: BoxDecoration(
                            color: widget.selectedColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 6),
          ] else if (widget.selectedTool == CanvasTool.bucket) ...[
            // 3 Niveles del Balde (Débil, Medio, Fuerte)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Relleno:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: GarabuTheme.deepEspresso,
                  ),
                ),
                const SizedBox(width: 10),
                _buildPowerChip('Débil', BucketPower.weak),
                const SizedBox(width: 6),
                _buildPowerChip('Medio', BucketPower.medium),
                const SizedBox(width: 6),
                _buildPowerChip('Fuerte', BucketPower.strong),
              ],
            ),
            const SizedBox(height: 6),
          ] else if (widget.selectedTool == CanvasTool.eyedropper) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4.0),
              child: Text(
                'Toca cualquier parte del lienzo para copiar su color',
                style: TextStyle(
                  fontSize: 12,
                  color: GarabuTheme.primaryBrown,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          const Divider(height: 12, color: GarabuTheme.warmSand),

          // 3. Paleta de Colores de Trazo/Relleno + Botón de Selector Libre
          SizedBox(
            height: 38,
            child: Row(
              children: [
                // Botón de Selector de Color Libre (Espectro)
                GestureDetector(
                  onTap: () => _openColorPicker(context),
                  child: Container(
                    width: 34,
                    height: 34,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: const SweepGradient(
                        colors: [
                          Color(0xFFFF0000),
                          Color(0xFFFFFF00),
                          Color(0xFF00FF00),
                          Color(0xFF00FFFF),
                          Color(0xFF0000FF),
                          Color(0xFFFF00FF),
                          Color(0xFFFF0000),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: GarabuTheme.primaryBrown,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, size: 18, color: Colors.white),
                  ),
                ),

                // Lista horizontal de colores sugeridos
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _palette.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final color = _palette[index];
                      final isSelected = widget.selectedColor == color;
                      return GestureDetector(
                        onTap: () => widget.onColorChanged(color),
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
                              width: isSelected ? 2.6 : 1.2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: GarabuTheme.primaryBrown.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Controles extras (como ojos/boca si los hay)
          if (widget.extraControls != null) ...[
            const SizedBox(height: 8),
            widget.extraControls!,
          ],
        ],
      ),
    );
  }

  Widget _buildPowerChip(String label, BucketPower power) {
    final isSelected = widget.selectedBucketPower == power;
    return GestureDetector(
      onTap: () => widget.onBucketPowerChanged(power),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? GarabuTheme.primaryBrown : GarabuTheme.warmSand.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? GarabuTheme.primaryBrown : GarabuTheme.warmSand,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : GarabuTheme.deepEspresso,
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? GarabuTheme.warmSand.withValues(alpha: 0.4)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? GarabuTheme.primaryBrown : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
