import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../../core/widgets/garabu_image.dart';
import '../../../../core/widgets/notebook_background.dart';
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
                        // Prenda con desplazamiento interactivo
                        Positioned.fill(
                          child: GestureDetector(
                            onPanUpdate: (details) {
                              setDialogState(() {
                                offsetX += details.delta.dx;
                                offsetY += details.delta.dy;
                              });
                            },
                            child: Transform.translate(
                              offset: Offset(offsetX, offsetY),
                              child: GarabuImage(
                                imageUrl: garment.imageUrl,
                                width: 220,
                                height: 220,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Controles de Flechas direccionales finas
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Mover Izquierda',
                        icon: const Icon(Icons.arrow_back_rounded, color: GarabuTheme.primaryBrown),
                        onPressed: () => setDialogState(() => offsetX -= 3),
                      ),
                      Column(
                        children: [
                          IconButton(
                            tooltip: 'Mover Arriba',
                            icon: const Icon(Icons.arrow_upward_rounded, color: GarabuTheme.primaryBrown),
                            onPressed: () => setDialogState(() => offsetY -= 3),
                          ),
                          IconButton(
                            tooltip: 'Mover Abajo',
                            icon: const Icon(Icons.arrow_downward_rounded, color: GarabuTheme.primaryBrown),
                            onPressed: () => setDialogState(() => offsetY += 3),
                          ),
                        ],
                      ),
                      IconButton(
                        tooltip: 'Mover Derecha',
                        icon: const Icon(Icons.arrow_forward_rounded, color: GarabuTheme.primaryBrown),
                        onPressed: () => setDialogState(() => offsetX += 3),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: () => setDialogState(() {
                          offsetX = 0;
                          offsetY = 0;
                        }),
                        child: const Text('Centrar', style: TextStyle(fontSize: 12)),
                      ),
                    ],
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
                  },
                  child: const Text('Guardar Posición'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reactividad en vivo: observar siempre la mascota en tiempo real para refresco automático
    final petAsync = ref.watch(currentPetProvider(pet.id));
    final livePet = petAsync.value ?? pet;
    final petRepo = ref.read(petRepositoryProvider);
    final closet = livePet.closet;
    final equippedIds = livePet.resolvedEquippedGarmentIds;
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
                    'Clóset de Prendas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Hasta 2 prendas a la vez para ${livePet.name}',
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
                  final bool isEquipped = equippedIds.contains(garment.id);
                  final int equipIndex = equippedIds.indexOf(garment.id);

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
                                  Flexible(
                                    child: Text(
                                      garment.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: GarabuTheme.deepEspresso,
                                      ),
                                      overflow: TextOverflow.ellipsis,
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
                                      child: Text(
                                        equippedIds.length > 1 ? 'Puesta #${equipIndex + 1}' : 'Puesta',
                                        style: const TextStyle(
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

                        // Acciones: Poner / Quitar, Mover Posición, Editar, Eliminar
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Botón Poner / Quitar (soporta hasta 2 a la vez)
                            IconButton(
                              tooltip: isEquipped ? 'Quitar prenda' : 'Poner prenda (hasta 2)',
                              icon: Icon(
                                isEquipped ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: isEquipped ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
                              ),
                              onPressed: () async {
                                await petRepo.toggleEquipGarment(
                                  petId: livePet.id,
                                  garmentId: garment.id,
                                );
                              },
                            ),

                            // Botón Ajustar Posición (Mover sobre la mascota)
                            IconButton(
                              tooltip: 'Mover y ajustar posición',
                              icon: const Icon(Icons.open_with_rounded, size: 20, color: GarabuTheme.deepEspresso),
                              onPressed: () => _showAdjustPositionDialog(context, ref, livePet, garment),
                            ),

                            // Botón Editar
                            IconButton(
                              tooltip: 'Editar dibujo de prenda',
                              icon: const Icon(Icons.edit_outlined, size: 20, color: GarabuTheme.primaryBrown),
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ClothesCanvasScreen(
                                      couple: couple,
                                      pet: livePet,
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
                                    petId: livePet.id,
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
                          builder: (_) => ClothesCanvasScreen(
                            couple: couple,
                            pet: livePet,
                          ),
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
                                'Toca para diseñar una prenda',
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
