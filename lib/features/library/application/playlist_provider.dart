import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../home/data/models/song_model.dart';

class PlaylistService {
  final Box _box;

  PlaylistService(this._box);

  // 1. CREATE
  Future<String> createPlaylist(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newPlaylist = {
      'id': id,
      'name': name,
      'songs': [], // Empty list of songs
    };

    await _box.put(id, newPlaylist);
    print("Playlist Created: $name (ID: $id)");
    return id;
  }

  // 2. DELETE PLAYLIST
  Future<void> deletePlaylist(String id) async {
    await _box.delete(id);
    print("Playlist Deleted: $id");
  }

  // 3. ADD SONG
  Future<void> addSongToPlaylist(String playlistId, SongModel song) async {
    final rawPlaylist = _box.get(playlistId);
    if (rawPlaylist == null) return;

    // Convert to Modifiable Map
    final playlist = Map<String, dynamic>.from(rawPlaylist);
    final List songs = List.from(playlist['songs'] ?? []);

    // Check if song already exists
    final exists = songs.any((s) => s['id'] == song.id);
    if (exists) {
      print("Song already in playlist");
      return;
    }

    // Add Song Data
    songs.add({
      'id': song.id,
      'title': song.title,
      'artist': song.artist,
      'song_url': song.songUrl,
      'cover_url': song.coverUrl,
    });

    playlist['songs'] = songs;
    await _box.put(playlistId, playlist);
    print("Song Added to ${playlist['name']}");
  }

  // 4. REMOVE SONG
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    final rawPlaylist = _box.get(playlistId);
    if (rawPlaylist == null) return;

    final playlist = Map<String, dynamic>.from(rawPlaylist);
    final List songs = List.from(playlist['songs'] ?? []);

    songs.removeWhere((s) => s['id'] == songId);

    playlist['songs'] = songs;
    await _box.put(playlistId, playlist);
    print("Song Removed from ${playlist['name']}");
  }

  // 5. GET ALL
  List<Map<String, dynamic>> getPlaylists() {
    return _box.values.map((e) {
      // Ensure it's a Map<String, dynamic>
      if (e is Map) {
        return Map<String, dynamic>.from(e);
      }
      return <String, dynamic>{};
    }).toList();
  }
}

// --- PROVIDERS ---

final playlistServiceProvider = Provider<PlaylistService>((ref) {
  // Ensure the box is open. If not, this will throw.
  // We assume main.dart opened it.
  final box = Hive.box('playlists');
  return PlaylistService(box);
});

final playlistsProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) async* {
      // Watch the Hive box for ANY changes
      final box = Hive.box('playlists');

      // Emit initial value
      yield box.values.map((e) => Map<String, dynamic>.from(e)).toList();

      // Emit on every change event
      await for (final event in box.watch()) {
        yield box.values.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    });
