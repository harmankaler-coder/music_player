// lib/features/library/application/favorites_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../home/data/models/song_model.dart';

// 1. The Service Class
class FavoritesService {
  final Box _box;

  FavoritesService(this._box);

  // Toggle favorite status
  Future<void> toggleFavorite(SongModel song) async {
    if (_box.containsKey(song.id)) {
      await _box.delete(song.id);
    } else {
      // Store basic details so we can display them offline
      await _box.put(song.id, {
        'id': song.id,
        'title': song.title,
        'artist': song.artist,
        'cover_url': song.coverUrl,
        'song_url': song.songUrl,
      });
    }
  }

  bool isFavorite(String songId) {
    return _box.containsKey(songId);
  }

  List<SongModel> getFavorites() {
    return _box.values.map((dynamic item) {
      final map = Map<String, dynamic>.from(item as Map);
      // Construct SongModel manually from Hive map
      return SongModel(
        id: map['id'],
        title: map['title'],
        artist: map['artist'],
        coverUrl: map['cover_url'],
        songUrl: map['song_url'],
      );
    }).toList();
  }
}

// 2. The Service Provider
final favoritesServiceProvider = Provider<FavoritesService>((ref) {
  // We assume 'favorites' box is opened in main.dart
  final box = Hive.box('favorites');
  return FavoritesService(box);
});

// 3. The List Provider (What the UI watches)
// We use a StreamProvider to update UI instantly when Hive changes
final favoritesProvider = StreamProvider.autoDispose<List<SongModel>>((ref) async* {
  final box = Hive.box('favorites');
  final service = FavoritesService(box);

  // Yield initial value
  yield service.getFavorites();

  // Yield new values whenever the box changes
  await for (final _ in box.watch()) {
    yield service.getFavorites();
  }
});

// 4. Helper Provider to check a specific song
final isFavoriteProvider = Provider.family<bool, String>((ref, songId) {
  final service = ref.watch(favoritesServiceProvider);
  // We also watch the stream to force rebuilds
  ref.watch(favoritesProvider);
  return service.isFavorite(songId);
});
