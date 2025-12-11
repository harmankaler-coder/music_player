import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../../home/data/models/song_model.dart';

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  MyAudioHandler() {
    _initListeners();
  }

  void _initListeners() {
    // 1. Playback State
    _player.playbackEventStream.listen((PlaybackEvent event) {
      final playing = _player.playing;
      playbackState.add(playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: event.currentIndex,
      ));
    });

    // 2. Duration
    _player.durationStream.listen((duration) {
      final index = _player.currentIndex;
      final newQueue = queue.value;
      if (index != null && newQueue.isNotEmpty && index < newQueue.length) {
        final oldMediaItem = newQueue[index];
        final newMediaItem = oldMediaItem.copyWith(duration: duration);
        newQueue[index] = newMediaItem;
        queue.add(newQueue);
        mediaItem.add(newMediaItem);
      }
    });

    // 3. Current Index
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  Future<void> playSongList(List<SongModel> songs, int index) async {
    print("Handler: playSongList called with ${songs.length} songs");

    final mediaItems = songs.map((song) {
      Uri? artUri;

      if (song.coverUrl.isNotEmpty && song.coverUrl.startsWith('http')) {
        // ONLINE
        artUri = Uri.parse(song.coverUrl);
      } else {
        // LOCAL: Try standard Android Content URI for Album Art
        final intId = int.tryParse(song.id);
        if (intId != null) {
          artUri = Uri.parse("content://media/external/audio/media/$intId/albumart");
        }
      }

      return MediaItem(
        id: song.songUrl,
        album: "Music App",
        title: song.title,
        artist: song.artist,
        artUri: artUri, // Now passing content:// URI for local
        extras: {'id': song.id},
      );
    }).toList();

    queue.add(mediaItems);

    try {
      final audioSource = ConcatenatingAudioSource(
        children: mediaItems.map((item) {
          final uriStr = item.id;
          if (uriStr.startsWith('http') || uriStr.startsWith('https')) {
            return AudioSource.uri(Uri.parse(uriStr), tag: item);
          } else if (uriStr.startsWith('content://')) {
            return AudioSource.uri(Uri.parse(uriStr), tag: item);
          } else if (uriStr.startsWith('file://')) {
            return AudioSource.uri(Uri.parse(uriStr), tag: item);
          } else {
            // Force file scheme for paths
            return AudioSource.uri(Uri.file(uriStr), tag: item);
          }
        }).toList(),
      );

      await _player.setAudioSource(audioSource, initialIndex: index);
      await _player.play();

    } catch (e) {
      print("Handler Error during playback: $e");
    }
  }

  AudioPlayer get internalPlayer => _player;
}
