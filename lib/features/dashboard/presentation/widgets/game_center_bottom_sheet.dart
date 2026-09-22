import 'package:flutter/material.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../minigames/atrapa_garabutos_screen.dart';
import '../../../pet/domain/pet_model.dart';

class GameCenterBottomSheet extends StatelessWidget {
  final PetModel pet;

  const GameCenterBottomSheet({
    super.key,
    required this.pet,
  });

  static void show(BuildContext context, PetModel pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GameCenterBottomSheet(pet: pet),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        children: [
          // Barra de agarre
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: GarabuTheme.warmSand,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Ícono de control de videojuegos
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
                      Icons.sports_esports_rounded,
                      size: 26,
                      color: GarabuTheme.primaryBrown,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sala de Juegos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: GarabuTheme.deepEspresso,
                        ),
                      ),
                      Text(
                        '¡Gana Monedas Garabu y diviértete!',
                        style: TextStyle(
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
          const SizedBox(height: 16),

          // Tarjeta del juego activo: Atrapa Garabutos
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GarabuTheme.paperWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: GarabuTheme.primaryBrown,
                width: 1.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        '¡NUEVO Y DISPONIBLE!',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.monetization_on_rounded, color: Color(0xFFFFA000), size: 16),
                    const SizedBox(width: 4),
                    const Text('Recompensa: Monedas', style: TextStyle(fontSize: 11, color: GarabuTheme.textSecondary)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFFD54F)),
                      ),
                      child: const Center(
                        child: Icon(Icons.star_rounded, color: Color(0xFFFFA000), size: 28),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atrapa Garabutos',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Mueve la canasta de tu mascota para atrapar todas las frutas y estrellas que caen.',
                            style: TextStyle(fontSize: 12, color: GarabuTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AtrapaGarabutosScreen(pet: pet),
                        ),
                      );
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: const Text('Jugar Ahora', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
          ),
          const SizedBox(height: 12),

          // Próximamente
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: GarabuTheme.paperWhite.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GarabuTheme.warmSand.withValues(alpha: 0.5)),
            ),
            child: const Row(
              children: [
                Icon(Icons.hourglass_top_rounded, size: 18, color: GarabuTheme.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Próximamente: "Dibuja y Adivina en Pareja" y "Batalla de Cosquillas"',
                    style: TextStyle(fontSize: 11.5, color: GarabuTheme.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
