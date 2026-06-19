import 'package:flutter/material.dart';

class AppTheme {
  // Keeping our deep colors centralized as static constants
  static const Color slateDarkest = Color(0xFF020617);
  static const Color slateDark = Color(0xFF0F172A);
  static const Color tealAccent = Color(0xFF2DD4BF);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: slateDarkest,
      appBarTheme: const AppBarTheme(
        backgroundColor: slateDark,
        elevation: 0,
      ),
      // Styling the input forms universally across all feature panels
      inputDecorationTheme: const InputDecorationTheme(
        labelStyle: TextStyle(color: Colors.white38),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: tealAccent)),
      ),
    );
  }
}