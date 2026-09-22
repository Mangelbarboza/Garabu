import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../pet/data/pet_repository.dart';
import '../../../pet/domain/pet_model.dart';

class LanguageBottomSheet extends ConsumerStatefulWidget {
  final PetModel pet;

  const LanguageBottomSheet({
    super.key,
    required this.pet,
  });

  static void show(BuildContext context, PetModel pet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LanguageBottomSheet(pet: pet),
    );
  }

  @override
  ConsumerState<LanguageBottomSheet> createState() => _LanguageBottomSheetState();
}

class _LanguageBottomSheetState extends ConsumerState<LanguageBottomSheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _addPhrase() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final petRepo = ref.read(petRepositoryProvider);
    await petRepo.addCustomPhrase(petId: widget.pet.id, phrase: text);
    _textController.clear();
    _focusNode.unfocus();
    setState(() {});
  }

  Future<void> _removePhrase(String phrase) async {
    final petRepo = ref.read(petRepositoryProvider);
    await petRepo.removeCustomPhrase(petId: widget.pet.id, phrase: phrase);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final petAsync = ref.watch(currentPetProvider(widget.pet.id));
    final pet = petAsync.value ?? widget.pet;
    final phrases = pet.customPhrases;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.82,
      ),
      decoration: const BoxDecoration(
        color: GarabuTheme.cardSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: GarabuTheme.primaryBrown.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.record_voice_over_rounded,
                      color: GarabuTheme.primaryBrown,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Enseñar lenguaje a ${pet.name}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: GarabuTheme.deepEspresso,
                        ),
                      ),
                      const Text(
                        'Frases que dirá al comer o ser acariciado',
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

          // Campo de texto para agregar nueva frase
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: GarabuTheme.paperWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: GarabuTheme.warmSand),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    maxLength: 100,
                    style: const TextStyle(fontSize: 13.5, color: GarabuTheme.deepEspresso),
                    decoration: const InputDecoration(
                      hintText: 'Escribe una frase tierna...',
                      hintStyle: TextStyle(fontSize: 13, color: GarabuTheme.textSecondary),
                      border: InputBorder.none,
                      counterText: '',
                    ),
                    onSubmitted: (_) => _addPhrase(),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _textController,
                  builder: (context, value, _) {
                    return Text(
                      '${value.text.length}/100',
                      style: TextStyle(
                        fontSize: 11,
                        color: value.text.length > 90
                            ? Colors.red
                            : GarabuTheme.textSecondary.withValues(alpha: 0.7),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add_circle_rounded, color: GarabuTheme.primaryBrown, size: 26),
                  onPressed: _addPhrase,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista de frases enseñadas
          Expanded(
            child: phrases.isEmpty
                ? Center(
                    child: Text(
                      'Aún no le has enseñado frases.\n¡Escribe una arriba!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: GarabuTheme.textSecondary.withValues(alpha: 0.7)),
                    ),
                  )
                : ListView.separated(
                    itemCount: phrases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final phrase = phrases[index];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: GarabuTheme.paperWhite,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: GarabuTheme.warmSand.withValues(alpha: 0.7)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: GarabuTheme.primaryBrown),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                phrase,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: GarabuTheme.deepEspresso,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                              onPressed: () => _removePhrase(phrase),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
