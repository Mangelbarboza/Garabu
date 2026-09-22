import 'package:flutter_test/flutter_test.dart';
import 'package:garabu/features/settings/data/audio_settings_provider.dart';
import 'package:garabu/features/auth/data/auth_repository.dart';

void main() {
  group('Settings & Audio Tests', () {
    test('AudioSettingsNotifier inicia con valores por defecto óptimos', () {
      final notifier = AudioSettingsNotifier();
      expect(notifier.state.musicVolume, 0.8);
      expect(notifier.state.soundVolume, 0.9);
      expect(notifier.state.isMusicMuted, false);
      expect(notifier.state.isSoundMuted, false);
      expect(notifier.state.effectiveMusicVolume, 0.8);
      expect(notifier.state.effectiveSoundVolume, 0.9);
    });

    test('AudioSettingsNotifier ajusta volumen y aplica límites [0.0, 1.0]', () {
      final notifier = AudioSettingsNotifier();

      notifier.setMusicVolume(0.45);
      expect(notifier.state.musicVolume, 0.45);
      expect(notifier.state.effectiveMusicVolume, 0.45);

      // Clamp por encima de 1.0
      notifier.setMusicVolume(1.8);
      expect(notifier.state.musicVolume, 1.0);

      // Clamp por debajo de 0.0
      notifier.setSoundVolume(-0.2);
      expect(notifier.state.soundVolume, 0.0);
      expect(notifier.state.isSoundMuted, true);
    });

    test('AudioSettingsNotifier conmuta silenciado (Mute) preservando el nivel fijado', () {
      final notifier = AudioSettingsNotifier();
      notifier.setMusicVolume(0.7);

      notifier.toggleMusicMute();
      expect(notifier.state.isMusicMuted, true);
      expect(notifier.state.effectiveMusicVolume, 0.0);
      expect(notifier.state.musicVolume, 0.7); // Se preserva el nivel para cuando desmutee

      notifier.toggleMusicMute();
      expect(notifier.state.isMusicMuted, false);
      expect(notifier.state.effectiveMusicVolume, 0.7);
    });

    test('AuthRepository deleteAccount limpia la sesión activa', () async {
      final repo = AuthRepository();
      await repo.deleteAccount();
      expect(repo.currentUser, isNull);
    });
  });
}
