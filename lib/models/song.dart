import 'package:hive/hive.dart';

part 'song.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String artist;

  @HiveField(3)
  String album;

  @HiveField(4)
  String path;

  @HiveField(5)
  Duration duration;

  @HiveField(6)
  String? coverUrl;

  @HiveField(7)
  DateTime addedAt;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.path,
    required this.duration,
    this.coverUrl,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  factory Song.fromMap(Map<String, dynamic> map) => Song(
        id: map['id']?.toString() ?? '',
        title: map['title'] as String? ?? 'Unknown',
        artist: map['artist'] as String? ?? 'Unknown Artist',
        album: map['album'] as String? ?? 'Unknown Album',
        path: map['path'] as String? ?? '',
        duration: Duration(milliseconds: map['duration'] as int? ?? 0),
        coverUrl: map['coverUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'artist': artist,
        'album': album,
        'path': path,
        'duration': duration.inMilliseconds,
        'coverUrl': coverUrl,
      };
}
