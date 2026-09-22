import 'package:flutter_riverpod/flutter_riverpod.dart';

class AudioSettingsState {
  final double musicVolume; // 0.0 a 1.0
  final double soundVolume; // 0.0 a 1.0
  final bool isMusicMuted;
  final bool isSoundMuted;

  const AudioSettingsState({
    this.musicVolume = 0.8,
    this.soundVolume = 0.9,
    this.isMusicMuted = false,
    this.isSoundMuted = false,
  });

  double get effectiveMusicVolume => isMusicMuted ? 0.0 : musicVolume;
  double get effectiveSoundVolume => isSoundMuted ? 0.0 : soundVolume;

  AudioSettingsState copyWith({
    double? musicVolume,
    double? soundVolume,
    bool? isMusicMuted,
    bool? isSoundMuted,
  }) {
    return AudioSettingsState(
      musicVolume: musicVolume ?? this.musicVolume,
      soundVolume: soundVolume ?? this.soundVolume,
      isMusicMuted: isMusicMuted ?? this.isMusicMuted,
      isSoundMuted: isSoundMuted ?? this.isSoundMuted,
    );
  }
}

class AudioSettingsNotifier extends StateNotifier<AudioSettingsState> {
  AudioSettingsNotifier() : super(const AudioSettingsState());

  void setMusicVolume(double volume) {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(
      musicVolume: clamped,
      isMusicMuted: clamped == 0.0,
    );
  }

  void setSoundVolume(double volume) {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(
      soundVolume: clamped,
      isSoundMuted: clamped == 0.0,
    );
  }

  void toggleMusicMute() {
    state = state.copyWith(isMusicMuted: !state.isMusicMuted);
  }

  void toggleSoundMute() {
    state = state.copyWith(isSoundMuted: !state.isSoundMuted);
  }
}

final audioSettingsProvider =
    StateNotifierProvider<AudioSettingsNotifier, AudioSettingsState>((ref) {
  return AudioSettingsNotifier();
});
