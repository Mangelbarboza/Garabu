import 'package:flutter/material.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../../core/widgets/garabu_image.dart';
import '../../../canvas/presentation/fruit_canvas_screen.dart';
import '../../../pet/domain/pet_model.dart';
import 'shop_bottom_sheet.dart';

class FeedBottomSheet extends StatelessWidget {
  final PetModel pet;
  final void Function(FruitInfo fruit)? onFruitFed;
  final VoidCallback? onWaterGiven;

  const FeedBottomSheet({
    super.key,
    required this.pet,
    this.onFruitFed,
    this.onWaterGiven,
  });

  static void show({
    required BuildContext context,
    required PetModel pet,
    required void Function(FruitInfo fruit) onFruitFed,
    VoidCallback? onWaterGiven,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeedBottomSheet(
        pet: pet,
        onFruitFed: onFruitFed,
        onWaterGiven: onWaterGiven,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drawnFruits = pet.drawnFruits;
    final inventory = pet.foodInventory;

    // Solo los productos con stock > 0 salen en la alacena
    final availableItems = kAvailableFruits.where((f) => (inventory[f.key] ?? 0) > 0).toList();

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

          // Encabezado de la Alacena
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alacena de ${pet.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Toca un alimento para dárselo en la boca',
                    style: TextStyle(
                      fontSize: 13,
                      color: GarabuTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: GarabuTheme.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Cuadrícula compacta estilo Alacena con cajoncitos (4 columnas)
          if (availableItems.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: GarabuTheme.paperWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GarabuTheme.warmSand.withValues(alpha: 0.6)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.kitchen_rounded,
                    size: 44,
                    color: GarabuTheme.primaryBrown.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tu alacena está vacía',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ve a la tienda para conseguir frutas y agua fresca',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: GarabuTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ShopBottomSheet.show(context: context, pet: pet);
                    },
                    icon: const Icon(Icons.storefront_rounded, size: 18),
                    label: const Text('Abrir Tienda'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GarabuTheme.primaryBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availableItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.84,
              ),
              itemBuilder: (context, index) {
                final fruit = availableItems[index];
                final isDrawn = drawnFruits.containsKey(fruit.key);
                final imageUrl = drawnFruits[fruit.key];
                final count = inventory[fruit.key] ?? 0;

                return InkWell(
                  onTap: () {
                    Navigator.of(context).pop();
                    if (onFruitFed != null) {
                      onFruitFed!(fruit);
                    }
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: GarabuTheme.paperWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: GarabuTheme.warmSand,
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Stack(
                      children: [
                        // Insignia solo con el número de existencias
                        Positioned(
                          top: 0,
                          right: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: GarabuTheme.primaryBrown,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // Cajoncito: dibujo redondo + etiqueta con nombre
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: 4),
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDrawn
                                      ? Colors.white
                                      : fruit.color.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: fruit.color.withValues(alpha: 0.5),
                                    width: 1.5,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Center(
                                  child: isDrawn && imageUrl != null
                                      ? Padding(
                                          padding: const EdgeInsets.all(3.0),
                                          child: GarabuImage(
                                            imageUrl: imageUrl,
                                            fit: BoxFit.contain,
                                          ),
                                        )
                                      : Icon(
                                          Icons.brush_rounded,
                                          color: fruit.color,
                                          size: 18,
                                        ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                fruit.name,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: GarabuTheme.deepEspresso,
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
            ),
          ],
          const SizedBox(height: 14),

          // Acceso a la Tienda
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ShopBottomSheet.show(context: context, pet: pet);
            },
            icon: const Icon(Icons.storefront_rounded, size: 18, color: GarabuTheme.primaryBrown),
            label: const Text(
              'Ir a la Tienda',
              style: TextStyle(
                color: GarabuTheme.primaryBrown,
                fontWeight: FontWeight.bold,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
