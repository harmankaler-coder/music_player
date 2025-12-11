import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:on_audio_query/on_audio_query.dart' hide SongModel;

import '../../home/data/models/song_model.dart';
import '../../library/application/playlist_provider.dart';
import '../application/audio_manager.dart';
import '../application/player_provider.dart';

class PlayerScreen extends ConsumerWidget {
  final String songId;
  const PlayerScreen({super.key, required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final positionAsync = ref.watch(positionProvider);
    final durationAsync = ref.watch(durationProvider);

    if (currentSong == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final duration = durationAsync.value ?? Duration.zero;
    final position = positionAsync.value ?? Duration.zero;
    final progress = (duration.inMilliseconds > 0)
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    final isFavorite = Hive.box('favorites').containsKey(currentSong.id);

    // FIX: Replaced Dismissible with GestureDetector for Swipe Down
    return GestureDetector(
      onVerticalDragEnd: (details) {
        // If swipe down velocity is high enough, close screen
        if (details.primaryVelocity! > 300) {
          context.pop();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 32,
              color: Colors.white,
            ),
            onPressed: () => context.pop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onPressed: () => _showSongOptions(context, ref, currentSong),
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildBackground(currentSong),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.3),
                            blurRadius: 40,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: _buildArtwork(currentSong),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentSong.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentSong.artist,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: isFavorite ? Colors.redAccent : Colors.white,
                          size: 28,
                        ),
                        onPressed: () async {
                          final box = Hive.box('favorites');
                          if (isFavorite) {
                            await box.delete(currentSong.id);
                          } else {
                            await box.put(currentSong.id, {
                              'id': currentSong.id,
                              'title': currentSong.title,
                              'artist': currentSong.artist,
                              'song_url': currentSong.songUrl,
                              'cover_url': currentSong.coverUrl,
                            });
                          }
                          (context as Element).markNeedsBuild();
                        },
                      ),
                    ],
                  ),

                  const Spacer(),

                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 6,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 12,
                      ),
                    ),
                    child: Slider(
                      value: min(progress, 1.0),
                      activeColor: Colors.white,
                      inactiveColor: Colors.white.withOpacity(0.2),
                      onChanged: (value) {
                        ref.read(playerControllerProvider).seek(value);
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(position),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.shuffle_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {},
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_previous_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            ref.read(playerControllerProvider).playPrevious(),
                      ),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(
                                context,
                              ).primaryColor.withOpacity(0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                          onPressed: () => ref
                              .read(playerControllerProvider)
                              .togglePlayPause(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.skip_next_rounded,
                          size: 40,
                          color: Colors.white,
                        ),
                        onPressed: () =>
                            ref.read(playerControllerProvider).playNext(),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.repeat_rounded,
                          color: Colors.white,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackground(SongModel song) {
    if (song.coverUrl.isEmpty || !song.coverUrl.startsWith('http')) {
      return Container(color: Colors.black);
    }
    return CachedNetworkImage(imageUrl: song.coverUrl, fit: BoxFit.cover);
  }

  Widget _buildArtwork(SongModel song) {
    if (song.coverUrl.isEmpty || !song.coverUrl.startsWith('http')) {
      return QueryArtworkWidget(
        id: int.tryParse(song.id) ?? 0,
        type: ArtworkType.AUDIO,
        artworkHeight: 300,
        artworkWidth: 300,
        size: 1000,
        keepOldArtwork: true,
        nullArtworkWidget: Container(
          color: Colors.grey[900],
          child: const Icon(
            Icons.music_note_rounded,
            size: 80,
            color: Colors.white,
          ),
        ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: song.coverUrl,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => Container(
          color: Colors.grey[900],
          child: const Icon(Icons.music_note),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _showSongOptions(BuildContext context, WidgetRef ref, SongModel song) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.only(bottom: 50),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[600],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: _buildSmallArtwork(song),
                  ),
                ),
                title: Text(
                  song.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(song.artist),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.playlist_add_rounded),
                title: const Text('Add to Playlist'),
                onTap: () {
                  context.pop();
                  _showAddToPlaylistDialog(context, ref, song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('Song Details'),
                onTap: () {
                  context.pop();
                  _showSongDetailsDialog(context, song);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSmallArtwork(SongModel song) {
    if (song.coverUrl.isEmpty || !song.coverUrl.startsWith('http')) {
      return QueryArtworkWidget(
        id: int.tryParse(song.id) ?? 0,
        type: ArtworkType.AUDIO,
      );
    }
    return CachedNetworkImage(imageUrl: song.coverUrl, fit: BoxFit.cover);
  }

  void _showSongDetailsDialog(BuildContext context, SongModel song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Song Details"),
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 60,
                height: 60,
                child: _buildSmallArtwork(song),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Title: ${song.title}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text("Artist: ${song.artist}"),
                  const SizedBox(height: 4),
                  Text(
                    "Source: ${song.songUrl.startsWith('http') ? 'Online' : 'Local Storage'}",
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "ID: ${song.id}",
                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showAddToPlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    SongModel song,
  ) {
    ref.invalidate(playlistsProvider);
    ref.read(playlistsProvider.future).then((playlists) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Add to Playlist"),
            content: SizedBox(
              width: double.maxFinite,
              child: playlists.isEmpty
                  ? const Text("No playlists created yet.")
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        final playlist = playlists[index];
                        return ListTile(
                          leading: const Icon(Icons.music_note_rounded),
                          title: Text(playlist['name']),
                          onTap: () {
                            ref
                                .read(playlistServiceProvider)
                                .addSongToPlaylist(playlist['id'], song);
                            context.pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Added to ${playlist['name']}"),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop();
                  _showCreatePlaylistDialog(context, ref, song);
                },
                child: const Text("New Playlist"),
              ),
              TextButton(
                onPressed: () => context.pop(),
                child: const Text("Cancel"),
              ),
            ],
          ),
        );
      }
    });
  }

  void _showCreatePlaylistDialog(
    BuildContext context,
    WidgetRef ref,
    SongModel? songToAdd,
  ) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        scrollable: true,
        title: const Text("New Playlist"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(hintText: "Playlist Name"),
                autofocus: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final id = await ref
                    .read(playlistServiceProvider)
                    .createPlaylist(controller.text);
                ref.invalidate(playlistsProvider);
                if (songToAdd != null) {
                  await ref
                      .read(playlistServiceProvider)
                      .addSongToPlaylist(id, songToAdd);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Added to ${controller.text}")),
                    );
                  }
                }
                if (context.mounted) context.pop();
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}
