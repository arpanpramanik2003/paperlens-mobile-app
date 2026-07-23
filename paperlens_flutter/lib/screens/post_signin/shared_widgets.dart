import 'package:flutter/material.dart';
import '../landing/landing_theme.dart';

class PostSigninStatusPill extends StatelessWidget {
  const PostSigninStatusPill({
    super.key,
    required this.label,
    required this.healthy,
  });

  final String label;
  final bool healthy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: healthy
            ? const Color(0xFFB9F6CA).withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: healthy
              ? const Color(0xFFB9F6CA).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class PostSigninSectionCard extends StatelessWidget {
  const PostSigninSectionCard({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.stars_rounded,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    return Container(
      padding: const EdgeInsets.all(18),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: subtextColor,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class PostSigninInfoBox extends StatelessWidget {
  const PostSigninInfoBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? SaaSTheme.surfaceDark.withValues(alpha: 0.55)
            : SaaSTheme.bgLightSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          height: 1.45,
          color: isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight,
        ),
      ),
    );
  }
}
