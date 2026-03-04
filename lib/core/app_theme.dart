import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme.dart';

/// Light variant of the VeriScan theme.
/// Neon accents stay identical — only backgrounds and surfaces change.
class AppTheme {
  // ── Light Background ──
  static const Color lightBackground = Color(0xFFF4F6F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardFill = Color(0x15000000); // 8% black

  // ── Light Text ──
  static const Color lightTextPrimary = Color(0xFF0D0F14);
  static const Color lightTextSecondary = Color(0x990D0F14);
  static const Color lightTextMuted = Color(0x4D0D0F14);

  static ThemeData get neonLight {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: VeriScanTheme.cyan,
        secondary: VeriScanTheme.purple,
        surface: lightSurface,
        error: VeriScanTheme.red,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: lightTextPrimary,
            letterSpacing: 1.2,
          ),
          displayMedium: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: lightTextPrimary,
          ),
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: lightTextPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: lightTextPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: lightTextPrimary,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: lightTextSecondary),
          bodyMedium: TextStyle(fontSize: 14, color: lightTextSecondary),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: lightTextPrimary,
            letterSpacing: 1.5,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: lightTextPrimary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: VeriScanTheme.cyan,
        unselectedItemColor: lightTextMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
