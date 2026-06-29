import 'package:hive/hive.dart';

class StorageService {
  static const _settingsBox = 'settings';

  Box get _box => Hive.box(_settingsBox);

  Future<void> setLastPlayedSongId(String? id) => _box.put('last_song', id);
  
  String? get lastPlayedSongId {
    try {
      return _box.get('last_song') as String?;
    } catch (e) {
      return null;
    }
  }

  Future<void> setShuffleEnabled(bool value) => _box.put('shuffle', value);
  
  bool get shuffleEnabled {
    try {
      return _box.get('shuffle', defaultValue: false) as bool;
    } catch (e) {
      return false;
    }
  }

  Future<void> setRepeatMode(int mode) => _box.put('repeat_mode', mode);
  
  int get repeatMode {
    try {
      return _box.get('repeat_mode', defaultValue: 0) as int;
    } catch (e) {
      return 0;
    }
  }

  Future<void> setLastUpdateCheck(DateTime dt) =>
      _box.put('last_update_check', dt.toIso8601String());

  DateTime? get lastUpdateCheck {
    try {
      final str = _box.get('last_update_check') as String?;
      return str != null ? DateTime.tryParse(str) : null;
    } catch (e) {
      return null;
    }
  }
}
