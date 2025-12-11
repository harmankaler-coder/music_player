import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/models/song_model.dart';

// 1. Service Class (Handles raw API calls)
class HomeService {
  final SupabaseClient _supabase;

  HomeService(this._supabase);

  Future<List<SongModel>> fetchSongs() async {
    try {
      // Select all columns from the 'songs' table
      final response = await _supabase.from('songs').select().order('created_at');

      // Convert list of JSON objects to list of SongModels
      final data = response as List<dynamic>;
      return data.map((json) => SongModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load songs: $e');
    }
  }
}

// 2. Service Provider (Dependency Injection)
final homeServiceProvider = Provider<HomeService>((ref) {
  return HomeService(Supabase.instance.client);
});

// 3. Data Provider (The state UI listens to)
final songsProvider = FutureProvider<List<SongModel>>((ref) async {
  final service = ref.watch(homeServiceProvider);
  return service.fetchSongs();
});
