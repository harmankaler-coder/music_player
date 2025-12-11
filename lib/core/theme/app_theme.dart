// lib/core/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Modern Palette
  static const Color background = Color(0xFF09090B); // Very dark slightly blue-grey
  static const Color surface = Color(0xFF18181B);
  static const Color primary = Color(0xFF8B5CF6); // Violet
  static const Color accent = Color(0xFFEC4899); // Pink
  static const Color success = Color(0xFF10B981);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,

      // Modern Text Theme
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),

      // Navigation Bar (Floating Style)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent, // We will make it transparent
        indicatorColor: primary,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide, // Minimalist
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white);
          }
          return IconThemeData(color: Colors.grey[600]);
        }),
      ),
    );
  }
}
