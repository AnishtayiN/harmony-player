import 'package:hive/hive.dart';

part 'favorite_song.g.dart';

@HiveType(typeId: 2)
class FavoriteSong extends HiveObject {
  @HiveField(0)
  String songId;

  @HiveField(1)
  DateTime addedAt;

  FavoriteSong({
    required this.songId,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();
}
