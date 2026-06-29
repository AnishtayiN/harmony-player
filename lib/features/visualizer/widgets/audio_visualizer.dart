import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/player_provider.dart';

class AudioVisualizer extends ConsumerStatefulWidget {
  final int barCount;
  final double height;
  final Color color;

  const AudioVisualizer({
    super.key,
    this.barCount = 32,
    this.height = 80,
    this.color = Colors.white,
  });

  @override
  ConsumerState<AudioVisualizer> createState() => _AudioVisualizerState();
}

class _AudioVisualizerState extends ConsumerState<AudioVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _barHeights = [];
  final List<double> _targetHeights = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _barHeights.addAll(List.filled(widget.barCount, 0.1));
    _targetHeights.addAll(List.filled(widget.barCount, 0.1));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..addListener(_updateBars);
  }

  void _updateBars() {
    if (!mounted) return;
    for (int i = 0; i < widget.barCount; i++) {
      final diff = _targetHeights[i] - _barHeights[i];
      _barHeights[i] += diff * 0.3;
    }
    _generateNewTargets();
    setState(() {});
  }

  void _generateNewTargets() {
    for (int i = 0; i < widget.barCount; i++) {
      final wave =
          sin(i * 0.3 + DateTime.now().millisecondsSinceEpoch * 0.002);
      final randomFactor = 0.3 + _random.nextDouble() * 0.7;
      _targetHeights[i] = (0.3 + wave.abs() * 0.7) * randomFactor;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final playerState = ref.watch(playerProvider);
    final isPlaying = playerState.status == PlayerStatus.playing;

    if (isPlaying && !_controller.isAnimating) {
      _controller.repeat(period: const Duration(milliseconds: 150));
    } else if (!isPlaying && _controller.isAnimating) {
      _controller.stop();
      for (int i = 0; i < widget.barCount; i++) {
        _targetHeights[i] = 0.1;
      }
    }

    return SizedBox(
      height: widget.height,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(widget.barCount, (index) {
          return _Bar(
            height: _barHeights[index] * widget.height,
            maxHeight: widget.height,
            color: widget.color,
          );
        }),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;
  final double maxHeight;
  final Color color;

  const _Bar({
    required this.height,
    required this.maxHeight,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      width: 3,
      height: height.clamp(2.0, maxHeight),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}
