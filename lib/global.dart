import 'package:audio_service/audio_service.dart';

class GlobalLocator {
  static final GlobalLocator _instance = GlobalLocator._internal();
  factory GlobalLocator() => _instance;
  GlobalLocator._internal();

  AudioHandler? audioHandler;
}

// Global accessor
final global = GlobalLocator();
