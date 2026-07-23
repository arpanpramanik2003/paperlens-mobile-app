import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'landing_theme.dart';

class SocialProofSection extends StatelessWidget {
  const SocialProofSection({
    super.key,
    this.isDarkMode = true,
  });

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;

    final labs = const [
      'MIT AI Lab',
      'Stanford Univ',
      'Oxford AI',
      'ETH Zürich',
      'IEEE',
      'arXiv',
      'Nature',
      'ACM Digital',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: SaaSTheme.glassCardDecoration(
        isDark: isDark,
        borderRadius: 20,
      ),
      child: Column(
        children: [
          Text(
            'TRUSTED BY RESEARCHERS & R&D LABS WORLDWIDE',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
              letterSpacing: 1.4,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),

          // Brands Pills
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: labs.map((lab) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark
                      ? SaaSTheme.surfaceDark.withValues(alpha: 0.8)
                      : SaaSTheme.bgLightSecondary,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.school_rounded,
                      size: 13,
                      color: isDark ? SaaSTheme.accentViolet : SaaSTheme.primaryTealDark,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      lab,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),
          Divider(
            color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
            height: 1,
          ),
          const SizedBox(height: 20),

          // Stat Metrics Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 480;
              return Wrap(
                alignment: WrapAlignment.spaceAround,
                spacing: 16,
                runSpacing: 16,
                children: [
                  _statTile('50,000+', 'Papers Processed', Icons.analytics_rounded, isDark, isNarrow),
                  _statTile('99.4%', 'Extraction Precision', Icons.verified_rounded, isDark, isNarrow),
                  _statTile('10x', 'Faster Lit Review', Icons.bolt_rounded, isDark, isNarrow),
                  _statTile('4.9/5', 'Researcher Score', Icons.star_rounded, isDark, isNarrow),
                ],
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }

  Widget _statTile(String value, String label, IconData icon, bool isDark, bool isNarrow) {
    return SizedBox(
      width: isNarrow ? 115 : 130,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
              ),
              const SizedBox(width: 4),
              SaaSTheme.gradientText(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
                gradient: isDark ? SaaSTheme.heroTextGradient : SaaSTheme.heroTextGradientLight,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
