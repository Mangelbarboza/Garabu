import 'package:flutter/material.dart';
import '../../../../core/theme/garabu_theme.dart';

class GameCenterBottomSheet extends StatelessWidget {
  const GameCenterBottomSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const GameCenterBottomSheet(),
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
          const SizedBox(height: 20),

          // Ícono de control de videojuegos estilo boceto
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GarabuTheme.paperWhite,
              shape: BoxShape.circle,
              border: Border.all(color: GarabuTheme.warmSand, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              size: 36,
              color: GarabuTheme.primaryBrown,
            ),
          ),
          const SizedBox(height: 16),

          const Text(
            'Sala de Juegos',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: GarabuTheme.deepEspresso,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Minijuegos interactivos en tiempo real para jugar en pareja',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              color: GarabuTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Tarjeta "En Desarrollo"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: GarabuTheme.paperWhite,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: GarabuTheme.primaryBrown.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: GarabuTheme.primaryBrown,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'En desarrollo activo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildGamePreviewItem(
                  icon: Icons.apple_rounded,
                  title: 'Atrapa Garabutos',
                  desc: 'Atrapa las frutas dibujadas que caen en pareja',
                ),
                const SizedBox(height: 10),
                _buildGamePreviewItem(
                  icon: Icons.draw_rounded,
                  title: 'Duelo de Bocetos',
                  desc: 'Adivina qué está dibujando tu pareja en vivo',
                ),
                const SizedBox(height: 10),
                _buildGamePreviewItem(
                  icon: Icons.favorite_rounded,
                  title: 'Trivia de Pareja',
                  desc: '¿Cuánto se conocen? Responde y gana monedas',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('¡Entendido!'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamePreviewItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: GarabuTheme.warmSand),
          ),
          child: Icon(icon, size: 20, color: GarabuTheme.primaryBrown),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: GarabuTheme.deepEspresso,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: GarabuTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
