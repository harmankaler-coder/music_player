import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/player_provider.dart';
import '../../application/audio_manager.dart';

class PlayerControls extends ConsumerWidget {
  const PlayerControls({super.key});

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${duration.inMinutes}:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(isPlayingProvider);
    final controller = ref.read(playerControllerProvider);

    // Watch Queue state
    final isShuffle = ref.watch(isShuffleProvider);
    final isRepeat = ref.watch(isRepeatProvider);

    final positionAsync = ref.watch(positionProvider);
    final durationAsync = ref.watch(durationProvider);

    final position = positionAsync.value ?? Duration.zero;
    final duration = durationAsync.value ?? Duration.zero;

    double sliderValue = 0.0;
    if (duration.inMilliseconds > 0) {
      sliderValue = position.inMilliseconds / duration.inMilliseconds;
    }
    if (sliderValue > 1.0) sliderValue = 1.0;
    if (sliderValue < 0.0) sliderValue = 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: const Color(0xFF6C63FF),
            inactiveTrackColor: Colors.white.withOpacity(0.2),
            thumbColor: Colors.white,
          ),
          child: Slider(
            value: sliderValue,
            onChanged: (val) {
              controller.seek(val);
            },
          ),
        ),

        // Time
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(position),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              Text(
                _formatDuration(duration),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shuffle
            IconButton(
              icon: const Icon(Icons.shuffle_rounded),
              color: isShuffle ? Theme.of(context).primaryColor : Colors.grey,
              onPressed: () {
                ref.read(isShuffleProvider.notifier).state = !isShuffle;
              },
            ),
            const SizedBox(width: 16),

            // Prev
            IconButton(
              iconSize: 36,
              icon: const Icon(Icons.skip_previous_rounded),
              color: Colors.white,
              onPressed: () => controller.playPrevious(),
            ),
            const SizedBox(width: 24),

            // Play/Pause
            Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: IconButton(
                iconSize: 42,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: Colors.black,
                ),
                onPressed: () => controller.togglePlayPause(),
              ),
            ),

            const SizedBox(width: 24),

            // Next
            IconButton(
              iconSize: 36,
              icon: const Icon(Icons.skip_next_rounded),
              color: Colors.white,
              onPressed: () => controller.playNext(),
            ),
            const SizedBox(width: 16),

            // Repeat
            IconButton(
              icon: Icon(isRepeat ? Icons.repeat_one_rounded : Icons.repeat_rounded),
              color: isRepeat ? Theme.of(context).primaryColor : Colors.grey,
              onPressed: () {
                ref.read(isRepeatProvider.notifier).state = !isRepeat;
              },
            ),
          ],
        ),
      ],
    );
  }
}
