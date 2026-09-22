import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/garabu_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../lobby/domain/couple_model.dart';
import '../../pet/domain/pet_model.dart';
import '../data/audio_settings_provider.dart';

class SettingsBottomSheet extends ConsumerWidget {
  final CoupleModel? couple;
  final PetModel? pet;

  const SettingsBottomSheet({
    super.key,
    this.couple,
    this.pet,
  });

  static void show({
    required BuildContext context,
    CoupleModel? couple,
    PetModel? pet,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SettingsBottomSheet(couple: couple, pet: pet),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioSettings = ref.watch(audioSettingsProvider);
    final audioNotifier = ref.read(audioSettingsProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);

    // Calcular el nombre de la pareja para el botón de custodia
    final partnerName = _resolvePartnerName(currentUser?.id, couple);

    return Container(
      decoration: const BoxDecoration(
        color: GarabuTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tirador superior (Drag handle)
            Center(
              child: Container(
                width: 44,
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
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: GarabuTheme.warmSand.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.settings_rounded,
                    color: GarabuTheme.primaryBrown,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ajustes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: GarabuTheme.deepEspresso,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Música, sonido, pareja y cuenta',
                        style: TextStyle(
                          fontSize: 12,
                          color: GarabuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: GarabuTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ==========================================
            // SECCIÓN 1: VOLUMEN DE MÚSICA Y SONIDO
            // ==========================================
            _buildSectionHeader(
              icon: Icons.volume_up_rounded,
              title: 'Volumen y Sonido',
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: GarabuTheme.paperWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GarabuTheme.warmSand.withValues(alpha: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Control de Música
                  _buildVolumeRow(
                    label: 'Música de fondo',
                    icon: audioSettings.isMusicMuted || audioSettings.effectiveMusicVolume == 0
                        ? Icons.music_off_rounded
                        : Icons.music_note_rounded,
                    volume: audioSettings.effectiveMusicVolume,
                    isMuted: audioSettings.isMusicMuted,
                    onToggleMute: () => audioNotifier.toggleMusicMute(),
                    onChanged: (val) => audioNotifier.setMusicVolume(val),
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(color: GarabuTheme.warmSand, height: 1),
                  ),

                  // Control de Efectos de Sonido
                  _buildVolumeRow(
                    label: 'Efectos de sonido',
                    icon: audioSettings.isSoundMuted || audioSettings.effectiveSoundVolume == 0
                        ? Icons.volume_off_rounded
                        : Icons.volume_up_rounded,
                    volume: audioSettings.effectiveSoundVolume,
                    isMuted: audioSettings.isSoundMuted,
                    onToggleMute: () => audioNotifier.toggleSoundMute(),
                    onChanged: (val) => audioNotifier.setSoundVolume(val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // SECCIÓN 2: PAREJA & CUSTODIA
            // ==========================================
            _buildSectionHeader(
              icon: Icons.favorite_border_rounded,
              title: 'Gestión de Pareja',
            ),
            const SizedBox(height: 8),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: GarabuTheme.paperWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFFB74D),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF9800).withValues(alpha: 0.05),
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
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF3E0),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.handshake_rounded,
                          color: Color(0xFFF57C00),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Custodia de $partnerName',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: GarabuTheme.deepEspresso,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Gestión de acuerdos o tenencia en caso de separación.',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: GarabuTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showCustodyDialog(context, partnerName),
                      icon: const Icon(Icons.info_outline_rounded, size: 18),
                      label: Text(
                        'Custodia de $partnerName',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFE65100),
                        side: const BorderSide(color: Color(0xFFFFB74D), width: 1.5),
                        backgroundColor: const Color(0xFFFFF8E1).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ==========================================
            // SECCIÓN 3: CUENTA Y SEGURIDAD
            // ==========================================
            _buildSectionHeader(
              icon: Icons.shield_outlined,
              title: 'Cuenta y Seguridad',
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: GarabuTheme.paperWhite,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: GarabuTheme.warmSand.withValues(alpha: 0.8)),
              ),
              child: Column(
                children: [
                  // Botón Cerrar Sesión
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showSignOutConfirmDialog(context, ref),
                      icon: const Icon(Icons.logout_rounded, size: 19),
                      label: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: GarabuTheme.primaryBrown,
                        side: const BorderSide(color: GarabuTheme.primaryBrown, width: 1.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Botón Eliminar Cuenta
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showDeleteAccountConfirmDialog(context, ref),
                      icon: const Icon(Icons.delete_forever_rounded, size: 19),
                      label: const Text(
                        'Eliminar Cuenta',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPERS VISUALES ---

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: GarabuTheme.primaryBrown),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: GarabuTheme.deepEspresso,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildVolumeRow({
    required String label,
    required IconData icon,
    required double volume,
    required bool isMuted,
    required VoidCallback onToggleMute,
    required ValueChanged<double> onChanged,
  }) {
    final percentage = (volume * 100).round();

    return Column(
      children: [
        Row(
          children: [
            InkWell(
              onTap: onToggleMute,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  icon,
                  size: 20,
                  color: isMuted ? GarabuTheme.textSecondary : GarabuTheme.primaryBrown,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: GarabuTheme.deepEspresso,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isMuted
                    ? GarabuTheme.warmSand.withValues(alpha: 0.4)
                    : GarabuTheme.primaryBrown.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isMuted ? 'Silenciado' : '$percentage%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isMuted ? GarabuTheme.textSecondary : GarabuTheme.primaryBrown,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: GarabuTheme.primaryBrown,
            inactiveTrackColor: GarabuTheme.warmSand.withValues(alpha: 0.5),
            thumbColor: GarabuTheme.primaryBrown,
            overlayColor: GarabuTheme.primaryBrown.withValues(alpha: 0.15),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: Slider(
            value: volume,
            min: 0.0,
            max: 1.0,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  String _resolvePartnerName(String? currentUserId, CoupleModel? couple) {
    if (couple == null) return 'la pareja';
    if (currentUserId != null && currentUserId == couple.user1Id) {
      return (couple.user2Name != null && couple.user2Name!.isNotEmpty)
          ? couple.user2Name!
          : 'la pareja';
    } else {
      return couple.user1Name.isNotEmpty ? couple.user1Name : 'la pareja';
    }
  }

  // --- DIÁLOGOS DE CONFIRMACIÓN E INFORMACIÓN ---

  void _showCustodyDialog(BuildContext context, String partnerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.handshake_rounded, color: Color(0xFFF57C00), size: 26),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Custodia de $partnerName',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: GarabuTheme.deepEspresso,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta función está diseñada para acompañar a las parejas en caso de distanciamiento o separación.',
              style: TextStyle(fontSize: 13.5, color: GarabuTheme.deepEspresso, height: 1.4),
            ),
            const SizedBox(height: 10),
            const Text(
              'Próximamente podrán acordar un régimen de visitas compartidas para Garabu, '
              'definir la tenencia temporal o transferir la tutela completa de forma respetuosa y sin perder sus dibujos ni recuerdos.',
              style: TextStyle(fontSize: 13, color: GarabuTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8E1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFFE082)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock_rounded, color: Color(0xFFE65100), size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Opción reservada. La lógica de custodia se activará en la siguiente actualización.',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBF360C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: GarabuTheme.primaryBrown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Entendido', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: GarabuTheme.primaryBrown, size: 24),
            SizedBox(width: 8),
            Text(
              '¿Cerrar Sesión?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GarabuTheme.deepEspresso),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas cerrar tu sesión? '
          'Tendrás que volver a iniciar sesión con tu cuenta para cuidar de Garabu.',
          style: TextStyle(fontSize: 13.5, color: GarabuTheme.deepEspresso, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: GarabuTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // cerrar bottom sheet
              await ref.read(authRepositoryProvider).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: GarabuTheme.primaryBrown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD32F2F), size: 26),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '¿Eliminar Cuenta?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFD32F2F)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Esta acción es IRREVERSIBLE. Se eliminará tu perfil de usuario y perderás de manera permanente el acceso a Garabu y a tus datos.',
              style: TextStyle(fontSize: 13.5, color: GarabuTheme.deepEspresso, height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBEE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.error_outline_rounded, color: Color(0xFFD32F2F), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No podrás recuperar tu mascota ni tus artículos comprados.',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFC62828)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: GarabuTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop(); // cerrar bottom sheet
              await ref.read(authRepositoryProvider).deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Eliminar Mi Cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
