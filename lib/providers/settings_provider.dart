import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class SettingsController extends StateNotifier<SettingsState> {
  final Box _box;

  SettingsController(this._box)
      : super(SettingsState(
          themeMode: _getThemeMode(_box),
          autoUpdateEnabled: _box.get('auto_update', defaultValue: true) as bool,
          visualizerEnabled: _box.get('visualizer', defaultValue: true) as bool,
          playbackSpeed:
              (_box.get('playback_speed', defaultValue: 1.0) as num).toDouble(),
        ));

  static ThemeMode _getThemeMode(Box box) {
    final index = box.get('theme_mode', defaultValue: 0) as int;
    if (index >= 0 && index < ThemeMode.values.length) {
      return ThemeMode.values[index];
    }
    return ThemeMode.system;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _box.put('theme_mode', mode.index);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setAutoUpdate(bool value) async {
    await _box.put('auto_update', value);
    state = state.copyWith(autoUpdateEnabled: value);
  }

  Future<void> setVisualizer(bool value) async {
    await _box.put('visualizer', value);
    state = state.copyWith(visualizerEnabled: value);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _box.put('playback_speed', speed);
    state = state.copyWith(playbackSpeed: speed);
  }
}

class SettingsState {
  final ThemeMode themeMode;
  final bool autoUpdateEnabled;
  final bool visualizerEnabled;
  final double playbackSpeed;

  SettingsState({
    required this.themeMode,
    required this.autoUpdateEnabled,
    required this.visualizerEnabled,
    required this.playbackSpeed,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? autoUpdateEnabled,
    bool? visualizerEnabled,
    double? playbackSpeed,
  }) {
    return SettingsState(
      themeMode: themeMode ?? this.themeMode,
      autoUpdateEnabled: autoUpdateEnabled ?? this.autoUpdateEnabled,
      visualizerEnabled: visualizerEnabled ?? this.visualizerEnabled,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsController, SettingsState>((ref) {
  return SettingsController(Hive.box('settings'));
});
