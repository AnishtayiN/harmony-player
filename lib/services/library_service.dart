import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_media_metadata/flutter_media_metadata.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../models/song.dart';

class LibraryService {
  final Box<Song> _songBox = Hive.box<Song>('songs');
  static final OnAudioQuery? _audioQuery = Platform.isAndroid ? OnAudioQuery() : null;

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final status = await Permission.audio.request();
      final storageStatus = await Permission.storage.request();
      return status.isGranted || storageStatus.isGranted;
    }
    return true;
  }

  Future<List<Song>> scanLibrary() async {
    if (Platform.isAndroid) {
      return _scanAndroid();
    } else if (Platform.isIOS) {
      return _importFromPicker();
    } else {
      return _scanDesktop();
    }
  }

  Future<List<Song>> _scanAndroid() async {
    if (_audioQuery == null) return [];
    
    final hasPermission = await requestPermissions();
    if (!hasPermission) return [];

    try {
      final songs = await _audioQuery!.querySongs(
        sortType: SongSortType.DATE_ADDED,
        orderType: OrderType.DESC_OR_GREATER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      final parsedSongs = <Song>[];
      for (final song in songs) {
        if (song.isMusic && song.duration != null && song.duration! > 0) {
          parsedSongs.add(Song(
            id: song.id.toString(),
            title: song.title,
            artist: song.artist ?? 'Unknown Artist',
            album: song.album ?? 'Unknown Album',
            path: song.data,
            duration: Duration(milliseconds: song.duration!),
          ));
        }
      }

      await _songBox.clear();
      await _songBox.addAll(parsedSongs);
      return parsedSongs;
    } catch (e) {
      debugPrint('[Library] Android scan error: $e');
      return [];
    }
  }

  Future<List<Song>> _scanDesktop() async {
    final musicDirs = <String>[];

    if (Platform.isWindows) {
      final home = Platform.environment['USERPROFILE'];
      if (home != null) musicDirs.add('$home\\Music');
    } else if (Platform.isMacOS || Platform.isLinux) {
      final home = Platform.environment['HOME'];
      if (home != null) musicDirs.add('$home/Music');
    }

    final songs = <Song>[];
    for (final dir in musicDirs) {
      if (await Directory(dir).exists()) {
        songs.addAll(await _scanDirectory(dir));
      }
    }

    await _songBox.clear();
    await _songBox.addAll(songs);
    return songs;
  }

  Future<List<Song>> _scanDirectory(String path) async {
    final songs = <Song>[];
    const extensions = ['.mp3', '.wav', '.aac', '.flac', '.ogg', '.m4a', '.wma'];

    try {
      final dir = Directory(path);
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final ext = entity.path.toLowerCase();
          if (extensions.any((e) => ext.endsWith(e))) {
            try {
              final song = await _parseFile(entity.path);
              if (song != null) songs.add(song);
            } catch (e) {
              debugPrint('[Library] Parse error: ${entity.path}');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[Library] Directory scan error: $e');
    }

    return songs;
  }

  Future<Song?> _parseFile(String path) async {
    try {
      final metadata = await MetadataRetriever.fromFile(File(path));
      final duration = metadata.duration ?? 0;

      if (duration <= 0) return null;

      return Song(
        id: _generateStableId(path),
        title: metadata.title ?? path.split(Platform.pathSeparator).last,
        artist: metadata.artist ?? 'Unknown Artist',
        album: metadata.album ?? 'Unknown Album',
        path: path,
        duration: Duration(milliseconds: duration),
      );
    } catch (e) {
      debugPrint('[Library] Parse error: $e');
      return null;
    }
  }

  String _generateStableId(String path) {
    return path.hashCode.abs().toString();
  }

  Future<List<Song>> _importFromPicker() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a', 'wma'],
        allowMultiple: true,
      );

      if (result == null || result.files.isEmpty) {
        return getCachedSongs();
      }

      final songs = <Song>[];
      for (final file in result.files) {
        if (file.path != null) {
          final song = await _parseFile(file.path!);
          if (song != null) songs.add(song);
        }
      }

      final existing = getCachedSongs();
      final existingPaths = existing.map((s) => s.path).toSet();
      final newSongs = songs.where((s) => !existingPaths.contains(s.path)).toList();

      await _songBox.addAll(newSongs);
      return [...existing, ...newSongs];
    } catch (e) {
      debugPrint('[Library] Import error: $e');
      return getCachedSongs();
    }
  }

  List<Song> getCachedSongs() => _songBox.values.toList();
}
