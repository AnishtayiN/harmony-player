import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/settings_provider.dart';
import '../../../providers/player_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme == 'http' || uri.scheme == 'https') {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      debugPrint('[Settings] Error opening URL: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final settingsCtrl = ref.read(settingsProvider.notifier);
    final playerCtrl = ref.read(playerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette),
            title: const Text('Theme'),
            subtitle: Text(_themeName(settings.themeMode)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => SimpleDialog(
                  title: const Text('Choose Theme'),
                  children: ThemeMode.values.map((mode) {
                    return SimpleDialogOption(
                      onPressed: () {
                        settingsCtrl.setThemeMode(mode);
                        Navigator.pop(ctx);
                      },
                      child: Row(
                        children: [
                          Icon(_themeIcon(mode)),
                          const SizedBox(width: 12),
                          Text(_themeName(mode)),
                          if (settings.themeMode == mode) const Spacer(),
                          if (settings.themeMode == mode)
                            const Icon(Icons.check, color: Colors.green),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.graphic_eq),
            title: const Text('Show Visualizer'),
            subtitle: const Text('Animated bars (decorative)'),
            value: settings.visualizerEnabled,
            onChanged: settingsCtrl.setVisualizer,
          ),

          const _SectionHeader('Playback'),
          ListTile(
            leading: const Icon(Icons.speed),
            title: const Text('Playback Speed'),
            subtitle: Text('${settings.playbackSpeed.toStringAsFixed(2)}x'),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => StatefulBuilder(
                  builder: (ctx, setSt) {
                    double speed = settings.playbackSpeed;
                    return AlertDialog(
                      title: const Text('Playback Speed'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${speed.toStringAsFixed(2)}x',
                            style: theme.textTheme.headlineMedium,
                          ),
                          Slider(
                            min: 0.5,
                            max: 2.0,
                            divisions: 15,
                            value: speed,
                            onChanged: (v) => setSt(() => speed = v),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            settingsCtrl.setPlaybackSpeed(speed);
                            playerCtrl.setPlaybackSpeed(speed);
                            Navigator.pop(ctx);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
          ),

          const _SectionHeader('Updates'),
          SwitchListTile(
            secondary: const Icon(Icons.system_update),
            title: const Text('Auto-check for Updates'),
            value: settings.autoUpdateEnabled,
            onChanged: settingsCtrl.setAutoUpdate,
          ),

          const _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Version'),
            subtitle: const Text(AppConstants.appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.code),
            title: const Text('Source Code'),
            subtitle: const Text('View on GitHub'),
            onTap: () => _openUrl(AppConstants.repositoryUrl),
          ),
          ListTile(
            leading: const Icon(Icons.telegram, color: Color(0xFF0088CC)),
            title: const Text('Contact Developer'),
            subtitle: const Text(AppConstants.developerTelegramHandle),
            onTap: () => _openUrl(AppConstants.developerTelegram),
          ),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'Made with ❤️ by ${AppConstants.developerName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System default';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.brightness_auto;
      case ThemeMode.light:
        return Icons.brightness_high;
      case ThemeMode.dark:
        return Icons.brightness_2;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
