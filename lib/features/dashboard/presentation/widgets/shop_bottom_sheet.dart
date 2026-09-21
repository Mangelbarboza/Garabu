import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../canvas/presentation/fruit_canvas_screen.dart';
import '../../../pet/data/pet_repository.dart';
import '../../../pet/domain/pet_model.dart';

class ShopBottomSheet extends ConsumerWidget {
  final PetModel pet;

  const ShopBottomSheet({
    super.key,
    required this.pet,
  });

  static void show({
    required BuildContext context,
    required PetModel pet,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShopBottomSheet(pet: pet),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final petRepo = ref.read(petRepositoryProvider);
    final drawnFruits = pet.drawnFruits;
    final inventory = pet.foodInventory;

    return Container(
      decoration: const BoxDecoration(
        color: GarabuTheme.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
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

          // Encabezado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tienda de Alimentos',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Compra alimentos consumibles para tu mascota',
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
          const SizedBox(height: 18),

          // Grid de las 6 frutas
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kAvailableFruits.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 14,
              childAspectRatio: 0.84,
            ),
            itemBuilder: (context, index) {
              final fruit = kAvailableFruits[index];
              final isDrawn = drawnFruits.containsKey(fruit.key);
              final count = inventory[fruit.key] ?? 0;

              return Container(
                decoration: BoxDecoration(
                  color: GarabuTheme.paperWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: GarabuTheme.warmSand.withValues(alpha: 0.7),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Botón con el color sólido característico de la fruta (sin imagen)
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        InkWell(
                          onTap: () {
                            if (!isDrawn) {
                              Navigator.of(context).pop();
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FruitCanvasScreen(pet: pet, fruit: fruit),
                                ),
                              );
                            } else {
                              petRepo.buyFruit(petId: pet.id, fruitKey: fruit.key, quantity: 1);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('¡Compraste 1 ${fruit.name}! (Tienes ${count + 1})'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: GarabuTheme.primaryBrown,
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: fruit.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: fruit.color.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              isDrawn ? Icons.shopping_bag_outlined : Icons.edit_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (count > 0)
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: GarabuTheme.deepEspresso,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                'x$count',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Nombre de la fruta
                    Text(
                      fruit.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: GarabuTheme.deepEspresso,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Estado: Dibujar o Comprar
                    if (!isDrawn)
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => FruitCanvasScreen(pet: pet, fruit: fruit),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: GarabuTheme.warmSand.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Dibujar',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: GarabuTheme.primaryBrown,
                            ),
                          ),
                        ),
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          InkWell(
                            onTap: () {
                              petRepo.buyFruit(petId: pet.id, fruitKey: fruit.key, quantity: 1);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('¡Compraste 1 ${fruit.name}! (Tienes ${count + 1})'),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: GarabuTheme.primaryBrown,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: GarabuTheme.warmSand.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Gratis',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: GarabuTheme.primaryBrown,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Tooltip(
                            message: 'Redibujar forma',
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => FruitCanvasScreen(pet: pet, fruit: fruit),
                                  ),
                                );
                              },
                              child: const Padding(
                                padding: EdgeInsets.all(2.0),
                                child: Icon(Icons.edit_rounded, size: 12, color: GarabuTheme.textSecondary),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
