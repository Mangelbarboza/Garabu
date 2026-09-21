import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../canvas/presentation/fruit_canvas_screen.dart';
import '../../../pet/domain/pet_model.dart';

class FeedBottomSheet extends StatelessWidget {
  final PetModel pet;
  final void Function(FruitInfo fruit)? onFruitFed;

  const FeedBottomSheet({
    super.key,
    required this.pet,
    this.onFruitFed,
  });

  static void show({
    required BuildContext context,
    required PetModel pet,
    required void Function(FruitInfo fruit) onFruitFed,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FeedBottomSheet(
        pet: pet,
        onFruitFed: onFruitFed,
      ),
    );
  }

  Widget _buildFruitImage(String imageUrl) {
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
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final drawnFruits = pet.drawnFruits;

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
          // Barra de agarre superior
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
                    'Alimentar a ${pet.name} 🍎',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Dibuja cada fruta para poder usarla como comida',
                    style: TextStyle(
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
                  '${drawnFruits.length}/${kAvailableFruits.length} listas',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: GarabuTheme.deepEspresso,
                  ),
                ),
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
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemBuilder: (context, index) {
              final fruit = kAvailableFruits[index];
              final isDrawn = drawnFruits.containsKey(fruit.key);
              final imageUrl = drawnFruits[fruit.key];

              return InkWell(
                onTap: () {
                  if (isDrawn) {
                    Navigator.of(context).pop();
                    if (onFruitFed != null) {
                      onFruitFed!(fruit);
                    }
                  } else {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FruitCanvasScreen(pet: pet, fruit: fruit),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDrawn ? GarabuTheme.paperWhite : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDrawn ? GarabuTheme.primaryBrown : GarabuTheme.warmSand,
                      width: isDrawn ? 1.8 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Imagen dibujada o Emoji bloqueado
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDrawn
                              ? Colors.white
                              : GarabuTheme.warmSand.withValues(alpha: 0.3),
                        ),
                        child: Center(
                          child: isDrawn && imageUrl != null
                              ? Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: _buildFruitImage(imageUrl),
                                )
                              : Text(
                                  fruit.emoji,
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: Colors.grey.withValues(alpha: 0.6),
                                  ),
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
                          color: isDrawn
                              ? const Color(0xFFE8F5E9)
                              : GarabuTheme.warmSand.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isDrawn ? 'Alimentar ✨' : 'Dibujar ✏️',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDrawn ? const Color(0xFF2E7D32) : GarabuTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
