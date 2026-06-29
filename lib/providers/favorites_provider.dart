import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/favorite_song.dart';
import '../models/song.dart';

class FavoritesController extends StateNotifier<List<String>> {
  final Box<FavoriteSong>? _box;

  FavoritesController(this._box)
      : super(_box?.values.map((f) => f.songId).toList() ?? []);

  bool isFavorite(String songId) => state.contains(songId);

  Future<void> toggle(Song song) async {
    if (_box == null) return;
    
    if (state.contains(song.id)) {
      await _box.delete(song.id);
      state = state.where((id) => id != song.id).toList();
    } else {
      final fav = FavoriteSong(songId: song.id);
      await _box.put(song.id, fav);
      state = [song.id, ...state];
    }
  }

  Future<void> clear() async {
    if (_box == null) return;
    await _box.clear();
    state = [];
  }
}

final favoritesBoxProvider = Provider<Box<FavoriteSong>>((ref) {
  return Hive.box<FavoriteSong>('favorites');
});

final favoritesProvider =
    StateNotifierProvider<FavoritesController, List<String>>((ref) {
  return FavoritesController(ref.watch(favoritesBoxProvider));
});
