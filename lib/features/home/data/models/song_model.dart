class SongModel {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;
  final String songUrl;

  const SongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
    required this.songUrl,
  });

  // Factory constructor to create a SongModel from Supabase JSON
  factory SongModel.fromJson(Map<String, dynamic> json) {
    return SongModel(
      id: json['id'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      coverUrl: json['cover_url'] as String, // Note the snake_case key from SQL
      songUrl: json['song_url'] as String,
    );
  }
}
