import 'package:flutter/material.dart';

class AppTheme {
  // Bold, modern palette — warm coral-orange primary on deep charcoal
  static const Color primary = Color(0xFFFF5533);      // Bold coral-orange
  static const Color secondary = Color(0xFFFFB347);    // Amber accent
  static const Color bgDark = Color(0xFF0F0F0F);       // Near-black
  static const Color bgCard = Color(0xFF1C1C1E);       // iOS-style dark card
  static const Color bgElevated = Color(0xFF2C2C2E);   // Elevated surface
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color divider = Color(0xFF38383A);
  static const Color success = Color(0xFF34C759);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF5533), Color(0xFFFF8C42)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardOverlay = LinearGradient(
    colors: [Colors.transparent, Color(0xCC0F0F0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get theme => ThemeData.dark().copyWith(
        primaryColor: primary,
        scaffoldBackgroundColor: bgDark,
        colorScheme: const ColorScheme.dark(
          primary: primary,
          secondary: secondary,
          surface: bgCard,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bgDark,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        cardTheme: CardThemeData(
          color: bgCard,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
}