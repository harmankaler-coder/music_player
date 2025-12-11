// lib/features/home/data/mock_data.dart

class Song {
  final String id;
  final String title;
  final String artist;
  final String coverUrl;

  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.coverUrl,
  });
}

class MockData {
  // Random music covers from Unsplash
  static const List<Song> recentlyPlayed = [
    Song(id: '1', title: 'Midnight City', artist: 'M83', coverUrl: 'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?q=80&w=300&auto=format&fit=crop'),
    Song(id: '2', title: 'Starboy', artist: 'The Weeknd', coverUrl: 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?q=80&w=300&auto=format&fit=crop'),
    Song(id: '3', title: 'Levitating', artist: 'Dua Lipa', coverUrl: 'https://images.unsplash.com/photo-1493225255756-d9584f8606e9?q=80&w=300&auto=format&fit=crop'),
    Song(id: '4', title: 'Stay', artist: 'Kid Laroi', coverUrl: 'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?q=80&w=300&auto=format&fit=crop'),
  ];

  static const List<Song> forYou = [
    Song(id: '5', title: 'Blinding Lights', artist: 'The Weeknd', coverUrl: 'https://images.unsplash.com/photo-1514525253440-b393452e3383?q=80&w=300&auto=format&fit=crop'),
    Song(id: '6', title: 'Peaches', artist: 'Justin Bieber', coverUrl: 'https://images.unsplash.com/photo-1506157786151-b8491531f063?q=80&w=300&auto=format&fit=crop'),
    Song(id: '7', title: 'Good 4 U', artist: 'Olivia Rodrigo', coverUrl: 'https://images.unsplash.com/photo-1459749411177-287ce3288789?q=80&w=300&auto=format&fit=crop'),
    Song(id: '8', title: 'Montero', artist: 'Lil Nas X', coverUrl: 'https://images.unsplash.com/photo-1501612780327-45045538702b?q=80&w=300&auto=format&fit=crop'),
    Song(id: '9', title: 'Heat Waves', artist: 'Glass Animals', coverUrl: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?q=80&w=300&auto=format&fit=crop'),
  ];
}
