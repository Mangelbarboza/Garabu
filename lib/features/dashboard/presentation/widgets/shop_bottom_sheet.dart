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
  final int price;

  const CatalogBackground({
    required this.id,
    required this.title,
    required this.assetPath,
    required this.description,
    this.price = 100,
  });
}

const List<CatalogBackground> kCatalogBackgrounds = [
  CatalogBackground(
    id: 'habitacion_acogedora',
    title: 'Habitación Acogedora',
    assetPath: 'assets/backgrounds/habitacion_acogedora.jpg',
    description: 'Boceto de cuarto cálido con escritorio, plantas y ventana.',
    price: 80,
  ),
  CatalogBackground(
    id: 'jardin_flores',
    title: 'Jardín de Flores',
    assetPath: 'assets/backgrounds/jardin_flores.jpg',
    description: 'Boceto de jardín al aire libre con flores, mariposas y cerca.',
    price: 100,
  ),
  CatalogBackground(
    id: 'noche_estrellada',
    title: 'Noche Estrellada',
    assetPath: 'assets/backgrounds/noche_estrellada.jpg',
    description: 'Cielo nocturno de estrellas, luna y constelaciones.',
    price: 120,
  ),
  CatalogBackground(
    id: 'cafeteria_paris',
    title: 'Cafetería de París',
    assetPath: 'assets/backgrounds/cafeteria_paris.jpg',
    description: 'Bistró parisino con sombrilla, mesita y croasán.',
    price: 110,
  ),
  CatalogBackground(
    id: 'bosque_magico',
    title: 'Bosque Mágico',
    assetPath: 'assets/backgrounds/bosque_magico.jpg',
    description: 'Árbol sabio y mágico con farol y luciérnagas.',
    price: 150,
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
  int _selectedTab = 0; // 0 = Comida, 1 = Ropa, 2 = Fondos
  String? _animatingItemKey;

  Future<void> _onBuyItem(String key, int price) async {
    setState(() => _animatingItemKey = key);
    final petRepo = ref.read(petRepositoryProvider);
    await petRepo.buyFruit(petId: widget.pet.id, fruitKey: key, quantity: 1, price: price);
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) setState(() => _animatingItemKey = null);
    });
  }

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
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(currentPetProvider(widget.pet.id));
    final pet = petAsync.value ?? widget.pet;
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

          // Encabezado con saldo de Monedas Garabu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD54F)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFA000), size: 18),
                        const SizedBox(width: 5),
                        Text(
                          '${pet.coins}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: GarabuTheme.deepEspresso,
                          ),
                        ),
                      ],
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
          const SizedBox(height: 12),

          // Pestañas SOLO con iconos (sin nombres de texto)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: GarabuTheme.warmSand.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                // 1. Icono de Comida
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _selectedTab == 0
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.restaurant_rounded,
                        size: 22,
                        color: _selectedTab == 0 ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
                      ),
                    ),
                  ),
                ),

                // 2. Icono de Ropa
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _selectedTab == 1
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.checkroom_rounded,
                        size: 22,
                        color: _selectedTab == 1 ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
                      ),
                    ),
                  ),
                ),

                // 3. Icono de Fondos
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedTab == 2 ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: _selectedTab == 2
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Icon(
                        Icons.wallpaper_rounded,
                        size: 22,
                        color: _selectedTab == 2 ? GarabuTheme.primaryBrown : GarabuTheme.textSecondary,
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
            // Pestaña Comida (Frutas + Agua)
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                itemCount: kAvailableFruits.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  final fruit = kAvailableFruits[index];
                  final isDrawn = drawnFruits.containsKey(fruit.key);
                  final count = inventory[fruit.key] ?? 0;
                  final isAnimating = _animatingItemKey == fruit.key;

                  return AnimatedScale(
                    scale: isAnimating ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutBack,
                    child: Container(
                      decoration: BoxDecoration(
                        color: GarabuTheme.paperWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isAnimating ? GarabuTheme.primaryBrown : GarabuTheme.warmSand.withValues(alpha: 0.7),
                          width: isAnimating ? 2.0 : 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Botón del alimento con contador instantáneo
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
                                    _onBuyItem(fruit.key, fruit.price);
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
                                    isDrawn ? Icons.add_shopping_cart_rounded : Icons.edit_rounded,
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
                                      '$count',
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
                          const SizedBox(height: 5),

                          // Nombre
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
                          const SizedBox(height: 3),

                          // Precio e Interacción (SIN SNACKBAR)
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
                                  onTap: () => _onBuyItem(fruit.key, fruit.price),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF8E1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFFFD54F), width: 0.8),
                                    ),
                                    child: Text(
                                      '🪙 ${fruit.price}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE65100),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Tooltip(
                                  message: 'Redibujar',
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
                    ),
                  );
                },
              ),
            ),
          ] else if (_selectedTab == 1) ...[
            // Pestaña Ropa (Prendas y Accesorios en confección)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.checkroom_rounded,
                      size: 48,
                      color: GarabuTheme.primaryBrown.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Taller de Ropa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: GarabuTheme.deepEspresso,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        'Crea prendas únicas dibujándolas sobre tu mascota en el Clóset. ¡Próximamente nuevos accesorios para comprar!',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12.5, color: GarabuTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Pestaña Fondos
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GarabuImage(
                            imageUrl: bg.assetPath,
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bg.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: GarabuTheme.deepEspresso,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                bg.description,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: GarabuTheme.textSecondary,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '🪙 ${bg.price}',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
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
