import 'package:just_audio/just_audio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../../../global.dart'; // Ensure this points to your global.dart
import '../../home/data/models/song_model.dart';
import 'audio_handler.dart';

final audioManagerProvider = Provider<AudioManager>((ref) {
  return AudioManager();
});

// Update Providers to safe-guard against null handler via Singleton
final positionProvider = StreamProvider.autoDispose<Duration>((ref) {
  return AudioService.position;
});

final durationProvider = StreamProvider.autoDispose<Duration?>((ref) {
  final handler = global.audioHandler;
  if (handler == null) return Stream.value(null);
  return handler.mediaItem.map((item) => item?.duration);
});

final playerStateStreamProvider = StreamProvider.autoDispose<PlaybackState>((ref) {
  final handler = global.audioHandler;
  if (handler == null) return Stream.value(PlaybackState());
  return handler.playbackState;
});

class AudioManager {
  // SINGLETON GETTER: Fetches the handler from the GlobalLocator
  MyAudioHandler? get _handler {
    final handler = global.audioHandler;

    if (handler == null) {
      print("AudioHandler is NULL! (Singleton Check Failed)");
      return null;
    }
    return handler as MyAudioHandler;
  }

  // --- ACTIONS ---

  Future<void> playSongList(List<SongModel> songs, int index) async {
    final handler = _handler;
    if (handler != null) {
      await handler.playSongList(songs, index);
    } else {
      print("Action Ignored: AudioHandler not ready yet.");
    }
  }

  Future<void> playSong(SongModel song) async {
    await playSongList([song], 0);
  }

  Future<void> pause() async {
    await _handler?.pause();
  }

  Future<void> resume() async {
    await _handler?.play();
  }

  Future<void> seek(Duration position) async {
    await _handler?.seek(position);
  }

  Future<void> next() async {
    await _handler?.skipToNext();
  }

  Future<void> previous() async {
    await _handler?.skipToPrevious();
  }

  // Expose internal player safely (For legacy UI seeking/listeners)
  AudioPlayer get player {
    if (_handler == null) {
      // Return a dummy player to prevent crash if accessed too early
      return AudioPlayer();
    }
    return _handler!.internalPlayer;
  }
}
