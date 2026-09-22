import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/garabu_theme.dart';
import '../../auth/data/auth_repository.dart';
import '../../canvas/presentation/clothes_canvas_screen.dart';
import '../../canvas/presentation/pet_naming_dialog.dart';
import '../data/lobby_repository.dart';
import '../domain/couple_model.dart';
import '../../settings/presentation/settings_bottom_sheet.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  const LobbyScreen({super.key});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  int _selectedOption = 0; // 0 = Invitar persona, 1 = Ingresar código
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  CoupleModel? _createdCouple;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _generateInvite() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lobbyRepo = ref.read(lobbyRepositoryProvider);
      final couple = await lobbyRepo.createCoupleInvite(
        user1Id: user.id,
        user1Name: user.name,
      );
      setState(() {
        _createdCouple = couple;
      });
      try {
        await ref.read(authRepositoryProvider).updateUserCoupleId(user.id, couple.id);
      } catch (e) {
        debugPrint('Error silencioso en updateUserCoupleId: $e');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinWithCode() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() {
        _errorMessage = 'El código debe tener 6 dígitos.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lobbyRepo = ref.read(lobbyRepositoryProvider);
      final couple = await lobbyRepo.joinWithCode(
        code: code,
        user2Id: user.id,
        user2Name: user.name,
      );
      try {
        await ref.read(authRepositoryProvider).updateUserCoupleId(user.id, couple.id);
      } catch (e) {
        debugPrint('Error silencioso en updateUserCoupleId: $e');
      }

      if (mounted) {
        // Usuario 2 se dirige a la pantalla de espera y lienzo de prendas
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ClothesCanvasScreen(couple: couple),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception:', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si ya creamos un código, escuchamos las actualizaciones en tiempo real
    if (_createdCouple != null) {
      ref.listen<AsyncValue<CoupleModel?>>(
        currentCoupleProvider(_createdCouple!.id),
        (previous, next) {
          final updated = next.value;
          if (updated != null && updated.status == 'drawing_body' && mounted) {
            // Usuario 2 ya ingresó el código. Procedemos al nombramiento y dibujo del cuerpo (Usuario 1)
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PetNamingDialog(couple: updated),
              ),
            );
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: GarabuTheme.background,
      appBar: AppBar(
        title: const Text('Comenzar en Pareja'),
        actions: [
          IconButton(
            tooltip: 'Ajustes',
            icon: const Icon(Icons.settings_rounded, color: GarabuTheme.primaryBrown),
            onPressed: () => SettingsBottomSheet.show(
              context: context,
              couple: _createdCouple,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Selector de Pestañas / Opciones
                  Container(
                    decoration: BoxDecoration(
                      color: GarabuTheme.paperWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GarabuTheme.warmSand),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedOption = 0),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedOption == 0
                                    ? GarabuTheme.primaryBrown
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Nueva mascota',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedOption == 0
                                      ? Colors.white
                                      : GarabuTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedOption = 1),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedOption == 1
                                    ? GarabuTheme.primaryBrown
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Ingresar código',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _selectedOption == 1
                                      ? Colors.white
                                      : GarabuTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8E8),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFF8B4B4)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFF9B1C1C), fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Contenido de Opción 1: Invitar persona
                  if (_selectedOption == 0) ...[
                    if (_createdCouple == null) ...[
                      const Text(
                        'Crea una sala compartida para diseñar su primer garabato juntos.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: GarabuTheme.textSecondary,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),
                      ElevatedButton.icon(
                        onPressed: _isLoading ? null : _generateInvite,
                        icon: const Icon(Icons.group_add_outlined),
                        label: _isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Nueva mascota (Invitar persona)'),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: GarabuTheme.warmSand),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Comparte este código con tu pareja:',
                              style: TextStyle(
                                fontSize: 14,
                                color: GarabuTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: GarabuTheme.paperWhite,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: GarabuTheme.primaryBrown.withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _createdCouple!.inviteCode,
                                    style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4.0,
                                      color: GarabuTheme.deepEspresso,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    tooltip: 'Copiar código',
                                    icon: const Icon(Icons.copy_rounded, color: GarabuTheme.primaryBrown),
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: _createdCouple!.inviteCode));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('¡Código copiado al portapapeles!')),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: GarabuTheme.primaryBrown,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Esperando a que tu pareja ingrese...',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: GarabuTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ] else ...[
                    // Contenido de Opción 2: Ingresar código
                    const Text(
                      'Ingresa el código de 6 dígitos que te compartió tu pareja:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: GarabuTheme.textSecondary,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codeController,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        color: GarabuTheme.deepEspresso,
                      ),
                      decoration: const InputDecoration(
                        counterText: '',
                        hintText: '000000',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _joinWithCode,
                      child: _isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Vincularnos'),
                    ),
                  ],

                  const SizedBox(height: 48),

                  // Texto estático de Tip requerido
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: GarabuTheme.paperWhite,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: GarabuTheme.warmSand),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('💡', style: TextStyle(fontSize: 18)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tip: Se recomienda crear a su mascota juntos en persona o por llamada.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: GarabuTheme.textSecondary,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
