import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF00D4FF);
  static const Color secondary = Color(0xFF7B2FFF);
  static const Color background = Color(0xFF0A0A0F);
  static const Color surface = Color(0xFF12121A);
  static const Color surfaceVariant = Color(0xFF1C1C28);
  static const Color accent = Color(0xFFFF3D6B);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      background: background,
      surface: surface,
    ),
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
      ),
    ),
  );
}
