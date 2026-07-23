import 'package:flutter/material.dart';
import 'landing_theme.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({
    super.key,
    required this.logoAsset,
    required this.onOpenAbout,
    this.isDarkMode = true,
  });

  final String logoAsset;
  final VoidCallback onOpenAbout;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      padding: const EdgeInsets.all(20),
      decoration: SaaSTheme.glassCardDecoration(
        isDark: isDark,
        borderRadius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SaaSTheme.brandButtonGradient,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Image.asset(
                    logoAsset,
                    width: 26,
                    height: 26,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'PaperLens AI',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
                  ),
                ),
                child: Text(
                  'v2.4.0 Engine',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subtextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The all-in-one AI research suite helping scientists, engineers, and PhD candidates master papers, uncover gaps, and plan experiments.',
            style: TextStyle(
              color: subtextColor,
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight, height: 1),
          const SizedBox(height: 14),

          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton.icon(
                    onPressed: onOpenAbout,
                    icon: Icon(
                      Icons.info_outline_rounded,
                      size: 14,
                      color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                    ),
                    label: Text(
                      'About PaperLens',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '© ${DateTime.now().year} PaperLens AI Inc. All rights reserved.',
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
