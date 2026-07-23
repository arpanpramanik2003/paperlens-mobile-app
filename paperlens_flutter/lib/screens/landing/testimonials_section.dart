import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'landing_theme.dart';

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({
    super.key,
    this.isDarkMode = true,
  });

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    final testimonials = const [
      (
        name: 'Dr. Sarah Chen',
        role: 'AI Senior Researcher @ Stanford Univ',
        quote: 'PaperLens AI saved me 100+ hours during my literature review for NeurIPS. The Gap Detection feature highlighted an unaddressed baseline issue that became the centerpiece of our paper.',
        avatarText: 'SC',
        accent: SaaSTheme.primaryTeal,
      ),
      (
        name: 'James Okonkwo',
        role: 'PhD Candidate @ MIT CSAIL',
        quote: 'The Citation Intelligence graph is pure genius. Instead of reading 50 references manually, PaperLens maps out which papers actually contributed foundational proofs vs incremental tweaks.',
        avatarText: 'JO',
        accent: SaaSTheme.accentViolet,
      ),
      (
        name: 'Prof. Maria Garcia',
        role: 'Biomedical Engineering Chair @ ETH Zürich',
        quote: 'Finally, an AI research assistant built with true academic rigor! It understands complex mathematical notation and produces verifiable experiment blueprints.',
        avatarText: 'MG',
        accent: SaaSTheme.accentCyan,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: SaaSTheme.pillDecoration(
              isDark: isDark,
              glowColor: SaaSTheme.accentAmber,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.star_rounded, size: 14, color: SaaSTheme.accentAmber),
                SizedBox(width: 6),
                Text(
                  'RESEARCHER TESTIMONIALS',
                  style: TextStyle(
                    color: SaaSTheme.accentAmber,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Trusted by World-Class Minds',
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
            'See how leading scientists accelerate discovery using PaperLens AI.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Cards List/Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              return Flex(
                direction: isWide ? Axis.horizontal : Axis.vertical,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: testimonials.map((t) {
                  return Expanded(
                    flex: isWide ? 1 : 0,
                    child: Container(
                      margin: EdgeInsets.only(
                        bottom: isWide ? 0 : 16,
                        right: isWide && testimonials.indexOf(t) < testimonials.length - 1 ? 14 : 0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: SaaSTheme.glassCardDecoration(
                          isDark: isDark,
                          borderRadius: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 5 Star rating
                            Row(
                              children: List.generate(
                                5,
                                (i) => const Icon(
                                  Icons.star_rounded,
                                  color: SaaSTheme.accentAmber,
                                  size: 16,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '"${t.quote}"',
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: textColor,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        t.accent,
                                        t.accent.withValues(alpha: 0.6),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    t.avatarText,
                                    style: const TextStyle(
                                      color: Color(0xFF041814),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        t.role,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: subtextColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}
