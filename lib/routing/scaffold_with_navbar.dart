import 'dart:ui'; // For Blur
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/player/presentation/widgets/mini_player.dart';

class ScaffoldWithNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important: Allows body to go behind the floating bar
      body: Stack(
        children: [
          // 1. Main Content
          navigationShell,

          // 2. Floating Bottom UI (MiniPlayer + Navbar)
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Mini Player (Floating above Navbar)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: MiniPlayer(),
                ),

                // Custom Floating Pill Navbar
                _FloatingPillNavBar(navigationShell: navigationShell),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingPillNavBar extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _FloatingPillNavBar({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(40), // Fully rounded pill
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Glass Effect
        child: Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _NavBarItem(
                icon: Icons.home_rounded,
                label: 'Home',
                index: 0,
                currentIndex: navigationShell.currentIndex,
                onTap: () => _onTap(context, 0),
              ),
              _NavBarItem(
                icon: Icons.search_rounded,
                label: 'Search',
                index: 1, // Note: Index depends on your router order
                currentIndex: navigationShell.currentIndex,
                onTap: () => _onTap(context, 1),
              ),
              _NavBarItem(
                icon: Icons.library_music_rounded,
                label: 'Library',
                index: 2,
                currentIndex: navigationShell.currentIndex,
                onTap: () => _onTap(context, 2),
              ),
              _NavBarItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                index: 3,
                currentIndex: navigationShell.currentIndex,
                onTap: () => _onTap(context, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;
    final color = isSelected ? Theme.of(context).primaryColor : Colors.grey;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 26,
            ),
            // Only show label if selected (Smooth expand effect)
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
