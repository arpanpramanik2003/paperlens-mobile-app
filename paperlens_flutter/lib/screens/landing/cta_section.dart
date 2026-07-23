import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'landing_theme.dart';

class CtaSection extends StatelessWidget {
  const CtaSection({
    super.key,
    required this.onGetStarted,
    this.isDarkMode = true,
  });

  final VoidCallback onGetStarted;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 400;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 16 : 28,
        vertical: isSmall ? 22 : 28,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF0F262C),
                  Color(0xFF1B1B3A),
                  Color(0xFF0C1E26),
                ]
              : const [
                  Color(0xFFE0F2FE),
                  Color(0xFFF3E8FF),
                  Color(0xFFE0F2FE),
                ],
        ),
        border: Border.all(
          color: isDark ? SaaSTheme.borderDarkGlowing : SaaSTheme.primaryTealDark.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.accentViolet).withValues(alpha: 0.2),
            blurRadius: 30,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: SaaSTheme.pillDecoration(
              isDark: isDark,
              glowColor: SaaSTheme.primaryTeal,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.rocket_launch_rounded, size: 13, color: SaaSTheme.primaryTeal),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'JOIN 50,000+ RESEARCHERS TODAY',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: SaaSTheme.primaryTeal,
                      fontSize: isSmall ? 10 : 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: isSmall ? 0.4 : 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'Ready to Supercharge Your Research?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmall ? 21 : 26,
              fontWeight: FontWeight.w900,
              color: isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),

          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: Text(
              'Get instant AI analysis for your research papers, citation graphs, and experiment blueprints in under 60 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSmall ? 13 : 14,
                height: 1.5,
                color: isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight,
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Primary Gradient Button
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: SaaSTheme.brandButtonGradient,
              boxShadow: [
                BoxShadow(
                  color: SaaSTheme.primaryTeal.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onGetStarted,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 16 : 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.flash_on_rounded, color: Color(0xFF041814), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Get Started Free — Instant Access',
                      style: TextStyle(
                        fontSize: isSmall ? 14 : 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF041814),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Trust Guarantee Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user_rounded,
                size: 13,
                color: isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  'No credit card required • Free plan available',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSmall ? 11 : 12,
                    color: isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms);
  }
}
