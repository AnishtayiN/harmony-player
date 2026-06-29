import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import '../../../models/song.dart';
import '../../../providers/player_provider.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../services/sleep_timer_service.dart';
import '../../../widgets/animated_gradient.dart';
import '../../../widgets/album_art_widget.dart';
import '../../visualizer/widgets/audio_visualizer.dart';
import 'queue_screen.dart';
import 'equalizer_screen.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final SleepTimerService _sleepTimer = SleepTimerService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _sleepTimer.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    if (d == Duration.zero) return '0:00';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  void _showSleepTimerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sleep Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_sleepTimer.isActive) ...[
              StreamBuilder<Duration?>(
                stream: _sleepTimer.remainingStream,
                initialData: _sleepTimer.remaining,
                builder: (c, snap) {
                  final rem = snap.data;
                  return Text(
                    rem == null ? 'Not set' : 'Time remaining: ${_fmt(rem)}',
                    style: const TextStyle(fontSize: 16),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
            ...[15, 30, 45, 60, 90].map((minutes) => ListTile(
                  title: Text('$minutes minutes'),
                  onTap: () {
                    _sleepTimer.start(
                      Duration(minutes: minutes),
                      () {
                        ref.read(playerProvider.notifier).pause();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sleep timer ended, paused music')),
                          );
                        }
                      },
                    );
                    Navigator.pop(ctx);
                  },
                )),
            if (_sleepTimer.isActive)
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.red),
                title: const Text('Cancel Timer'),
                onTap: () {
                  _sleepTimer.cancel();
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playerState = ref.watch(playerProvider);
    final controller = ref.read(playerProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final song = playerState.currentSong;
    final isFav = song != null && ref.watch(favoritesProvider).contains(song.id);

    if (song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No song playing')),
      );
    }

    if (playerState.status == PlayerStatus.playing) {
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              size: 32, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Now Playing',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.queue_music, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QueueScreen()),
            ),
          ),
          PopupMenuButton<String>(
            color: theme.colorScheme.surface,
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              if (value == 'equalizer') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                );
              } else if (value == 'sleep') {
                _showSleepTimerDialog();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'equalizer',
                child: Row(
                  children: [
                    Icon(Icons.equalizer),
                    SizedBox(width: 12),
                    Text('Equalizer'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'sleep',
                child: Row(
                  children: [
                    Icon(_sleepTimer.isActive ? Icons.bedtime : Icons.bedtime_outlined),
                    const SizedBox(width: 12),
                    Text(_sleepTimer.isActive ? 'Sleep Timer (Active)' : 'Sleep Timer'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: AnimatedGradientBackground(
        colors: const [
          Color(0xFF6750A4),
          Color(0xFF3D2C5C),
          Color(0xFF1A0F2E),
        ],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Album Art
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (ctx, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: AlbumArtWidget(
                      song: song,
                      size: 280,
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Visualizer
                if (settings.visualizerEnabled)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: AudioVisualizer(
                      barCount: 40,
                      height: 60,
                      color: Colors.white,
                    ),
                  ),

                const SizedBox(height: 16),

                // Title & Artist
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            song.title,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${song.artist} • ${song.album}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Progress Slider
                StreamBuilder<Duration>(
                  stream: controller.player.positionStream,
                  initialData: playerState.position,
                  builder: (ctx, posSnap) {
                    return StreamBuilder<Duration?>(
                      stream: controller.player.durationStream,
                      initialData: playerState.duration,
                      builder: (ctx, durSnap) {
                        final pos = posSnap.data ?? playerState.position;
                        final dur = durSnap.data ?? playerState.duration;
                        final max = dur.inMilliseconds.toDouble();
                        final val = pos.inMilliseconds.toDouble().clamp(0.0, max);

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderThemeData(
                                trackHeight: 4,
                                thumbShape: const RoundSliderThumbShape(
                                    enabledThumbRadius: 8),
                                overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 16),
                                activeTrackColor: Colors.white,
                                inactiveTrackColor: Colors.white.withOpacity(0.2),
                                thumbColor: Colors.white,
                              ),
                              child: Slider(
                                min: 0,
                                max: max == 0 ? 1 : max,
                                value: max == 0 ? 0 : val,
                                onChanged: (v) => controller.seek(
                                    Duration(milliseconds: v.toInt())),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_fmt(pos),
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                  Text(_fmt(dur),
                                      style: const TextStyle(
                                          color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: () => ref
                          .read(favoritesProvider.notifier)
                          .toggle(song),
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.redAccent : Colors.white70,
                        size: 28,
                      ),
                    ),
                    IconButton(
                      onPressed: controller.previous,
                      icon: const Icon(Icons.skip_previous_rounded,
                          color: Colors.white, size: 44),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: controller.toggle,
                        icon: Icon(
                          playerState.status == PlayerStatus.playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: const Color(0xFF6750A4),
                          size: 52,
                        ),
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    IconButton(
                      onPressed: controller.next,
                      icon: const Icon(Icons.skip_next_rounded,
                          color: Colors.white, size: 44),
                    ),
                    _ControlButton(
                      icon: controller.player.loopMode == LoopMode.one
                          ? Icons.repeat_one
                          : Icons.repeat,
                      active: controller.player.loopMode != LoopMode.off,
                      onPressed: controller.cycleRepeat,
                    ),
                  ],
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(
        icon,
        color: active ? Colors.white : Colors.white54,
        size: 28,
      ),
    );
  }
}
