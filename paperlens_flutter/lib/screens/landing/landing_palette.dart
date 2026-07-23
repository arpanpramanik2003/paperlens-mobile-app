import 'package:flutter/material.dart';
import 'landing_theme.dart';

/// Legacy bridge pointing to SaaSTheme
class LandingPalette {
  static const Color accent = SaaSTheme.primaryTeal;
  static const Color textStrong = SaaSTheme.textPrimaryDark;
  static const Color textMuted = SaaSTheme.textMutedDark;

  static BoxDecoration backgroundDecoration(bool darkMode) {
    return SaaSTheme.backgroundDecoration(darkMode);
  }

  static LinearGradient background(bool darkMode) {
    if (darkMode) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF08141B),
          Color(0xFF060D12),
          Color(0xFF0A1821),
          Color(0xFF060D12),
        ],
      );
    } else {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF0FDFA),
          Color(0xFFF8FAFC),
          Color(0xFFEFF6FF),
          Color(0xFFF8FAFC),
        ],
      );
    }
  }
}
