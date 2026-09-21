import 'package:flutter/material.dart';
import '../../../core/theme/garabu_theme.dart';
import '../../lobby/domain/couple_model.dart';
import 'body_canvas_screen.dart';

class PetNamingDialog extends StatefulWidget {
  final CoupleModel couple;

  const PetNamingDialog({
    super.key,
    required this.couple,
  });

  @override
  State<PetNamingDialog> createState() => _PetNamingDialogState();
}

class _PetNamingDialogState extends State<PetNamingDialog> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _onConfirm() {
    if (!_formKey.currentState!.validate()) return;
    final petName = _nameController.text.trim();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => BodyCanvasScreen(
          couple: widget.couple,
          petName: petName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GarabuTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: GarabuTheme.paperWhite,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '🐾',
                          style: TextStyle(fontSize: 40),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pongamos nombre a nuestra mascota:',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: GarabuTheme.deepEspresso,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Este nombre los acompañará en su racha diaria.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: GarabuTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: GarabuTheme.deepEspresso,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Ej. Garabito, Pelusa...',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor escribe un nombre';
                        }
                        if (value.trim().length < 2) {
                          return 'Mínimo 2 letras';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _onConfirm(),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: _onConfirm,
                      child: const Text('Continuar a dibujar el cuerpo'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
