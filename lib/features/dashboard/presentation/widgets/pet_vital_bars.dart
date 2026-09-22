import 'package:flutter/material.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../pet/domain/pet_model.dart';

class PetVitalBars extends StatefulWidget {
  final PetModel pet;
  final bool isCompact;

  const PetVitalBars({
    super.key,
    required this.pet,
    this.isCompact = false,
  });

  @override
  State<PetVitalBars> createState() => _PetVitalBarsState();
}

class _PetVitalBarsState extends State<PetVitalBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _chargeAnimController;

  @override
  void initState() {
    super.initState();
    _chargeAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _chargeAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pet = widget.pet;
    final hunger = pet.hunger;
    final thirst = pet.thirst;
    final energy = pet.energy;
    final happiness = pet.happiness;

    if (widget.isCompact) {
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
            _buildMiniBar(
              icon: pet.isSleeping ? Icons.bolt_rounded : Icons.bedtime_rounded,
              value: energy,
              color: pet.isSleeping ? const Color(0xFFFFD54F) : const Color(0xFFFFB74D),
              isCharging: pet.isSleeping,
            ),
            const SizedBox(width: 8),
            _buildMiniBar(icon: Icons.favorite_rounded, value: happiness, color: const Color(0xFFF06292)),
          ],
        ),
      );
    }

    return Container(
      width: 175,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: GarabuTheme.warmSand.withValues(alpha: 0.8), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nivel y barra de EXP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.stars_rounded, color: Color(0xFFFFA000), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Nvl. ${pet.level}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                ],
              ),
              Text(
                '${pet.experience}/${pet.maxExperienceForLevel} EXP',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: GarabuTheme.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 5,
              child: LinearProgressIndicator(
                value: pet.levelProgress,
                backgroundColor: GarabuTheme.warmSand.withValues(alpha: 0.35),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA000)),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Barras de vitalidad
          _buildStatRow(
            label: 'Hambre',
            icon: Icons.restaurant_rounded,
            value: hunger,
            barColor: const Color(0xFFE57373),
          ),
          const SizedBox(height: 7),
          _buildStatRow(
            label: 'Sed',
            icon: Icons.water_drop_rounded,
            value: thirst,
            barColor: const Color(0xFF64B5F6),
          ),
          const SizedBox(height: 7),
          _buildStatRow(
            label: 'Energía',
            icon: pet.isSleeping ? Icons.bolt_rounded : Icons.bedtime_rounded,
            value: energy,
            barColor: pet.isSleeping ? const Color(0xFFFFD54F) : const Color(0xFFFFB74D),
            isCharging: pet.isSleeping,
          ),
          const SizedBox(height: 7),
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
    bool isCharging = false,
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
            child: isCharging
                ? AnimatedBuilder(
                    animation: _chargeAnimController,
                    builder: (context, _) {
                      return Opacity(
                        opacity: 0.6 + (_chargeAnimController.value * 0.4),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: GarabuTheme.warmSand.withValues(alpha: 0.4),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      );
                    },
                  )
                : LinearProgressIndicator(
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
    bool isCharging = false,
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
                color: isCharging ? const Color(0xFFF57F17) : GarabuTheme.textSecondary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 7,
            child: isCharging
                ? AnimatedBuilder(
                    animation: _chargeAnimController,
                    builder: (context, _) {
                      return Opacity(
                        opacity: 0.65 + (_chargeAnimController.value * 0.35),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: GarabuTheme.warmSand.withValues(alpha: 0.4),
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      );
                    },
                  )
                : TweenAnimationBuilder<double>(
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
