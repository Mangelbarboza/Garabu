import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../canvas/presentation/clothes_canvas_screen.dart';
import '../../../lobby/domain/couple_model.dart';
import '../../../pet/data/pet_repository.dart';
import '../../../pet/domain/pet_model.dart';

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
    if (imageUrl.startsWith('data:image/png;base64,')) {
      final base64Data = imageUrl.replaceFirst('data:image/png;base64,', '');
      return Image.memory(
        base64Decode(base64Data),
        fit: BoxFit.contain,
      );
    } else {
      return Image.network(
        imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, color: GarabuTheme.textSecondary),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petRepo = ref.read(petRepositoryProvider);
    final closet = pet.closet;
    const maxSlots = 5;

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
          const SizedBox(height: 16),

          // Título y Contador de Slots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Clóset de Creaciones 👗',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Prendas compartidas para ${pet.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: GarabuTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: GarabuTheme.warmSand.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${closet.length}/$maxSlots slots',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: GarabuTheme.deepEspresso,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de los 5 slots
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: maxSlots,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final bool hasItem = index < closet.length;

                if (hasItem) {
                  final garment = closet[index];
                  final bool isEquipped = pet.activeGarmentId == garment.id;

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isEquipped ? GarabuTheme.paperWhite : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isEquipped ? GarabuTheme.primaryBrown : GarabuTheme.warmSand,
                        width: isEquipped ? 2.0 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Miniatura de la Prenda
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: GarabuTheme.paperWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: GarabuTheme.warmSand),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: _buildGarmentThumbnail(garment.imageUrl),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Información de la prenda
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    garment.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: GarabuTheme.deepEspresso,
                                    ),
                                  ),
                                  if (isEquipped) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: GarabuTheme.primaryBrown,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Puesta ✨',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Slot #${index + 1}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: GarabuTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Acciones: Poner / Quitar, Editar, Eliminar
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón Poner / Quitar
                            IconButton(
                              tooltip: isEquipped ? 'Quitar prenda' : 'Poner prenda',
                              icon: Icon(
                                isEquipped ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: isEquipped ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
                              ),
                              onPressed: () async {
                                final newActive = isEquipped ? null : garment.id;
                                await petRepo.equipGarment(
                                  petId: pet.id,
                                  garmentId: newActive,
                                );
                              },
                            ),

                            // Botón Editar
                            IconButton(
                              tooltip: 'Editar prenda',
                              icon: const Icon(Icons.edit_outlined, size: 20, color: GarabuTheme.primaryBrown),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ClothesCanvasScreen(
                                      couple: couple,
                                      editingGarmentId: garment.id,
                                      initialGarmentName: garment.name,
                                    ),
                                  ),
                                );
                              },
                            ),

                            // Botón Eliminar
                            IconButton(
                              tooltip: 'Eliminar prenda',
                              icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFC62828)),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('¿Eliminar prenda?'),
                                    content: Text('¿Deseas eliminar "${garment.name}" del clóset?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
                                        onPressed: () => Navigator.of(ctx).pop(true),
                                        child: const Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await petRepo.deleteGarment(
                                    petId: pet.id,
                                    garmentId: garment.id,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                } else {
                  // Slot Vacío disponible
                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ClothesCanvasScreen(couple: couple),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: GarabuTheme.paperWhite.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: GarabuTheme.warmSand,
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: GarabuTheme.warmSand),
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: GarabuTheme.primaryBrown,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Slot #${index + 1} libre',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: GarabuTheme.deepEspresso,
                                ),
                              ),
                              const Text(
                                'Toca para dibujar una nueva prenda',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: GarabuTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
