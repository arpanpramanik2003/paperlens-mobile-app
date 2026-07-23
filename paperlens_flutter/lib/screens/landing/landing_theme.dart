import 'package:flutter/material.dart';

/// Unified SaaS Design System & Color Palette for PaperLens AI
class SaaSTheme {
  // --- Dark Mode Colors ---
  static const Color bgDark = Color(0xFF060D12);
  static const Color bgDarkSecondary = Color(0xFF0B161E);
  static const Color surfaceDark = Color(0xFF0F2029);
  static const Color cardDark = Color(0xFF142934);
  static const Color cardDarkHover = Color(0xFF1B3543);
  
  static const Color borderDark = Color(0xFF1E3B49);
  static const Color borderDarkGlowing = Color(0x6600E6C3);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textMutedDark = Color(0xFF94A3B8);
  static const Color textSubtleDark = Color(0xFF64748B);

  // --- Light Mode Colors ---
  static const Color bgLight = Color(0xFFF8FAFC);
  static const Color bgLightSecondary = Color(0xFFF1F5F9);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardLightHover = Color(0xFFF1F5F9);

  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderLightGlowing = Color(0x66006A60);

  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textMutedLight = Color(0xFF475569);
  static const Color textSubtleLight = Color(0xFF94A3B8);

  // --- Core Brand Accents ---
  static const Color primaryTeal = Color(0xFF00E6C3);
  static const Color primaryTealDark = Color(0xFF00A88F);
  static const Color accentViolet = Color(0xFF8B5CF6);
  static const Color accentCyan = Color(0xFF00BAFF);
  static const Color accentMagenta = Color(0xFFEC4899);
  static const Color accentAmber = Color(0xFFF59E0B);
  static const Color accentEmerald = Color(0xFF10B981);

  // --- Gradients ---
  static const Gradient heroTextGradient = LinearGradient(
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFF80EEEC),
      Color(0xFF8B5CF6),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient heroTextGradientLight = LinearGradient(
    colors: [
      Color(0xFF0F172A),
      Color(0xFF006A60),
      Color(0xFF6D28D9),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient brandButtonGradient = LinearGradient(
    colors: [
      Color(0xFF00E6C3),
      Color(0xFF00BAFF),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const Gradient violetButtonGradient = LinearGradient(
    colors: [
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  /// Mesh background gradient for Landing page
  static BoxDecoration backgroundDecoration(bool isDark) {
    if (isDark) {
      return const BoxDecoration(
        color: bgDark,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF08141B),
            Color(0xFF060D12),
            Color(0xFF0A1821),
            Color(0xFF060D12),
          ],
        ),
      );
    } else {
      return const BoxDecoration(
        color: bgLight,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF0FDFA),
            Color(0xFFF8FAFC),
            Color(0xFFEFF6FF),
            Color(0xFFF8FAFC),
          ],
        ),
      );
    }
  }

  /// Glass Card Decoration
  static BoxDecoration glassCardDecoration({
    required bool isDark,
    Color? customBorderColor,
    double borderRadius = 20,
    bool isHovered = false,
  }) {
    final border = customBorderColor ??
        (isDark
            ? (isHovered ? borderDarkGlowing : borderDark)
            : (isHovered ? borderLightGlowing : borderLight));

    return BoxDecoration(
      color: isDark
          ? (isHovered ? cardDarkHover : cardDark).withValues(alpha: 0.85)
          : (isHovered ? cardLightHover : cardLight).withValues(alpha: 0.90),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: border, width: 1.2),
      boxShadow: [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.35)
              : const Color(0xFF0F172A).withValues(alpha: 0.05),
          blurRadius: isHovered ? 20 : 12,
          offset: const Offset(0, 6),
        ),
        if (isHovered && isDark)
          BoxShadow(
            color: primaryTeal.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: -2,
          ),
      ],
    );
  }

  /// Glowing pill container decoration
  static BoxDecoration pillDecoration({
    required bool isDark,
    Color? glowColor,
  }) {
    final baseGlow = glowColor ?? (isDark ? primaryTeal : const Color(0xFF006A60));
    return BoxDecoration(
      color: baseGlow.withValues(alpha: isDark ? 0.12 : 0.08),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(
        color: baseGlow.withValues(alpha: isDark ? 0.35 : 0.25),
        width: 1,
      ),
    );
  }

  /// Shader Text Helper
  static Widget gradientText(
    String text, {
    required TextStyle style,
    Gradient gradient = heroTextGradient,
    TextAlign textAlign = TextAlign.start,
  }) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        textAlign: textAlign,
        style: style,
      ),
    );
  }
}
