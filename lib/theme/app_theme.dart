import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color bg = Color(0xFF0B1020);
  static const Color surface = Color(0xFF161C2E);
  static const Color surfaceHigh = Color(0xFF1F2740);
  static const Color accent = Color(0xFF6E8EFF);
  static const Color accent2 = Color(0xFF9D7BFF);
  static const Color danger = Color(0xFFFF5C7A);
  static const Color success = Color(0xFF3DD68C);
  static const Color warn = Color(0xFFFFB84D);
  static const Color text = Color(0xFFEEF1F8);
  static const Color muted = Color(0xFF8A93A8);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent2,
        surface: surface,
        error: danger,
      ),
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme).apply(
        bodyColor: text,
        displayColor: text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}
