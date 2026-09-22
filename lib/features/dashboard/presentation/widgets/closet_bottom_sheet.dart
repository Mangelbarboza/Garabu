import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../../core/widgets/garabu_image.dart';
import '../../../../core/widgets/notebook_background.dart';
import '../../../canvas/presentation/clothes_canvas_screen.dart';
import '../../../lobby/domain/couple_model.dart';
import '../../../pet/data/pet_repository.dart';
import '../../../pet/domain/pet_model.dart';
import 'shop_bottom_sheet.dart';

class ClosetBottomSheet extends ConsumerStatefulWidget {
  final CoupleModel couple;
  final PetModel pet;

  const ClosetBottomSheet({
    super.key,
    required this.couple,
    required this.pet,
  });

  static void show(BuildContext context, CoupleModel couple, PetModel pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ClosetBottomSheet(couple: couple, pet: pet),
    );
  }

  @override
  ConsumerState<ClosetBottomSheet> createState() => _ClosetBottomSheetState();
}

class _ClosetBottomSheetState extends ConsumerState<ClosetBottomSheet> {
  late List<String> _localEquippedIds;

  @override
  void initState() {
    super.initState();
    _localEquippedIds = List.from(widget.pet.resolvedEquippedGarmentIds);
  }

  Widget _buildGarmentThumbnail(String imageUrl) {
    return GarabuImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
    );
  }

  void _showAdjustPositionDialog(
    BuildContext context,
    PetModel pet,
    GarmentItem garment,
  ) {
    double offsetX = garment.offsetX;
    double offsetY = garment.offsetY;
    double scale = garment.scale;
    double rotation = garment.rotation; // radianes

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final degrees = (rotation * 180 / pi).round();

            return AlertDialog(
              backgroundColor: GarabuTheme.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 16, 8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              title: Row(
                children: [
                  const Icon(Icons.tune_rounded, color: GarabuTheme.primaryBrown, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ajustar "${garment.name}"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: GarabuTheme.deepEspresso,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Arrastra directamente sobre el personaje, cambia el tamaño y gíralo a tu gusto:',
                        style: TextStyle(fontSize: 12, color: GarabuTheme.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),

                      // Lienzo a escala 1:1 directa con el personaje
                      Center(
                        child: Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            color: GarabuTheme.paperWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: GarabuTheme.primaryBrown.withValues(alpha: 0.3), width: 1.8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanUpdate: (details) {
                              setDialogState(() {
                                offsetX = (offsetX + details.delta.dx).clamp(-180.0, 180.0);
                                offsetY = (offsetY + details.delta.dy).clamp(-180.0, 180.0);
                              });
                            },
                            child: Stack(
                              children: [
                                const NotebookBackground(),
                                // 1. Personaje real de fondo para calzar perfectamente
                                Opacity(
                                  opacity: 0.65,
                                  child: GarabuImage(
                                    imageUrl: pet.bodyImageUrl,
                                    width: 250,
                                    height: 250,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                // 2. Prenda con sus transformaciones en tiempo real
                                Transform.translate(
                                  offset: Offset(offsetX, offsetY),
                                  child: Transform.rotate(
                                    angle: rotation,
                                    child: Transform.scale(
                                      scale: scale,
                                      child: GarabuImage(
                                        imageUrl: garment.imageUrl,
                                        width: 250,
                                        height: 250,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                // Guía visual de arrastre
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.touch_app_rounded, color: Colors.white, size: 14),
                                        SizedBox(width: 4),
                                        Text('Arrastra', style: TextStyle(color: Colors.white, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Control 1: Tamaño / Escala
                      Row(
                        children: [
                          const Icon(Icons.photo_size_select_small_rounded, size: 18, color: GarabuTheme.primaryBrown),
                          const SizedBox(width: 6),
                          const Text('Tamaño:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso)),
                          const Spacer(),
                          Text('${(scale * 100).round()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GarabuTheme.primaryBrown)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                            onPressed: () => setDialogState(() => scale = (scale - 0.05).clamp(0.3, 3.0)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              ),
                              child: Slider(
                                value: scale,
                                min: 0.3,
                                max: 2.5,
                                activeColor: GarabuTheme.primaryBrown,
                                onChanged: (v) => setDialogState(() => scale = v),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                            onPressed: () => setDialogState(() => scale = (scale + 0.05).clamp(0.3, 3.0)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),

                      // Control 2: Rotación
                      Row(
                        children: [
                          const Icon(Icons.rotate_right_rounded, size: 18, color: GarabuTheme.primaryBrown),
                          const SizedBox(width: 6),
                          const Text('Rotación:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso)),
                          const Spacer(),
                          Text('$degrees°', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GarabuTheme.primaryBrown)),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.rotate_left_rounded, size: 20),
                            onPressed: () => setDialogState(() => rotation = (rotation - (10 * pi / 180))),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                              ),
                              child: Slider(
                                value: (degrees).clamp(-180, 180).toDouble(),
                                min: -180,
                                max: 180,
                                activeColor: const Color(0xFFE91E63),
                                onChanged: (v) => setDialogState(() => rotation = v * pi / 180),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.rotate_right_rounded, size: 20),
                            onPressed: () => setDialogState(() => rotation = (rotation + (10 * pi / 180))),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ],
                      ),

                      // Control 3: Flechas de posición fina y botón de restablecer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded, size: 18),
                            onPressed: () => setDialogState(() => offsetX = (offsetX - 2).clamp(-180.0, 180.0)),
                            tooltip: 'Izquierda',
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                            onPressed: () => setDialogState(() => offsetY = (offsetY - 2).clamp(-180.0, 180.0)),
                            tooltip: 'Subir',
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                            onPressed: () => setDialogState(() => offsetY = (offsetY + 2).clamp(-180.0, 180.0)),
                            tooltip: 'Bajar',
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                            onPressed: () => setDialogState(() => offsetX = (offsetX + 2).clamp(-180.0, 180.0)),
                            tooltip: 'Derecha',
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                offsetX = 0.0;
                                offsetY = 0.0;
                                scale = 1.0;
                                rotation = 0.0;
                              });
                            },
                            child: const Text('Reset', style: TextStyle(fontSize: 11, color: GarabuTheme.textSecondary)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: GarabuTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await ref.read(petRepositoryProvider).updateGarmentTransform(
                          petId: pet.id,
                          garmentId: garment.id,
                          offsetX: offsetX,
                          offsetY: offsetY,
                          scale: scale,
                          rotation: rotation,
                        );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GarabuTheme.primaryBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Guardar Ajuste'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleGarmentEquip(String garmentId) {
    setState(() {
      if (_localEquippedIds.contains(garmentId)) {
        // Quitar prenda
        _localEquippedIds.remove(garmentId);
      } else {
        // Equipar hasta 5 prendas
        if (_localEquippedIds.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Ya tienes 5 prendas equipadas! Quita una primero para poner otra.'),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        _localEquippedIds.add(garmentId);
      }
    });

    // Guardar en repositorio de inmediato en segundo plano
    ref.read(petRepositoryProvider).updateEquippedGarments(
          petId: widget.pet.id,
          garmentIds: _localEquippedIds,
        );
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios de la mascota (si añade o edita prendas en tiempo real)
    final petAsync = ref.watch(currentPetProvider(widget.pet.id));
    final livePet = petAsync.value ?? widget.pet;
    final closet = livePet.closet;

    return Container(
      decoration: const BoxDecoration(
        color: GarabuTheme.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barra de agarre
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: GarabuTheme.warmSand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Título y Contador
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GarabuTheme.primaryBrown.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.checkroom_rounded,
                      size: 22,
                      color: GarabuTheme.primaryBrown,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clóset de Garabu',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: GarabuTheme.deepEspresso,
                        ),
                      ),
                      Text(
                        'Equipadas: ${_localEquippedIds.length}/5 prendas',
                        style: const TextStyle(
                          fontSize: 12,
                          color: GarabuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: GarabuTheme.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Cuadrícula estilo Alacena de 4 columnas
          if (closet.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Column(
                children: [
                  const Icon(Icons.dry_cleaning_rounded, size: 48, color: GarabuTheme.warmSand),
                  const SizedBox(height: 8),
                  const Text(
                    'Tu clóset está vacío.',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '¡Dibuja una prenda o visita la tienda de ropa!',
                    style: TextStyle(fontSize: 12.5, color: GarabuTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ClothesCanvasScreen(
                                couple: widget.couple,
                                pet: livePet,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.brush_rounded, size: 18),
                        label: const Text('Dibujar Prenda'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GarabuTheme.primaryBrown,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          ShopBottomSheet.show(context: context, pet: livePet, initialTab: 1);
                        },
                        icon: const Icon(Icons.storefront_rounded, size: 18),
                        label: const Text('Comprar Ropa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GarabuTheme.primaryBrown,
                          side: const BorderSide(color: GarabuTheme.primaryBrown),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 330),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  childAspectRatio: 0.80,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: closet.length,
                itemBuilder: (context, index) {
                  final garment = closet[index];
                  final isEquipped = _localEquippedIds.contains(garment.id);
                  final equipOrder = _localEquippedIds.indexOf(garment.id) + 1;

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _toggleGarmentEquip(garment.id),
                    onLongPress: () => _showAdjustPositionDialog(context, livePet, garment),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: isEquipped
                            ? GarabuTheme.primaryBrown.withValues(alpha: 0.09)
                            : GarabuTheme.paperWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEquipped
                              ? GarabuTheme.primaryBrown
                              : GarabuTheme.warmSand.withValues(alpha: 0.8),
                          width: isEquipped ? 2.2 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Miniatura de la prenda centrada
                          Positioned(
                            top: 8,
                            bottom: 24,
                            left: 8,
                            right: 8,
                            child: _buildGarmentThumbnail(garment.imageUrl),
                          ),

                          // Etiqueta del nombre de la prenda abajo
                          Positioned(
                            bottom: 5,
                            left: 4,
                            right: 4,
                            child: Text(
                              garment.name,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isEquipped ? FontWeight.bold : FontWeight.w500,
                                color: isEquipped ? GarabuTheme.primaryBrown : GarabuTheme.deepEspresso,
                              ),
                            ),
                          ),

                          // Insignia de Orden de Equipamiento (#1, #2, #3, #4, #5)
                          if (isEquipped)
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: GarabuTheme.primaryBrown,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '#$equipOrder',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),

                          // Botón sutil de ajuste de posición
                          Positioned(
                            top: 3,
                            left: 3,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => _showAdjustPositionDialog(context, livePet, garment),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.08),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.tune_rounded,
                                    size: 13,
                                    color: GarabuTheme.primaryBrown,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),

          // Botones inferiores: Diseñar nueva prenda y Comprar en tienda
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClothesCanvasScreen(
                          couple: widget.couple,
                          pet: livePet,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.brush_rounded, size: 17),
                  label: const Text('Dibujar Prenda', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GarabuTheme.primaryBrown,
                    side: const BorderSide(color: GarabuTheme.primaryBrown, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ShopBottomSheet.show(context: context, pet: livePet, initialTab: 1);
                  },
                  icon: const Icon(Icons.shopping_bag_rounded, size: 17),
                  label: const Text('Comprar Ropa', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GarabuTheme.primaryBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
