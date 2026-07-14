import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VianTheme {
  static const Color primaryGold = Color(0xFFC6A15B); // Atelier Gold
  static const Color primaryGoldLight = Color(0xFFE9C178); // Atelier Gold Light
  static const Color champagneGold = Color(0xFFF1E4C3); // Champagne Gold Accent
  static const Color darkBackground = Color(0xFF121317); // Atelier Near-Black Charcoal
  static const Color headerBlack = Color(0xFFE3E2E7); // Warm light grey for high contrast titles
  static const Color cardColor = Color(0xFF1E1F23); // Surface container Z-1 card
  static const Color whiteText = Color(0xFFE3E2E7); // Primary text
  static const Color lightText = Color(0xFFD1C5B4); // On-surface variant text
  static const Color goldBorder = Color(0xFF38342C); // Thin architectural outline/divider
  static const Color success = Color(0xFF22C55E); // Emerald Success Green
  static const Color warning = Color(0xFFF59E0B); // Amber Warning
  static const Color danger = Color(0xFFEF4444); // Rose Red Danger
  static const Color accentBlue = Color(0xFF2563EB); // Royal Blue
  static const Color sidebarBg = Color(0xFF121317); // Sidebar Z-0 Base background

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
        onPrimary: darkBackground,
        onSecondary: headerBlack,
        onBackground: headerBlack,
        onSurface: whiteText,
        error: danger,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.outfit(fontSize: 40.0, fontWeight: FontWeight.bold, color: headerBlack, letterSpacing: -0.01),
        titleLarge: GoogleFonts.outfit(fontSize: 24.0, fontWeight: FontWeight.w500, color: headerBlack),
        bodyLarge: GoogleFonts.inter(fontSize: 16.0, color: whiteText),
        bodyMedium: GoogleFonts.inter(fontSize: 14.0, color: lightText),
        labelLarge: GoogleFonts.poppins(fontSize: 14.0, fontWeight: FontWeight.w500, color: primaryGold),
        labelSmall: GoogleFonts.outfit(fontSize: 12.0, fontWeight: FontWeight.bold, color: primaryGold, letterSpacing: 0.15),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: headerBlack),
        titleTextStyle: GoogleFonts.outfit(
          color: headerBlack,
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
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
          borderRadius: BorderRadius.zero, // Sharp edge philosophy
          side: const BorderSide(color: goldBorder, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: darkBackground,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Sharp edge button
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
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.zero, // Sharp edge button
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBackground,
        labelStyle: const TextStyle(color: lightText),
        floatingLabelStyle: const TextStyle(color: primaryGold),
        hintStyle: const TextStyle(color: Color(0xFF8E8A84)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: goldBorder, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: primaryGold, width: 1),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: danger, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: danger, width: 1.5),
        ),
      ),
    );
  }
}
