import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'landing_theme.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({
    super.key,
    this.isDarkMode = true,
  });

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    final steps = const [
      (
        step: '01',
        title: 'Upload Paper or Paste DOI',
        desc: 'Drag & drop any paper PDF or paste arXiv URLs / DOIs. PaperLens automatically parses figures, formulas, and references.',
        icon: Icons.cloud_upload_rounded,
        accent: SaaSTheme.primaryTeal,
      ),
      (
        step: '02',
        title: 'Multi-Model AI Synthesis',
        desc: 'Our specialized academic LLM pipeline synthesizes core methodologies, extracts key claims, and constructs a live citation graph.',
        icon: Icons.auto_awesome_mosaic_rounded,
        accent: SaaSTheme.accentViolet,
      ),
      (
        step: '03',
        title: 'Actionable Research Roadmap',
        desc: 'Detect hidden research gaps, generate novel project hypotheses, and generate step-by-step experiment blueprints in seconds.',
        icon: Icons.rocket_launch_rounded,
        accent: SaaSTheme.accentCyan,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: SaaSTheme.pillDecoration(
              isDark: isDark,
              glowColor: SaaSTheme.primaryTeal,
            ),
            child: const Text(
              '3-STEP WORKFLOW',
              style: TextStyle(
                color: SaaSTheme.primaryTeal,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'From Raw Paper to Research Breakthrough',
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
            'Accelerate your research pipeline with automated paper intelligence.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Timeline Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: steps.map((item) {
                    final index = steps.indexOf(item);
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: index < steps.length - 1 ? 16 : 0,
                        ),
                        child: _stepCard(item, isDark, textColor, subtextColor),
                      ),
                    );
                  }).toList(),
                );
              }

              return Column(
                children: steps.map((item) {
                  final index = steps.indexOf(item);
                  return Container(
                    margin: EdgeInsets.only(
                      bottom: index < steps.length - 1 ? 16 : 0,
                    ),
                    child: _stepCard(item, isDark, textColor, subtextColor),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _stepCard(
    ({String desc, IconData icon, String step, String title, Color accent}) item,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: SaaSTheme.glassCardDecoration(
        isDark: isDark,
        borderRadius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: item.accent.withValues(alpha: 0.3)),
                ),
                child: Icon(item.icon, color: item.accent, size: 22),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'STEP ${item.step}',
                  style: TextStyle(
                    color: item.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            item.title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.desc,
            style: TextStyle(
              color: subtextColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}
