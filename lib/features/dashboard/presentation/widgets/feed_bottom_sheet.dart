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

          // Encabezado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alimentar a ${pet.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Arrastra la comida a la boca de tu mascota',
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
          const SizedBox(height: 14),

          // Tarjeta de Acción: Dar Agua Fresca (Sed) - SIN EMOJIS
          InkWell(
            onTap: () {
              Navigator.of(context).pop();
              if (onWaterGiven != null) {
                onWaterGiven!();
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFE1F5FE),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFB3E5FC)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: Color(0xFF0288D1),
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dar agua fresca',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0277BD),
                          ),
                        ),
                        Text(
                          'Mantén a ${pet.name} hidratado',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF01579B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF0277BD)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Grid de las 6 frutas
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: kAvailableFruits.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final fruit = kAvailableFruits[index];
              final isDrawn = drawnFruits.containsKey(fruit.key);
              final imageUrl = drawnFruits[fruit.key];
              final count = inventory[fruit.key] ?? 0;
              final canFeed = isDrawn && count > 0;

              return InkWell(
                onTap: () {
                  if (canFeed) {
                    Navigator.of(context).pop();
                    if (onFruitFed != null) {
                      onFruitFed!(fruit);
                    }
                  } else if (!isDrawn) {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FruitCanvasScreen(pet: pet, fruit: fruit),
                      ),
                    );
                  } else {
                    // Está agotada, sugerir comprar en tienda
                    Navigator.of(context).pop();
                    ShopBottomSheet.show(context: context, pet: pet);
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: canFeed
                        ? GarabuTheme.paperWhite
                        : GarabuTheme.paperWhite.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: canFeed ? GarabuTheme.primaryBrown : GarabuTheme.warmSand,
                      width: canFeed ? 1.8 : 1.0,
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
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Vista previa de imagen dibujada o círculo de color de la fruta
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDrawn
                                    ? Colors.white
                                    : fruit.color.withValues(alpha: 0.2),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Center(
                                child: isDrawn && imageUrl != null
                                    ? Padding(
                                        padding: const EdgeInsets.all(4.0),
                                        child: GarabuImage(
                                          imageUrl: imageUrl,
                                          fit: BoxFit.contain,
                                        ),
                                      )
                                    : Icon(
                                        Icons.brush_rounded,
                                        color: fruit.color,
                                        size: 24,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Nombre de la fruta
                            Text(
                              fruit.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: GarabuTheme.deepEspresso,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Estado / Botón
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: canFeed
                                    ? const Color(0xFFE8F5E9)
                                    : (!isDrawn
                                        ? GarabuTheme.warmSand.withValues(alpha: 0.5)
                                        : const Color(0xFFFFEBEE)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                canFeed
                                    ? 'Dar (x$count)'
                                    : (!isDrawn ? 'Dibujar' : 'Agotada'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: canFeed
                                      ? const Color(0xFF2E7D32)
                                      : (!isDrawn
                                          ? GarabuTheme.textSecondary
                                          : const Color(0xFFC62828)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Contador badge si tiene existencias
                      if (count > 0)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: GarabuTheme.primaryBrown,
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
                ),
              );
            },
          ),
          const SizedBox(height: 14),

          // Botón para ir a la Tienda
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              ShopBottomSheet.show(context: context, pet: pet);
            },
            icon: const Icon(Icons.storefront_rounded, size: 18),
            label: const Text('Comprar más alimentos en la Tienda'),
            style: OutlinedButton.styleFrom(
              foregroundColor: GarabuTheme.primaryBrown,
              side: const BorderSide(color: GarabuTheme.primaryBrown),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
