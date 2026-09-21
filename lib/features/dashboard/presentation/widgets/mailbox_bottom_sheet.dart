import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/garabu_theme.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../lobby/domain/couple_model.dart';
import '../../../mailbox/data/mailbox_repository.dart';

class MailboxBottomSheet extends ConsumerWidget {
  final CoupleModel couple;

  const MailboxBottomSheet({
    super.key,
    required this.couple,
  });

  static void show(BuildContext context, CoupleModel couple) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MailboxBottomSheet(couple: couple),
    );
  }

  void _openWriteLetterDialog(BuildContext context, WidgetRef ref) {
    final currentUser = ref.read(currentUserProvider);
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: GarabuTheme.cardSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.mark_email_unread_outlined, color: GarabuTheme.primaryBrown),
            SizedBox(width: 8),
            Text(
              'Escribir Carta',
              style: TextStyle(
                color: GarabuTheme.deepEspresso,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Escríbele una nota especial a tu pareja:',
              style: TextStyle(color: GarabuTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: GarabuTheme.paperWhite,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GarabuTheme.warmSand),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: TextField(
                controller: textController,
                maxLines: 5,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Querido amor...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: GarabuTheme.textSecondary)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Enviar carta'),
            onPressed: () async {
              final content = textController.text.trim();
              if (content.isEmpty) return;

              final mailboxRepo = ref.read(mailboxRepositoryProvider);
              await mailboxRepo.sendLetter(
                coupleId: couple.id,
                senderId: currentUser?.id ?? 'user',
                senderName: currentUser?.name ?? 'Tu pareja',
                content: content,
              );

              if (context.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Carta depositada en el buzón!'),
                    backgroundColor: GarabuTheme.primaryBrown,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lettersAsync = ref.watch(lettersProvider(couple.id));
    final currentUser = ref.watch(currentUserProvider);

    return Container(
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
          // Agarre
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
          const SizedBox(height: 16),

          // Título y Botón de Redactar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buzón de Cartas',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: GarabuTheme.deepEspresso,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Notas y mensajes privados entre ustedes',
                    style: TextStyle(
                      fontSize: 13,
                      color: GarabuTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: const Text('Escribir', style: TextStyle(fontSize: 13)),
                onPressed: () => _openWriteLetterDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Lista de Cartas
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 380),
            child: lettersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: GarabuTheme.primaryBrown),
              ),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (letters) {
                if (letters.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: GarabuTheme.paperWhite,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: GarabuTheme.warmSand),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline_rounded, size: 40, color: GarabuTheme.primaryBrown),
                        SizedBox(height: 12),
                        Text(
                          'El buzón está vacío',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: GarabuTheme.deepEspresso,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '¡Sé la primera persona en dejarle una carta de amor a tu pareja!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: GarabuTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: letters.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final letter = letters[index];
                    final isMyLetter = letter.senderId == currentUser?.id;

                    return InkWell(
                      onTap: () {
                        if (!letter.isRead && !isMyLetter) {
                          ref.read(mailboxRepositoryProvider).markAsRead(
                                coupleId: couple.id,
                                letterId: letter.id,
                              );
                        }
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: (!letter.isRead && !isMyLetter)
                              ? const Color(0xFFFFF8E1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: (!letter.isRead && !isMyLetter)
                                ? const Color(0xFFFFD54F)
                                : GarabuTheme.warmSand,
                            width: (!letter.isRead && !isMyLetter) ? 1.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      isMyLetter ? Icons.outgoing_mail : Icons.mail_outline_rounded,
                                      size: 16,
                                      color: GarabuTheme.primaryBrown,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isMyLetter ? 'De ti' : 'De ${letter.senderName}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: GarabuTheme.deepEspresso,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${letter.createdAt.day}/${letter.createdAt.month} ${letter.createdAt.hour.toString().padLeft(2, '0')}:${letter.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: GarabuTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              letter.content,
                              style: const TextStyle(
                                fontSize: 14,
                                color: GarabuTheme.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
