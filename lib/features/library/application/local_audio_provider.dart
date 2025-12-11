import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import 'package:permission_handler/permission_handler.dart';
import '../../home/data/models/song_model.dart';

final localAudioProvider = FutureProvider<List<SongModel>>((ref) async {
  final OnAudioQuery audioQuery = OnAudioQuery();

  // 1. Request Permission
  bool permission = await audioQuery.permissionsStatus();
  if (!permission) {
    await Permission.storage.request();
    await Permission.audio.request();
    permission = await audioQuery.permissionsStatus();
  }

  if (!permission) {
    return [];
  }

  // 2. Query Songs
  List<SongModel> localSongs = [];
  try {
    List<SongModel> songs = await audioQuery.querySongs(
      sortType: SongSortType.DATE_ADDED,
      orderType: OrderType.DESC_OR_GREATER,
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    ).then((deviceSongs) {
      // 3. FILTERING LOGIC
      // Remove small files (likely ringtones/calls)
      final musicFiles = deviceSongs.where((song) {
        // Filter 1: Duration > 45 seconds (45000 ms)
        final duration = song.duration ?? 0;
        if (duration < 45000) return false;

        // Filter 2: Remove known non-music paths
        final path = song.data.toLowerCase();
        if (path.contains('call_rec') ||
            path.contains('whatsapp audio') ||
            path.contains('voice recorder')) {
          return false;
        }

        // Filter 3: Check "isMusic" flag if available (not always reliable, but helpful)
        if (song.isMusic == false) return false;

        return true;
      }).toList();

      // Convert to our model
      return musicFiles.map((e) {
        return SongModel(
          id: e.id.toString(),
          title: e.title,
          artist: e.artist == "<unknown>" ? "Unknown Artist" : (e.artist ?? "Unknown Artist"),
          coverUrl: '', // Local files don't have URLs
          songUrl: e.uri!,
        );
      }).toList();
    });

    localSongs = songs;

  } catch (e) {
    print("Error querying songs: $e");
  }

  return localSongs;
});
