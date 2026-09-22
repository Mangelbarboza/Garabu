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

class ClosetBottomSheet extends ConsumerWidget {
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

  Widget _buildGarmentThumbnail(String imageUrl) {
    return GarabuImage(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
    );
  }

  void _showAdjustPositionDialog(
    BuildContext context,
    WidgetRef ref,
    PetModel pet,
    GarmentItem garment,
  ) {
    double offsetX = garment.offsetX;
    double offsetY = garment.offsetY;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: GarabuTheme.cardSurface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.open_with_rounded, color: GarabuTheme.primaryBrown),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ajustar "${garment.name}"',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: GarabuTheme.deepEspresso,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Arrastra la prenda o usa las flechas para calzarla exactamente sobre el cuerpo:',
                    style: TextStyle(fontSize: 12.5, color: GarabuTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Lienzo de Previsualización y Arrastre
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      color: GarabuTheme.paperWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GarabuTheme.warmSand, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        const NotebookBackground(),
                        // Silueta base del personaje
                        Opacity(
                          opacity: 0.65,
                          child: GarabuImage(
                            imageUrl: pet.bodyImageUrl,
                            width: 220,
                            height: 220,
                            fit: BoxFit.contain,
                          ),
                        ),
                        // Prenda ajustable
                        Center(
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setDialogState(() {
                                offsetX = (offsetX + details.delta.dx).clamp(-120.0, 120.0);
                                offsetY = (offsetY + details.delta.dy).clamp(-140.0, 140.0);
                              });
                            },
                            child: Transform.translate(
                              offset: Offset(offsetX, offsetY),
                              child: Container(
                                width: 150,
                                height: 150,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: GarabuTheme.primaryBrown.withValues(alpha: 0.4),
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _buildGarmentThumbnail(garment.imageUrl),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Controles finos de flechas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_upward_rounded),
                        onPressed: () => setDialogState(() => offsetY = (offsetY - 3).clamp(-140.0, 140.0)),
                        tooltip: 'Subir',
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward_rounded),
                        onPressed: () => setDialogState(() => offsetY = (offsetY + 3).clamp(-140.0, 140.0)),
                        tooltip: 'Bajar',
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => setDialogState(() => offsetX = (offsetX - 3).clamp(-120.0, 120.0)),
                        tooltip: 'Izquierda',
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded),
                        onPressed: () => setDialogState(() => offsetX = (offsetX + 3).clamp(-120.0, 120.0)),
                        tooltip: 'Derecha',
                      ),
                      TextButton(
                        onPressed: () => setDialogState(() {
                          offsetX = 0;
                          offsetY = 0;
                        }),
                        child: const Text('Centrar', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                  Text(
                    'Posición actual: X: ${offsetX.round()}, Y: ${offsetY.round()}',
                    style: const TextStyle(fontSize: 11, color: GarabuTheme.textSecondary),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: GarabuTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.of(ctx).pop();
                    await ref.read(petRepositoryProvider).updateGarmentOffset(
                          petId: pet.id,
                          garmentId: garment.id,
                          offsetX: offsetX,
                          offsetY: offsetY,
                        );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('¡Posición de "${garment.name}" guardada!'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GarabuTheme.primaryBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _toggleGarmentEquip(BuildContext context, WidgetRef ref, String garmentId) async {
    final currentEquipped = List<String>.from(pet.resolvedEquippedGarmentIds);

    if (currentEquipped.contains(garmentId)) {
      // Quitar prenda
      currentEquipped.remove(garmentId);
    } else {
      // Equipar hasta 5 prendas
      if (currentEquipped.length >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Ya tienes 5 prendas equipadas! Quita una primero para poner otra.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      currentEquipped.add(garmentId);
    }

    final petRepo = ref.read(petRepositoryProvider);
    await petRepo.updateEquippedGarments(petId: pet.id, garmentIds: currentEquipped);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closet = pet.closet;
    final equippedIds = pet.resolvedEquippedGarmentIds;

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

          // Encabezado del Clóset (Estilo Alacena)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Clóset de ${pet.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Equipadas: ${equippedIds.length}/5 prendas',
                    style: const TextStyle(
                      fontSize: 13,
                      color: GarabuTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.storefront_rounded, color: GarabuTheme.primaryBrown),
                    tooltip: 'Tienda de Ropa',
                    onPressed: () {
                      Navigator.of(context).pop();
                      ShopBottomSheet.show(context: context, pet: pet);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: GarabuTheme.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Cuadrícula en cajoncitos (4 columnas, igual a la Alacena)
          if (closet.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: GarabuTheme.paperWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GarabuTheme.warmSand.withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.checkroom_rounded,
                    size: 44,
                    color: GarabuTheme.warmSand,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tu clóset está vacío',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dibuja una prenda o compra en la Tienda con tus Monedas Garabu.',
                    textAlign: TextAlign.center,
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
                                couple: couple,
                                pet: pet,
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
                          ShopBottomSheet.show(context: context, pet: pet);
                        },
                        icon: const Icon(Icons.storefront_rounded, size: 18),
                        label: const Text('Tienda'),
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
            ),
          ] else ...[
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: closet.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
                itemBuilder: (context, index) {
                  final garment = closet[index];
                  final isEquipped = equippedIds.contains(garment.id);
                  final equipIndex = equippedIds.indexOf(garment.id);

                  return InkWell(
                    onTap: () => _toggleGarmentEquip(context, ref, garment.id),
                    onLongPress: () => _showAdjustPositionDialog(context, ref, pet, garment),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isEquipped ? const Color(0xFFFFF8E1) : GarabuTheme.paperWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isEquipped ? GarabuTheme.primaryBrown : GarabuTheme.warmSand,
                          width: isEquipped ? 2.0 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isEquipped ? 0.08 : 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Stack(
                        children: [
                          // Botón de ajuste de posición en la esquina superior izquierda
                          Positioned(
                            top: 0,
                            left: 0,
                            child: GestureDetector(
                              onTap: () => _showAdjustPositionDialog(context, ref, pet, garment),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: GarabuTheme.warmSand, width: 0.8),
                                ),
                                child: const Icon(
                                  Icons.tune_rounded,
                                  size: 13,
                                  color: GarabuTheme.primaryBrown,
                                ),
                              ),
                            ),
                          ),

                          // Insignia de "Puesta" en la esquina superior derecha
                          if (isEquipped)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: BoxDecoration(
                                  color: GarabuTheme.primaryBrown,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '#${equipIndex + 1}',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),

                          // Contenido: Miniatura centrada y nombre abajo
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 6),
                              Expanded(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(2.0),
                                    child: _buildGarmentThumbnail(garment.imageUrl),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                garment.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isEquipped ? FontWeight.bold : FontWeight.w600,
                                  color: isEquipped ? GarabuTheme.deepEspresso : GarabuTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Botones de acción inferiores
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ClothesCanvasScreen(
                          couple: couple,
                          pet: pet,
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
                    padding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    ShopBottomSheet.show(context: context, pet: pet);
                  },
                  icon: const Icon(Icons.storefront_rounded, size: 17),
                  label: const Text('Tienda de Ropa', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GarabuTheme.primaryBrown,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 11),
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
