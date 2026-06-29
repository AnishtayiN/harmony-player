import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';

class HarmonyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  StreamSubscription? _playbackEventSub;

  HarmonyAudioHandler() {
    _playbackEventSub = _player.playbackEventStream.listen((event) {
      playbackState.add(_transformEvent(event));
    });
  }

  AudioPlayer get player => _player;

  Future<void> loadSong(Song song) async {
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.file(song.path)));
      mediaItem.add(MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        album: song.album,
        duration: song.duration,
        artUri: song.coverUrl != null ? Uri.tryParse(song.coverUrl!) : null,
      ));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> setQueue(List<Song> songs, {int? initialIndex}) async {
    _playlist.children.clear();
    for (final song in songs) {
      _playlist.children.add(AudioSource.uri(Uri.file(song.path), tag: song.id));
    }
    await _player.setAudioSource(_playlist, initialIndex: initialIndex ?? 0);
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    if (_player.hasNext) await _player.seekToNext();
  }

  @override
  Future<void> skipToPrevious() async {
    if (_player.hasPrevious) await _player.seekToPrevious();
  }

  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {
    await _player.setShuffleMode(
      mode == AudioServiceShuffleMode.all ? ShuffleMode.all : ShuffleMode.none,
    );
  }

  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {
    LoopMode loopMode;
    switch (mode) {
      case AudioServiceRepeatMode.one:
        loopMode = LoopMode.one;
        break;
      case AudioServiceRepeatMode.all:
        loopMode = LoopMode.all;
        break;
      default:
        loopMode = LoopMode.off;
    }
    await _player.setLoopMode(loopMode);
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        MediaControl.stop,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  @override
  Future<void> onTaskRemoved() async {
    await _playbackEventSub?.cancel();
    await super.onTaskRemoved();
  }
}
