import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audio_service/audio_service.dart';
import '../../home/data/models/song_model.dart';
import 'audio_manager.dart';

// --- STATE PROVIDERS ---
final currentSongProvider = StateProvider<SongModel?>((ref) => null);
final queueProvider = StateProvider<List<SongModel>>((ref) => []);
final currentIndexProvider = StateProvider<int>((ref) => -1);

final isShuffleProvider = StateProvider<bool>((ref) => false);
final isRepeatProvider = StateProvider<bool>((ref) => false);

// --- DERIVED STATE ---
final isPlayingProvider = Provider.autoDispose<bool>((ref) {
  final playerStateAsync = ref.watch(playerStateStreamProvider);
  return playerStateAsync.when(
    data: (state) => state.playing,
    loading: () => false,
    error: (_, __) => false,
  );
});

// --- CONTROLLER ---
final playerControllerProvider = Provider((ref) => PlayerController(ref));

class PlayerController {
  final Ref ref;
  PlayerController(this.ref);

  Future<void> playSongList(List<SongModel> songs, int index) async {
    ref.read(currentSongProvider.notifier).state = songs[index];
    ref.read(queueProvider.notifier).state = songs;
    ref.read(currentIndexProvider.notifier).state = index;

    final audioManager = ref.read(audioManagerProvider);
    await audioManager.playSongList(songs, index);
  }

  Future<void> playSong(SongModel song) async {
    await playSongList([song], 0);
  }

  Future<void> playNext() async {
    final audioManager = ref.read(audioManagerProvider);
    await audioManager.next();
    _updateIndex(1);
  }

  Future<void> playPrevious() async {
    final audioManager = ref.read(audioManagerProvider);
    await audioManager.previous();
    _updateIndex(-1);
  }

  Future<void> togglePlayPause() async {
    final audioManager = ref.read(audioManagerProvider);
    final isPlaying = ref.read(isPlayingProvider);
    if (isPlaying) {
      await audioManager.pause();
    } else {
      await audioManager.resume();
    }
  }

  Future<void> seek(double value) async {
    final audioManager = ref.read(audioManagerProvider);
    final durationAsync = ref.read(durationProvider);
    final duration = durationAsync.value;

    if (duration != null) {
      await audioManager.seek(duration * value);
    }
  }

  void _updateIndex(int delta) {
    final current = ref.read(currentIndexProvider);
    final queue = ref.read(queueProvider);
    if (queue.isEmpty) return;

    int newIndex = current + delta;
    if (newIndex >= queue.length) newIndex = 0;
    if (newIndex < 0) newIndex = queue.length - 1;

    ref.read(currentIndexProvider.notifier).state = newIndex;
    ref.read(currentSongProvider.notifier).state = queue[newIndex];
  }
}
