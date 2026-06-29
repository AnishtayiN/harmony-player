import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/song.dart';
import '../../../providers/player_provider.dart';
import '../../../widgets/song_tile.dart';
import '../../player/screens/now_playing_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  List<Song> _songs = [];
  bool _isLoading = true;
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadSongs();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadSongs() async {
    setState(() => _isLoading = true);
    final library = ref.read(libraryProvider);
    final cached = library.getCachedSongs();

    if (cached.isEmpty) {
      final scanned = await library.scanLibrary();
      setState(() {
        _songs = scanned;
        _isLoading = false;
      });
    } else {
      setState(() {
        _songs = cached;
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() => _searchQuery = query);
    });
  }

  List<Song> get _filteredSongs {
    if (_searchQuery.isEmpty) return _songs;
    final q = _searchQuery.toLowerCase();
    return _songs
        .where((s) =>
            s.title.toLowerCase().contains(q) ||
            s.artist.toLowerCase().contains(q) ||
            s.album.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Your Library',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary.withOpacity(0.8),
                      theme.colorScheme.primary.withOpacity(0.3),
                      theme.scaffoldBackgroundColor,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -30,
                      top: 30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isLoading ? null : _loadSongs,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SearchBar(
                leading: const Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Icon(Icons.search),
                ),
                hintText: 'Search songs, artists, albums...',
                onChanged: _onSearchChanged,
                elevation: const MaterialStatePropertyAll(0),
                shape: MaterialStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),

          if (!_isLoading && _songs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_filteredSongs.length} songs',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatTotalDuration(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color:
                                theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        ref
                            .read(playerProvider.notifier)
                            .playQueue(_filteredSongs, 0);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const NowPlayingScreen()),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Play All'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_filteredSongs.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.music_off,
                        size: 80,
                        color: theme.colorScheme.onSurface.withOpacity(0.3)),
                    const SizedBox(height: 16),
                    Text(
                      _songs.isEmpty ? 'No music found' : 'No matches',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _songs.isEmpty
                          ? 'Add music files or grant permissions'
                          : 'Try a different search',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_songs.isEmpty)
                      ElevatedButton.icon(
                        onPressed: _loadSongs,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Scan Library'),
                      ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  final song = _filteredSongs[i];
                  return SongTile(
                    song: song,
                    onTap: () {
                      ref
                          .read(playerProvider.notifier)
                          .playQueue(_filteredSongs, i);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const NowPlayingScreen()),
                      );
                    },
                  );
                },
                childCount: _filteredSongs.length,
              ),
            ),

          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ),
    );
  }

  String _formatTotalDuration() {
    final total = _filteredSongs.fold<int>(
        0, (sum, s) => sum + s.duration.inSeconds);
    final hours = total ~/ 3600;
    final minutes = (total % 3600) ~/ 60;
    if (hours > 0) return '$hours hours, $minutes minutes';
    return '$minutes minutes';
  }
}
