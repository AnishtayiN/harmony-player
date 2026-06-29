import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'features/library/screens/home_screen.dart';
import 'models/song.dart';
import 'models/playlist.dart';
import 'models/favorite_song.dart';
import 'services/update_service.dart';
import 'services/storage_service.dart';
import 'widgets/update_dialog.dart';
import 'core/constants/app_constants.dart';
import 'providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  await Hive.initFlutter();
  Hive.registerAdapter(SongAdapter());
  Hive.registerAdapter(PlaylistAdapter());
  Hive.registerAdapter(FavoriteSongAdapter());

  await Hive.openBox<Song>('songs');
  await Hive.openBox<Playlist>('playlists');
  await Hive.openBox<FavoriteSong>('favorites');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: HarmonyApp()));
}

class HarmonyApp extends ConsumerStatefulWidget {
  const HarmonyApp({super.key});

  @override
  ConsumerState<HarmonyApp> createState() => _HarmonyAppState();
}

class _HarmonyAppState extends ConsumerState<HarmonyApp>
    with WidgetsBindingObserver {
  final _updateService = UpdateService();
  final _storage = StorageService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), _checkForUpdates);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdates(force: false);
    }
  }

  Future<void> _checkForUpdates({bool force = false}) async {
    final settings = ref.read(settingsProvider);
    if (!settings.autoUpdateEnabled && !force) return;

    final now = DateTime.now();

    if (!force) {
      final last = _storage.lastUpdateCheck;
      if (last != null && now.difference(last) < AppConstants.updateCheckInterval) {
        return;
      }
    }

    await _storage.setLastUpdateCheck(now);

    try {
      final update = await _updateService.checkUpdateIfNeeded();
      if (update != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => UpdateDialog(updateResult: update),
        );
      }
    } catch (e) {
      debugPrint('[Update] Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settings.themeMode,
      home: const HomeScreen(),
    );
  }
}
