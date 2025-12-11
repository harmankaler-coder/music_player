import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/player/application/audio_handler.dart';
import 'routing/app_router.dart';
import 'global.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  late AudioHandler audioHandler;

  // 1. Initialize Hive
  await Hive.initFlutter();

  // NEW: Open the favorites box
  await Hive.openBox('favorites');

  await Hive.openBox('playlists');

  // 2. Initialize Supabase (Backend)
  // TODO: Replace with your actual credentials from Supabase Dashboard
  await Supabase.initialize(
    url: 'https://btwbbaoihflsmzepfkww.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJ0d2JiYW9paGZsc216ZXBma3d3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUxOTg0MzIsImV4cCI6MjA4MDc3NDQzMn0.KHQdDEqP7XjuFzZrxxggo-PjWej783c-K3-sv6N8iBA',
  );

  print("Initializing Audio Service...");
  final handler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.music.channel.audio',
      androidNotificationChannelName: 'Music',
    ),
  );

  // ASSIGN TO SINGLETON
  global.audioHandler = handler;

  print("Audio Service Initialized.");



  runApp(
    // 3. Wrap app in ProviderScope for Riverpod state management
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the router provider defined in lib/routing/app_router.dart
    final router = ref.watch(routerProvider);
    final theme = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Flutter Music App',
      debugShowCheckedModeBanner: false,

      // Apply the modern Dark Theme defined in lib/core/theme/app_theme.dart
      theme: theme,

      // Connect GoRouter to handle the 6 tabs
      routerConfig: router,
    );
  }
}
