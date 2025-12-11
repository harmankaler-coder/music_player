import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;
import '../../player/application/player_provider.dart';
import '../../home/data/models/song_model.dart';
import '../application/playlist_provider.dart';
import '../application/local_audio_provider.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. WATCH PLAYLISTS
    final playlistsAsync = ref.watch(playlistsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // HEADER
          SliverAppBar(
            floating: true,
            title: const Text(
              "Your Library",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 28),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.add, size: 28),
                onPressed: () => _showCreatePlaylistDialog(context, ref),
              ),
            ],
          ),

          // STATIC ITEMS (Favorites, Local Files)
          SliverToBoxAdapter(
            child: Column(
              children: [
                _LibraryTile(
                  icon: Icons.favorite_rounded,
                  color: Colors.redAccent,
                  title: "Liked Songs",
                  subtitle: "0 songs", // Placeholder
                  onTap: () {}, // TODO: Open Favorites
                ),
                _LibraryTile(
                  icon: Icons.phone_android_rounded,
                  color: Colors.green,
                  title: "Local Files",
                  subtitle: "Device storage",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LocalFilesScreen(),
                      ),
                    );
                  },
                ),
                const Divider(height: 32, thickness: 0.5),
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Playlists",
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PLAYLISTS LIST (Dynamic)
          playlistsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) =>
                SliverFillRemaining(child: Center(child: Text("Error: $err"))),
            data: (playlists) {
              if (playlists.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text("No Playlists Created")),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final playlist = playlists[index];
                  final songs = (playlist['songs'] as List).length;

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.music_note,
                        color: Colors.white70,
                      ),
                    ),
                    title: Text(
                      playlist['name'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text("$songs Songs"),
                    onTap: () {
                      // Navigate to Detail View
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlaylistDetailScreen(playlist: playlist),
                        ),
                      );
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () =>
                          _showPlaylistOptions(context, ref, playlist['id']),
                    ),
                  );
                }, childCount: playlists.length),
              );
            },
          ),

          const SliverPadding(
            padding: EdgeInsets.only(bottom: 160),
          ), // Main screen padding
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Playlist"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "My Playlist"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await ref
                    .read(playlistServiceProvider)
                    .createPlaylist(controller.text);
                ref.invalidate(playlistsProvider); // Refresh UI
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showPlaylistOptions(
    BuildContext context,
    WidgetRef ref,
    String playlistId,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true, // Show above Navbar
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                "Delete Playlist",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                await ref
                    .read(playlistServiceProvider)
                    .deletePlaylist(playlistId);
                ref.invalidate(playlistsProvider); // Refresh UI
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _LibraryTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

// --- SUB-SCREEN: Local Files ---
class LocalFilesScreen extends ConsumerWidget {
  const LocalFilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localSongsAsync = ref.watch(localAudioProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Local Files")),
      body: localSongsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error: $err")),
        data: (songs) {
          if (songs.isEmpty)
            return const Center(child: Text("No local songs found"));

          return ListView.builder(
            // FIX: Add Bottom Padding to avoid overlap with MiniPlayer
            padding: const EdgeInsets.only(bottom: 160),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ListTile(
                leading: QueryArtworkWidget(
                  id: int.tryParse(song.id) ?? 0,
                  type: ArtworkType.AUDIO,
                  nullArtworkWidget: Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey[800],
                    child: const Icon(Icons.music_note),
                  ),
                ),
                title: Text(
                  song.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  song.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  ref.read(playerControllerProvider).playSongList(songs, index);
                  context.push('/player/${song.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}

// --- SUB-SCREEN: Playlist Detail ---
class PlaylistDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> playlist;
  const PlaylistDetailScreen({super.key, required this.playlist});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistsAsync = ref.watch(playlistsProvider);

    final currentPlaylist =
        playlistsAsync.value?.firstWhere(
          (p) => p['id'] == playlist['id'],
          orElse: () => playlist,
        ) ??
        playlist;

    final songsRaw = currentPlaylist['songs'] as List;
    final songs = songsRaw
        .map(
          (json) => SongModel(
            id: json['id'],
            title: json['title'],
            artist: json['artist'],
            songUrl: json['song_url'],
            coverUrl: json['cover_url'],
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(currentPlaylist['name'])),
      body: songs.isEmpty
          ? const Center(child: Text("Empty Playlist"))
          : ListView.builder(
              // FIX: Add Bottom Padding here too
              padding: const EdgeInsets.only(bottom: 160),
              itemCount: songs.length,
              itemBuilder: (context, index) {
                final song = songs[index];
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: _buildArtwork(song),
                    ),
                  ),
                  title: Text(song.title),
                  subtitle: Text(song.artist),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: () async {
                      await ref
                          .read(playlistServiceProvider)
                          .removeSongFromPlaylist(playlist['id'], song.id);
                      ref.invalidate(playlistsProvider);
                    },
                  ),
                  onTap: () {
                    ref
                        .read(playerControllerProvider)
                        .playSongList(songs, index);
                    context.push('/player/${song.id}');
                  },
                );
              },
            ),
    );
  }

  Widget _buildArtwork(SongModel song) {
    if (song.coverUrl.isEmpty || !song.coverUrl.startsWith('http')) {
      return QueryArtworkWidget(
        id: int.tryParse(song.id) ?? 0,
        type: ArtworkType.AUDIO,
      );
    }
    return CachedNetworkImage(
      imageUrl: song.coverUrl,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => const Icon(Icons.music_note),
    );
  }
}
