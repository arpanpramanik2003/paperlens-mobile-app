import 'package:flutter/material.dart';

class LandingPalette {
  static const Color accent = Color(0xFF8CF6E0);
  static const Color textStrong = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFFD8F2ED);

  static LinearGradient background(bool darkMode) {
    return LinearGradient(
      begin: const Alignment(-0.9, -1),
      end: const Alignment(1, 1),
      colors: darkMode
          ? const [Color(0xFF061A17), Color(0xFF0A2F2A), Color(0xFF123B33)]
          : const [Color(0xFF052A24), Color(0xFF0A4B42), Color(0xFF0F5E52)],
    );
  }
}
