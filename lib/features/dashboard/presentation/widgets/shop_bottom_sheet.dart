import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../../core/widgets/garabu_image.dart';
import '../../../canvas/presentation/fruit_canvas_screen.dart';
import '../../../pet/data/pet_repository.dart';
import '../../../pet/domain/pet_model.dart';

class CatalogBackground {
  final String id;
  final String title;
  final String assetPath;
  final String description;

  const CatalogBackground({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.description,
  });
}

const List<CatalogBackground> kCatalogBackgrounds = [
  CatalogBackground(
    id: 'habitacion_acogedora',
    title: 'Habitación Acogedora',
    assetPath: 'assets/backgrounds/habitacion_acogedora.jpg',
    description: 'Boceto de cuarto cálido con escritorio, plantas y ventana.',
  ),
  CatalogBackground(
    id: 'jardin_flores',
    title: 'Jardín de Flores',
    assetPath: 'assets/backgrounds/jardin_flores.jpg',
    description: 'Boceto de jardín al aire libre con flores, mariposas y cerca.',
  ),
  CatalogBackground(
    id: 'noche_estrellada',
    title: 'Noche Estrellada',
    assetPath: 'assets/backgrounds/noche_estrellada.jpg',
    description: 'Cielo nocturno de estrellas, luna y constelaciones.',
  ),
  CatalogBackground(
    id: 'cafeteria_paris',
    title: 'Cafetería de París',
    assetPath: 'assets/backgrounds/cafeteria_paris.jpg',
    description: 'Bistró parisino con sombrilla, mesita y croasán.',
  ),
  CatalogBackground(
    id: 'bosque_magico',
    title: 'Bosque Mágico',
    assetPath: 'assets/backgrounds/bosque_magico.jpg',
    description: 'Árbol sabio y mágico con farol y luciérnagas.',
  ),
];

class ShopBottomSheet extends ConsumerStatefulWidget {
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
  ConsumerState<ShopBottomSheet> createState() => _ShopBottomSheetState();
}

class _ShopBottomSheetState extends ConsumerState<ShopBottomSheet> {
  int _selectedTab = 0; // 0 = Alimentos, 1 = Fondos

  Future<void> _applyBackgroundToSlot(PetModel pet, CatalogBackground bg) async {
    final petRepo = ref.read(petRepositoryProvider);
    final chosenSlot = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GarabuTheme.paperWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Equipar "${bg.title}"',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: GarabuTheme.deepEspresso,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Selecciona en cuál de los 3 slots deseas guardar este fondo:',
              style: TextStyle(fontSize: 13, color: GarabuTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            for (int i = 0; i < 3; i++) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  dense: true,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: const BorderSide(color: GarabuTheme.warmSand),
                  ),
                  tileColor: Colors.white,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: GarabuTheme.primaryBrown,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    'Slot #${i + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso),
                  ),
                  subtitle: Text(
                    pet.backgroundSlots.length > i && pet.backgroundSlots[i] != null
                        ? 'Ocupado (se reemplazará)'
                        : 'Vacío',
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () => Navigator.of(ctx).pop(i),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (chosenSlot == null) return;

    await petRepo.updateBackgroundSlot(
      petId: pet.id,
      coupleId: pet.coupleId,
      slotIndex: chosenSlot,
      customUrl: bg.assetPath,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡"${bg.title}" equipado con éxito en Slot #${chosenSlot + 1}!'),
          backgroundColor: GarabuTheme.primaryBrown,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(currentPetProvider(widget.pet.id));
    final pet = petAsync.value ?? widget.pet;
    final petRepo = ref.read(petRepositoryProvider);
    final drawnFruits = pet.drawnFruits;
    final inventory = pet.foodInventory;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
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
          const SizedBox(height: 14),

          // Encabezado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tienda Garabu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _selectedTab == 0
                        ? 'Alimentos consumibles para tu mascota'
                        : 'Fondos ilustrados estilo boceto',
                    style: const TextStyle(
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

          // Selector de Pestañas
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: GarabuTheme.warmSand.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _selectedTab == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_rounded,
                            size: 16,
                            color: _selectedTab == 0 ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Alimentos',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 0 ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _selectedTab == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wallpaper_rounded,
                            size: 16,
                            color: _selectedTab == 1 ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Fondos (5)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 1 ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Contenido de la pestaña
          if (_selectedTab == 0) ...[
            // Tab 0: Grid de las 6 frutas
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
                      // Botón con el color sólido característico de la fruta
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
          ] else ...[
            // Tab 1: Lista de Fondos Temáticos
            Expanded(
              child: ListView.separated(
                itemCount: kCatalogBackgrounds.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final bg = kCatalogBackgrounds[index];
                  final isEquipped = pet.backgroundSlots.contains(bg.assetPath);

                  return Container(
                    decoration: BoxDecoration(
                      color: GarabuTheme.paperWhite,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isEquipped ? GarabuTheme.primaryBrown : GarabuTheme.warmSand,
                        width: isEquipped ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        // Vista previa cuadrada del fondo boceto
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GarabuImage(
                            imageUrl: bg.assetPath,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Información del fondo
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bg.title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: GarabuTheme.deepEspresso,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                bg.description,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: GarabuTheme.textSecondary,
                                  height: 1.25,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Botón de Equipar
                        ElevatedButton(
                          onPressed: () => _applyBackgroundToSlot(pet, bg),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEquipped ? GarabuTheme.warmSand : GarabuTheme.primaryBrown,
                            foregroundColor: isEquipped ? GarabuTheme.deepEspresso : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            isEquipped ? 'En Slot' : 'Equipar',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
