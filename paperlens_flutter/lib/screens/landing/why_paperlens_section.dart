import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'landing_theme.dart';

class WhyPaperLensSection extends StatelessWidget {
  const WhyPaperLensSection({
    super.key,
    this.isDarkMode = true,
  });

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: SaaSTheme.pillDecoration(
              isDark: isDark,
              glowColor: SaaSTheme.accentViolet,
            ),
            child: const Text(
              'THE PARADIGM SHIFT',
              style: TextStyle(
                color: SaaSTheme.accentViolet,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Why Researchers Switch to PaperLens AI',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Replace tedious manual paper skimming with high-precision AI research intelligence.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Comparison Matrix Layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;

              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Traditional Card
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? SaaSTheme.surfaceDark.withValues(alpha: 0.5) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? SaaSTheme.borderDark : const Color(0xFFFCA5A5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.timer_off_rounded, color: Colors.redAccent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Traditional Lit Review',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? SaaSTheme.textPrimaryDark : const Color(0xFF991B1B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _comparisonRow('4-6 hours spent reading each dense 20-page paper PDF.', false, isDark),
                          _comparisonRow('Manual reference hopping across hundreds of citations.', false, isDark),
                          _comparisonRow('Hard to spot unstated assumptions and research limitations.', false, isDark),
                          _comparisonRow('Disconnected notes and manual experiment planning.', false, isDark),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 16),

                  // PaperLens AI Card
                  Expanded(
                    flex: isWide ? 1 : 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: SaaSTheme.glassCardDecoration(
                        isDark: isDark,
                        borderRadius: 20,
                        isHovered: true,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.bolt_rounded, color: SaaSTheme.primaryTeal, size: 22),
                              const SizedBox(width: 8),
                              SaaSTheme.gradientText(
                                'PaperLens AI Engine',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                                gradient: isDark ? SaaSTheme.heroTextGradient : SaaSTheme.heroTextGradientLight,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _comparisonRow('5-minute deep synthesis, equation translations & instant Q&A.', true, isDark),
                          _comparisonRow('Automated visual citation graph & pedigree mapping.', true, isDark),
                          _comparisonRow('AI-driven gap detection & novel hypothesis formulation.', true, isDark),
                          _comparisonRow('Step-by-step experiment blueprints & metric validation.', true, isDark),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _comparisonRow(String text, bool isPositive, bool isDark) {
    final iconColor = isPositive
        ? SaaSTheme.primaryTeal
        : (isDark ? Colors.redAccent.withValues(alpha: 0.8) : Colors.red);
    final icon = isPositive ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final textColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: textColor,
                fontWeight: isPositive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
