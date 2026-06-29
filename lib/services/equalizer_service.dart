class EqualizerPreset {
  final String name;
  final List<double> bands; // 10 bands: 31, 62, 125, 250, 500, 1k, 2k, 4k, 8k, 16k Hz

  EqualizerPreset({required this.name, required this.bands});
}

class EqualizerService {
  static final List<EqualizerPreset> presets = [
    EqualizerPreset(
      name: 'Flat',
      bands: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
    ),
    EqualizerPreset(
      name: 'Bass Boost',
      bands: [6, 5, 4, 2, 0, 0, 0, 0, 0, 0],
    ),
    EqualizerPreset(
      name: 'Treble Boost',
      bands: [0, 0, 0, 0, 0, 0, 2, 4, 5, 6],
    ),
    EqualizerPreset(
      name: 'Vocal',
      bands: [-2, -1, 0, 2, 4, 4, 3, 2, 0, -1],
    ),
    EqualizerPreset(
      name: 'Rock',
      bands: [5, 4, 2, 0, -1, 0, 2, 3, 4, 5],
    ),
    EqualizerPreset(
      name: 'Pop',
      bands: [-1, 1, 3, 4, 3, 1, 0, -1, -1, -1],
    ),
    EqualizerPreset(
      name: 'Jazz',
      bands: [3, 2, 0, 1, -1, -1, 0, 1, 2, 3],
    ),
    EqualizerPreset(
      name: 'Classical',
      bands: [4, 3, 2, 1, -1, -1, 0, 2, 3, 4],
    ),
  ];

  EqualizerPreset _currentPreset = presets[0];
  List<double> _customBands = List.filled(10, 0);
  bool _isEnabled = false;

  EqualizerPreset get currentPreset => _currentPreset;
  List<double> get bands => _isEnabled ? _customBands : List.filled(10, 0);
  bool get isEnabled => _isEnabled;

  void setPreset(EqualizerPreset preset) {
    _currentPreset = preset;
    _customBands = List.from(preset.bands);
    _isEnabled = true;
  }

  void setBand(int index, double value) {
    if (index >= 0 && index < 10) {
      _customBands[index] = value.clamp(-12.0, 12.0);
      _isEnabled = true;
    }
  }

  void toggle() {
    _isEnabled = !_isEnabled;
  }

  void reset() {
    _currentPreset = presets[0];
    _customBands = List.filled(10, 0);
    _isEnabled = false;
  }
}
