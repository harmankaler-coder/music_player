// (Imports same as before...)
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:on_audio_query/on_audio_query.dart';
import '../../application/player_provider.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider);
    final isPlaying = ref.watch(isPlayingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (currentSong == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/player/${currentSong.id}'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E).withOpacity(0.85) : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Row(
              children: [
                Hero(
                  tag: 'mini_player_art',
                  child: Container(
                    width: 46, height: 46,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: ClipOval(
                      child: currentSong.coverUrl.isEmpty
                          ? QueryArtworkWidget(
                        id: int.tryParse(currentSong.id) ?? 0,
                        type: ArtworkType.AUDIO,
                        keepOldArtwork: true,
                        nullArtworkWidget: Container(color: Colors.grey[800], child: const Icon(Icons.music_note, color: Colors.white)),
                      )
                          : CachedNetworkImage(
                        imageUrl: currentSong.coverUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(currentSong.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black)),
                      Text(currentSong.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                    ],
                  ),
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 26,
                      color: isDark ? Colors.white : Colors.black,
                      onPressed: () => ref.read(playerControllerProvider).playPrevious(),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                      child: IconButton(
                        icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        iconSize: 24,
                        color: Colors.white,
                        onPressed: () => ref.read(playerControllerProvider).togglePlayPause(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 26,
                      color: isDark ? Colors.white : Colors.black,
                      onPressed: () => ref.read(playerControllerProvider).playNext(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
