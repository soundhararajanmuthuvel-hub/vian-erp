import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VianTheme {
  static const Color primaryGold = Color(0xFFD4AF37); // Architectural Gold
  static const Color darkBackground = Color(0xFFF8FAFC); // Slate clean background
  static const Color headerBlack = Color(0xFF0F172A); // Premium Slate Dark
  static const Color cardColor = Color(0xFFFFFFFF); // Card white background
  static const Color whiteText = Color(0xFF0F172A); // High contrast text on light bg
  static const Color lightText = Color(0xFF475569); // slate-600 body text
  static const Color goldBorder = Color(0xFFD4AF37);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color accentBlue = Color(0xFF2563EB); // Accent Blue
  static const Color sidebarBg = Color(0xFF111827); // Sidebar deep charcoal

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryGold,
      colorScheme: const ColorScheme.light(
        primary: primaryGold,
        secondary: accentBlue,
        background: darkBackground,
        surface: cardColor,
        onPrimary: sidebarBg,
        onSecondary: headerBlack,
        onBackground: headerBlack,
        onSurface: lightText,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme.copyWith(
          displayLarge: const TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: headerBlack),
          titleLarge: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600, color: headerBlack),
          bodyLarge: const TextStyle(fontSize: 16.0, color: headerBlack),
          bodyMedium: const TextStyle(fontSize: 14.0, color: lightText),
          labelLarge: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: primaryGold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardColor,
        elevation: 0,
        iconTheme: IconThemeData(color: headerBlack),
        titleTextStyle: TextStyle(
          color: headerBlack,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: sidebarBg,
        elevation: 16,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: Colors.black.withOpacity(0.04), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: headerBlack,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: headerBlack,
          side: const BorderSide(color: headerBlack, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: lightText),
        floatingLabelStyle: const TextStyle(color: headerBlack),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: headerBlack, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
      ),
    );
  }
}
