import 'package:flutter/material.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../lobby/domain/couple_model.dart';
import '../../../minigames/atrapa_garabutos_screen.dart';
import '../../../minigames/batalla_cosquillas_screen.dart';
import '../../../minigames/trivia_pareja_screen.dart';
import '../../../pet/domain/pet_model.dart';

class GameCenterBottomSheet extends StatefulWidget {
  final PetModel pet;
  final CoupleModel? couple;

  const GameCenterBottomSheet({
    super.key,
    required this.pet,
    this.couple,
  });

  static void show(BuildContext context, PetModel pet, [CoupleModel? couple]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GameCenterBottomSheet(pet: pet, couple: couple),
    );
  }

  @override
  State<GameCenterBottomSheet> createState() => _GameCenterBottomSheetState();
}

class _GameCenterBottomSheetState extends State<GameCenterBottomSheet> {
  int _selectedTabIndex = 0; // 0: En Solitario, 1: En Pareja

  @override
  Widget build(BuildContext context) {
    final u1 = widget.couple?.user1Name ?? 'Uno';
    final u2 = widget.couple?.user2Name ?? 'El otro';

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
      child: SingleChildScrollView(
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

            // Encabezado
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
                          '¡Gana Monedas, EXP y sube la diversión!',
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

            // Selector de Pestañas: [En Solitario] / [En Pareja]
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: GarabuTheme.warmSand.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      index: 0,
                      icon: Icons.person_rounded,
                      title: 'En Solitario',
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _buildTabButton(
                      index: 1,
                      icon: Icons.favorite_rounded,
                      title: 'En Pareja',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Vista según pestaña
            if (_selectedTabIndex == 0) ...[
              _buildSoloGames(u1, u2),
            ] else ...[
              _buildCoupleGames(u1, u2),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required int index,
    required IconData icon,
    required String title,
  }) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => setState(() => _selectedTabIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected
                  ? (index == 1 ? const Color(0xFFE91E63) : GarabuTheme.primaryBrown)
                  : GarabuTheme.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? (index == 1 ? const Color(0xFFE91E63) : GarabuTheme.deepEspresso)
                    : GarabuTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- MINIJUEGOS EN SOLITARIO ---
  Widget _buildSoloGames(String u1, String u2) {
    final recAtrapaU1 = widget.couple?.gameRecords['atrapa_garabutos_${widget.couple?.user1Id}'] ?? 0;
    final recAtrapaU2 = widget.couple?.gameRecords['atrapa_garabutos_${widget.couple?.user2Id}'] ?? 0;

    final recCosquillasU1 = widget.couple?.gameRecords['batalla_cosquillas_${widget.couple?.user1Id}'] ?? 0;
    final recCosquillasU2 = widget.couple?.gameRecords['batalla_cosquillas_${widget.couple?.user2Id}'] ?? 0;

    return Column(
      children: [
        // Tarjeta 1: Atrapa Garabutos
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
                      'REFLEJOS & COMPETITIVO',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.star_rounded, color: Color(0xFF2E7D32), size: 16),
                  const SizedBox(width: 4),
                  const Text('+40 EXP ⭐', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
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
                          '¡Esquiva bombas (-5s), atrapa relojes (+5s), frutas y estrellas doradas!',
                          style: TextStyle(fontSize: 12, color: GarabuTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Récord de pareja
              if (widget.couple != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9C4).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, size: 15, color: Color(0xFFFFA000)),
                      const SizedBox(width: 6),
                      Text(
                        'Récords: $u1 ($recAtrapaU1 pts)  |  $u2 ($recAtrapaU2 pts)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: GarabuTheme.deepEspresso),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AtrapaGarabutosScreen(pet: widget.pet, couple: widget.couple),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Jugar Atrapa Garabutos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
        const SizedBox(height: 14),

        // Tarjeta 2: Batalla de Cosquillas
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GarabuTheme.paperWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE91E63),
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
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'FIEBRE DE RISAS',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC2185B)),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.star_rounded, color: Color(0xFF2E7D32), size: 16),
                  const SizedBox(width: 4),
                  const Text('+45 EXP ⭐', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF48FB1)),
                    ),
                    child: const Center(
                      child: Icon(Icons.mood_rounded, color: Color(0xFFE91E63), size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batalla de Cosquillas',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '¡Rasquea rápido las garabu-pulguitas y activa la Fiebre de Carcajadas x2!',
                          style: TextStyle(fontSize: 12, color: GarabuTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Récord de pareja
              if (widget.couple != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, size: 15, color: Color(0xFFE91E63)),
                      const SizedBox(width: 6),
                      Text(
                        'Récords: $u1 ($recCosquillasU1 pts)  |  $u2 ($recCosquillasU2 pts)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: GarabuTheme.deepEspresso),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BatallaCosquillasScreen(pet: widget.pet, couple: widget.couple),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Jugar Batalla de Cosquillas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- MINIJUEGOS EN PAREJA ---
  Widget _buildCoupleGames(String u1, String u2) {
    final recTriviaU1 = widget.couple?.gameRecords['trivia_pareja_${widget.couple?.user1Id}'] ?? 0;
    final recTriviaU2 = widget.couple?.gameRecords['trivia_pareja_${widget.couple?.user2Id}'] ?? 0;

    return Column(
      children: [
        // Tarjeta: Trivia de Pareja
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: GarabuTheme.paperWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFFE91E63),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
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
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '¡COOPERATIVO DE PAREJA!',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFC2185B)),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.star_rounded, color: Color(0xFF2E7D32), size: 16),
                  const SizedBox(width: 4),
                  const Text('+50 EXP ⭐', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE4EC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFF48FB1)),
                    ),
                    child: const Center(
                      child: Icon(Icons.favorite_rounded, color: Color(0xFFE91E63), size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trivia de Pareja',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '¡Descubran qué tanto se conocen, anécdotas divertidas y cuidados de Garabu!',
                          style: TextStyle(fontSize: 12, color: GarabuTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Récord de pareja
              if (widget.couple != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC).withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_border_rounded, size: 15, color: Color(0xFFE91E63)),
                      const SizedBox(width: 6),
                      Text(
                        'Récords: $u1 ($recTriviaU1 pts)  |  $u2 ($recTriviaU2 pts)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: GarabuTheme.deepEspresso),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => TriviaParejaScreen(pet: widget.pet, couple: widget.couple),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Jugar Trivia en Pareja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE91E63),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Próximamente en pareja
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: GarabuTheme.paperWhite.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: GarabuTheme.warmSand.withValues(alpha: 0.6)),
          ),
          child: const Row(
            children: [
              Icon(Icons.palette_rounded, size: 20, color: GarabuTheme.textSecondary),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Próximamente: "Dibuja y Adivina"',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Uno dibuja una pista en el lienzo y el otro debe adivinarla en tiempo real.',
                      style: TextStyle(fontSize: 11, color: GarabuTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
