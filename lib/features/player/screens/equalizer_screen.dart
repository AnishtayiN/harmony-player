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
          // Presets
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

          // Sliders
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
