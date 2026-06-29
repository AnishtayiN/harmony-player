import 'package:hive/hive.dart';
import 'song.dart';

part 'playlist.g.dart';

@HiveType(typeId: 1)
class Playlist extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  List<String> songIds;

  @HiveField(3)
  DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    List<String>? songIds,
    DateTime? createdAt,
  })  : songIds = songIds ?? [],
        createdAt = createdAt ?? DateTime.now();

  void addSong(Song song) {
    if (!songIds.contains(song.id)) {
      songIds.add(song.id);
      save();
    }
  }

  void removeSong(Song song) {
    songIds.remove(song.id);
    save();
  }
}
