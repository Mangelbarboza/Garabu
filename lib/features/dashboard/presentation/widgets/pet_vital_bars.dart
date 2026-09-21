import 'package:flutter/material.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../pet/domain/pet_model.dart';

class PetVitalBars extends StatelessWidget {
  final PetModel pet;
  final bool isCompact;

  const PetVitalBars({
    super.key,
    required this.pet,
    this.isCompact = false,
  });

  double _calculateHunger() {
    if (pet.lastFedAt == null) return 0.4;
    final diffHours = DateTime.now().difference(pet.lastFedAt!).inMinutes / 60.0;
    // Se vacía en unas 6 horas
    return (1.0 - (diffHours / 6.0)).clamp(0.05, 1.0);
  }

  double _calculateThirst() {
    if (pet.lastWateredAt == null) return 0.5;
    final diffHours = DateTime.now().difference(pet.lastWateredAt!).inMinutes / 60.0;
    // Se vacía en unas 4 horas
    return (1.0 - (diffHours / 4.0)).clamp(0.05, 1.0);
  }

  double _calculateEnergy() {
    if (pet.isSleeping) return 1.0;
    // Energía estándar si está despierto
    return 0.75;
  }

  double _calculateHappiness() {
    if (pet.lastPettedAt == null) return 0.5;
    final diffMinutes = DateTime.now().difference(pet.lastPettedAt!).inSeconds / 60.0;
    // Se mantiene alto por 30 minutos tras acariciar
    return (1.0 - (diffMinutes / 30.0)).clamp(0.15, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final hunger = _calculateHunger();
    final thirst = _calculateThirst();
    final energy = _calculateEnergy();
    final happiness = _calculateHappiness();

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GarabuTheme.warmSand.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMiniBar(icon: Icons.restaurant_rounded, value: hunger, color: const Color(0xFFE57373)),
            const SizedBox(width: 8),
            _buildMiniBar(icon: Icons.water_drop_rounded, value: thirst, color: const Color(0xFF64B5F6)),
            const SizedBox(width: 8),
            _buildMiniBar(icon: Icons.bedtime_rounded, value: energy, color: const Color(0xFFFFB74D)),
            const SizedBox(width: 8),
            _buildMiniBar(icon: Icons.favorite_rounded, value: happiness, color: const Color(0xFFF06292)),
          ],
        ),
      );
    }

    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GarabuTheme.warmSand.withValues(alpha: 0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatRow(
            label: 'Hambre',
            icon: Icons.restaurant_rounded,
            value: hunger,
            barColor: const Color(0xFFE57373),
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            label: 'Sed',
            icon: Icons.water_drop_rounded,
            value: thirst,
            barColor: const Color(0xFF64B5F6),
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            label: 'Energía',
            icon: Icons.bedtime_rounded,
            value: energy,
            barColor: const Color(0xFFFFB74D),
          ),
          const SizedBox(height: 8),
          _buildStatRow(
            label: 'Ánimo',
            icon: Icons.favorite_rounded,
            value: happiness,
            barColor: const Color(0xFFF06292),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBar({
    required IconData icon,
    required double value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            width: 28,
            height: 6,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: GarabuTheme.warmSand.withValues(alpha: 0.4),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow({
    required String label,
    required IconData icon,
    required double value,
    required Color barColor,
  }) {
    final percent = (value * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: barColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: GarabuTheme.deepEspresso,
              ),
            ),
            const Spacer(),
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: GarabuTheme.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 7,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: value),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (context, animValue, _) {
                return LinearProgressIndicator(
                  value: animValue,
                  backgroundColor: GarabuTheme.warmSand.withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(barColor),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
