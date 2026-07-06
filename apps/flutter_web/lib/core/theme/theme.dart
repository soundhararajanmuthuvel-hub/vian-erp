import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VianTheme {
  static const Color primaryGold = Color(0xFFF5A623);
  static const Color darkBackground = Color(0xFF23232F);
  static const Color headerBlack = Color(0xFF0F0F0F);
  static const Color whiteText = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFFD9D9D9);
  static const Color goldBorder = Color(0xFFC88A12);
  static const Color success = Color(0xFF28A745);
  static const Color warning = Color(0xFFFFC107);
  static const Color danger = Color(0xFFDC3545);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryGold,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: goldBorder,
        background: darkBackground,
        surface: headerBlack,
        onPrimary: headerBlack,
        onSecondary: whiteText,
        onBackground: whiteText,
        onSurface: lightText,
        error: danger,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.dark().textTheme.copyWith(
          displayLarge: const TextStyle(fontSize: 32.0, fontWeight: FontWeight.bold, color: whiteText),
          titleLarge: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600, color: primaryGold),
          bodyLarge: const TextStyle(fontSize: 16.0, color: whiteText),
          bodyMedium: const TextStyle(fontSize: 14.0, color: lightText),
          labelLarge: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500, color: primaryGold),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: headerBlack,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGold),
        titleTextStyle: TextStyle(
          color: primaryGold,
          fontSize: 20.0,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: headerBlack,
        elevation: 16,
      ),
      cardTheme: CardThemeData(
        color: headerBlack,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0x33F5A623), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: headerBlack,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: goldBorder, width: 1.5),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            letterSpacing: 0.8,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryGold,
          side: const BorderSide(color: primaryGold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E26),
        labelStyle: const TextStyle(color: lightText),
        floatingLabelStyle: const TextStyle(color: primaryGold),
        hintStyle: const TextStyle(color: Color(0xFF70707C)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0x33F5A623), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: danger, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
      ),
    );
  }
}
