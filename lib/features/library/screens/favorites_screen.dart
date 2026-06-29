import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../../../models/song.dart';
import '../../../providers/favorites_provider.dart';
import '../../../providers/player_provider.dart';
import '../../../widgets/song_tile.dart';
import '../../player/screens/now_playing_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final favIds = ref.watch(favoritesProvider);
    final songBox = Hive.box<Song>('songs');
    final favorites = favIds
        .map((id) => songBox.get(id))
        .where((s) => s != null)
        .cast<Song>()
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        actions: [
          if (favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear all',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Favorites?'),
                    content: const Text('This will remove all favorite songs.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(favoritesProvider.notifier).clear();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Clear',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border,
                      size: 80,
                      color: theme.colorScheme.onSurface.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text('No favorites yet',
                      style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text('Tap the heart icon on songs to add them here',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      )),
                ],
              ),
            )
          : Column(
              children: [
                if (favorites.length > 1)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${favorites.length} songs'),
                        FilledButton.icon(
                          onPressed: () {
                            ref
                                .read(playerProvider.notifier)
                                .playQueue(favorites, 0);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const NowPlayingScreen()),
                            );
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Play All'),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: favorites.length,
                    itemBuilder: (ctx, i) {
                      final song = favorites[i];
                      return SongTile(
                        song: song,
                        onTap: () {
                          ref
                              .read(playerProvider.notifier)
                              .playQueue(favorites, i);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const NowPlayingScreen()),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
