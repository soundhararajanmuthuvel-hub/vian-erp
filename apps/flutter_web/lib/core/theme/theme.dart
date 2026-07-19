import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VianTheme {
  static const Color primaryGold = Color(0xFFE9C178); // Stitch Primary Gold
  static const Color primaryGoldLight = Color(0xFFC6A15B); // Stitch Primary Container Gold
  static const Color champagneGold = Color(0xFFF8EBE6); // Warm Sand Highlights
  static const Color darkBackground = Color(0xFF14141A); // Stitch Dark Background
  static const Color headerBlack = Color(0xFFE9E1D9); // On Background (Near-white)
  static const Color cardColor = Color(0xFF1E1B16); // Stitch Surface Container Low
  static const Color whiteText = Color(0xFFE9E1D9); // Main Light Text
  static const Color lightText = Color(0xFF9A8F80); // Secondary Light Text
  static const Color goldBorder = Color(0xFF38342C); // Dark Outline Variant Border
  static const Color success = Color(0xFF22C55E); // Emerald Success Green
  static const Color warning = Color(0xFFF59E0B); // Amber Warning
  static const Color danger = Color(0xFFBA1A1A); // Red Error
  static const Color accentBlue = Color(0xFF2563EB); // Royal Blue
  static const Color sidebarBg = Color(0xFF110E09); // Fixed Left Sidebar Base
 
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryGold,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: primaryGoldLight,
        background: darkBackground,
        surface: cardColor,
        onPrimary: Color(0xFF412D00),
        onSecondary: headerBlack,
        onBackground: headerBlack,
        onSurface: whiteText,
        error: danger,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 40.0, fontWeight: FontWeight.bold, color: headerBlack, letterSpacing: -0.02),
        titleLarge: GoogleFonts.outfit(fontSize: 24.0, fontWeight: FontWeight.w600, color: headerBlack, letterSpacing: -0.01),
        bodyLarge: GoogleFonts.inter(fontSize: 16.0, color: whiteText),
        bodyMedium: GoogleFonts.inter(fontSize: 14.0, color: lightText),
        labelLarge: GoogleFonts.jetBrainsMono(fontSize: 14.0, fontWeight: FontWeight.w600, color: primaryGold, letterSpacing: 0.05),
        labelSmall: GoogleFonts.jetBrainsMono(fontSize: 12.0, fontWeight: FontWeight.bold, color: primaryGold, letterSpacing: 0.05),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: headerBlack),
        titleTextStyle: GoogleFonts.outfit(
          color: headerBlack,
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: sidebarBg,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 10px rounded corners
          side: const BorderSide(color: goldBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: const Color(0xFF412D00),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6), // 6px rounded corners
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGold,
          side: const BorderSide(color: primaryGold, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6), // 6px rounded corners
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor,
        labelStyle: const TextStyle(color: lightText),
        floatingLabelStyle: const TextStyle(color: primaryGold),
        hintStyle: const TextStyle(color: Color(0xFF8E8A84)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: goldBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
      ),
    );
  }
}
