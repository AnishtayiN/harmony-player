import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../models/song.dart';
import '../services/audio_service.dart';
import '../services/library_service.dart';

enum PlayerStatus { idle, loading, playing, paused }

class PlayerState {
  final PlayerStatus status;
  final Song? currentSong;
  final Duration position;
  final Duration duration;
  final List<Song> queue;
  final int queueIndex;
  final bool isShuffled;
  final LoopMode loopMode;

  const PlayerState({
    this.status = PlayerStatus.idle,
    this.currentSong,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.queue = const [],
    this.queueIndex = 0,
    this.isShuffled = false,
    this.loopMode = LoopMode.off,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    Song? currentSong,
    Duration? position,
    Duration? duration,
    List<Song>? queue,
    int? queueIndex,
    bool? isShuffled,
    LoopMode? loopMode,
  }) {
    return PlayerState(
      status: status ?? this.status,
      currentSong: currentSong ?? this.currentSong,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      queue: queue ?? this.queue,
      queueIndex: queueIndex ?? this.queueIndex,
      isShuffled: isShuffled ?? this.isShuffled,
      loopMode: loopMode ?? this.loopMode,
    );
  }
}

class PlayerController extends StateNotifier<PlayerState> {
  final HarmonyAudioHandler _audioHandler;
  final AudioPlayer _player = AudioPlayer();
  final List<StreamSubscription> _subscriptions = [];

  PlayerController(this._audioHandler) : super(const PlayerState()) {
    _initStreams();
  }

  AudioPlayer get player => _player;

  void _initStreams() {
    _subscriptions.add(_player.positionStream.listen((p) {
      state = state.copyWith(position: p);
    }));

    _subscriptions.add(_player.durationStream.listen((d) {
      if (d != null) {
        state = state.copyWith(duration: d);
      }
    }));

    _subscriptions.add(_player.playerStateStream.listen((s) {
      PlayerStatus newStatus;
      if (s.processing == ProcessingState.completed) {
        newStatus = PlayerStatus.idle;
      } else if (s.processing == ProcessingState.loading ||
          s.processing == ProcessingState.buffering) {
        newStatus = PlayerStatus.loading;
      } else {
        newStatus = s.playing ? PlayerStatus.playing : PlayerStatus.paused;
      }
      state = state.copyWith(status: newStatus);
    }));

    _subscriptions.add(_player.currentIndexStream.listen((index) {
      if (index != null && index < state.queue.length) {
        state = state.copyWith(
          queueIndex: index,
          currentSong: state.queue[index],
        );
      }
    }));
  }

  Future<void> playSong(Song song) async {
    try {
      state = state.copyWith(
        status: PlayerStatus.loading,
        currentSong: song,
        queue: [song],
        queueIndex: 0,
      );
      await _audioHandler.loadSong(song);
      await _audioHandler.play();
    } catch (e) {
      debugPrint('[Player] playSong error: $e');
      state = state.copyWith(status: PlayerStatus.idle);
    }
  }

  Future<void> playQueue(List<Song> songs, int startIndex) async {
    if (songs.isEmpty) return;
    try {
      final safeIndex = startIndex.clamp(0, songs.length - 1);
      state = state.copyWith(
        status: PlayerStatus.loading,
        queue: List.from(songs),
        queueIndex: safeIndex,
        currentSong: songs[safeIndex],
      );
      await _audioHandler.setQueue(songs);
      await _player.seek(Duration.zero, index: safeIndex);
      await _audioHandler.play();
    } catch (e) {
      debugPrint('[Player] playQueue error: $e');
      state = state.copyWith(status: PlayerStatus.idle);
    }
  }

  Future<void> play() async {
    await _audioHandler.play();
  }

  Future<void> pause() async {
    await _audioHandler.pause();
  }

  Future<void> toggle() async {
    if (state.status == PlayerStatus.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> next() async {
    if (state.queueIndex < state.queue.length - 1) {
      await _audioHandler.skipToNext();
    } else if (state.loopMode == LoopMode.all && state.queue.isNotEmpty) {
      await _player.seek(Duration.zero, index: 0);
    }
  }

  Future<void> previous() async {
    if (state.position.inSeconds > 3) {
      await seek(Duration.zero);
    } else if (state.queueIndex > 0) {
      await _audioHandler.skipToPrevious();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> toggleShuffle() async {
    final newShuffle = !state.isShuffled;
    state = state.copyWith(isShuffled: newShuffle);
    await _audioHandler.setShuffleMode(
      newShuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
  }

  Future<void> cycleRepeat() async {
    LoopMode newMode;
    switch (state.loopMode) {
      case LoopMode.off:
        newMode = LoopMode.all;
        break;
      case LoopMode.all:
        newMode = LoopMode.one;
        break;
      case LoopMode.one:
        newMode = LoopMode.off;
        break;
    }
    state = state.copyWith(loopMode: newMode);
    await _audioHandler.setRepeatMode(
      newMode == LoopMode.one
          ? AudioServiceRepeatMode.one
          : newMode == LoopMode.all
              ? AudioServiceRepeatMode.all
              : AudioServiceRepeatMode.none,
    );
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final newQueue = List<Song>.from(state.queue);
    final item = newQueue.removeAt(oldIndex);
    newQueue.insert(newIndex, item);

    int newQueueIndex = state.queueIndex;
    if (oldIndex == state.queueIndex) {
      newQueueIndex = newIndex;
    } else if (oldIndex < state.queueIndex && newIndex >= state.queueIndex) {
      newQueueIndex--;
    } else if (oldIndex > state.queueIndex && newIndex <= state.queueIndex) {
      newQueueIndex++;
    }

    state = state.copyWith(queue: newQueue, queueIndex: newQueueIndex);
    _audioHandler.setQueue(newQueue);
  }

  void removeFromQueue(int index) {
    if (index < 0 || index >= state.queue.length) return;
    final newQueue = List<Song>.from(state.queue)..removeAt(index);
    int newQueueIndex = state.queueIndex;
    if (index < state.queueIndex) {
      newQueueIndex--;
    } else if (index == state.queueIndex && newQueue.isNotEmpty) {
      newQueueIndex = newQueueIndex.clamp(0, newQueue.length - 1);
    }
    state = state.copyWith(queue: newQueue, queueIndex: newQueueIndex);
    _audioHandler.setQueue(newQueue);
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _player.dispose();
    super.dispose();
  }
}

final audioHandlerProvider = Provider<HarmonyAudioHandler>((ref) {
  return HarmonyAudioHandler();
});

final playerProvider =
    StateNotifierProvider<PlayerController, PlayerState>((ref) {
  return PlayerController(ref.watch(audioHandlerProvider));
});

final libraryProvider = Provider<LibraryService>((ref) => LibraryService());
