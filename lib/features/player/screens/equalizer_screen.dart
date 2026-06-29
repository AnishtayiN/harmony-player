import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/equalizer_service.dart';

final equalizerProvider = Provider<EqualizerService>((ref) => EqualizerService());

class EqualizerScreen extends ConsumerStatefulWidget {
  const EqualizerScreen({super.key});

  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen> {
  final List<String> _freqLabels = [
    '31', '62', '125', '250', '500', '1k', '2k', '4k', '8k', '16k'
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eq = ref.watch(equalizerProvider);

    if (!Platform.isAndroid) {
      return Scaffold(
        appBar: AppBar(title: const Text('Equalizer')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, size: 64,
                    color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Equalizer is only available on Android',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Audio equalization requires platform-specific APIs that are currently only supported on Android devices.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equalizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: () {
              eq.reset();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.orange.shade100,
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Note: Equalizer affects audio only on Android devices with compatible hardware.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: EqualizerService.presets.length,
              itemBuilder: (ctx, i) {
                final preset = EqualizerService.presets[i];
                final isSelected = eq.currentPreset.name == preset.name;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(preset.name),
                    selected: isSelected,
                    onSelected: (_) {
                      eq.setPreset(preset);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(10, (i) {
                  return Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${eq.bands[i].toStringAsFixed(0)}dB',
                          style: theme.textTheme.bodySmall,
                        ),
                        Expanded(
                          child: RotatedBox(
                            quarterTurns: 3,
                            child: Slider(
                              min: -12,
                              max: 12,
                              divisions: 24,
                              value: eq.bands[i],
                              onChanged: (v) {
                                eq.setBand(i, v);
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                        Text(
                          _freqLabels[i],
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
