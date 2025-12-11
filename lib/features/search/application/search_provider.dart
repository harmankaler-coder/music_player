import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../home/data/models/song_model.dart';
import '../../library/application/local_audio_provider.dart'; // Import local provider

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider.autoDispose<List<SongModel>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim().toLowerCase();

  if (query.isEmpty) {
    return [];
  }

  // 1. Fetch Online Songs (Supabase)
  final supabase = Supabase.instance.client;
  List<SongModel> onlineSongs = [];
  try {
    final response = await supabase
        .from('songs')
        .select()
        .or('title.ilike.%$query%,artist.ilike.%$query%');

    final data = response as List<dynamic>;
    onlineSongs = data.map((json) => SongModel.fromJson(json)).toList();
  } catch (e) {
    print("Search Error (Online): $e");
  }

  // 2. Fetch Local Songs (Device)
  // We re-use the existing provider which handles permissions and scanning
  final localSongsAsync = await ref.read(localAudioProvider.future);
  final localMatches = localSongsAsync.where((song) {
    return song.title.toLowerCase().contains(query) ||
        song.artist.toLowerCase().contains(query);
  }).toList();

  // 3. Merge Results (Local first, then Online)
  return [...localMatches, ...onlineSongs];
});
