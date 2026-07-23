import 'dart:ui';
import 'package:flutter/material.dart';
import 'landing_theme.dart';

class LandingNavbar extends StatelessWidget {
  const LandingNavbar({
    super.key,
    required this.logoAsset,
    required this.darkMode,
    required this.onToggleTheme,
    required this.onHome,
    required this.onExplore,
    required this.onHowItWorks,
    required this.onAbout,
    this.onSignIn,
  });

  final String logoAsset;
  final bool darkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onHome;
  final VoidCallback onExplore;
  final VoidCallback onHowItWorks;
  final VoidCallback onAbout;
  final VoidCallback? onSignIn;

  @override
  Widget build(BuildContext context) {
    final isDark = darkMode;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? SaaSTheme.bgDark.withValues(alpha: 0.75)
                : SaaSTheme.bgLight.withValues(alpha: 0.85),
            border: Border(
              bottom: BorderSide(
                color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Logo + Brand Title + Status Badge
                  Flexible(
                    child: GestureDetector(
                      onTap: onHome,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SaaSTheme.brandButtonGradient,
                            boxShadow: [
                              BoxShadow(
                                color: SaaSTheme.primaryTeal.withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Image.asset(
                              logoAsset,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'PaperLens',
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                SaaSTheme.gradientText(
                                  'AI',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                  gradient: isDark
                                      ? SaaSTheme.heroTextGradient
                                      : SaaSTheme.heroTextGradientLight,
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: SaaSTheme.primaryTeal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Research Suite v2.4',
                                  style: TextStyle(
                                    color: subtextColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                  // Actions: Theme toggle & Sign In button
                  Row(
                    children: [
                      IconButton(
                        onPressed: onToggleTheme,
                        tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? SaaSTheme.surfaceDark
                              : SaaSTheme.bgLightSecondary,
                          side: BorderSide(
                            color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
                          ),
                        ),
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                          child: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            key: ValueKey(isDark),
                            size: 18,
                            color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.accentViolet,
                          ),
                        ),
                      ),
                      if (onSignIn != null) ...[
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: onSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.surfaceLight,
                            foregroundColor: textColor,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            side: BorderSide(
                              color: isDark ? SaaSTheme.borderDarkGlowing : SaaSTheme.primaryTealDark,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Navigation links row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _navItem('Home', Icons.home_rounded, onHome, isDark),
                    _navItem('Features', Icons.auto_awesome_rounded, onExplore, isDark),
                    _navItem('How It Works', Icons.account_tree_rounded, onHowItWorks, isDark),
                    _navItem('About', Icons.info_outline_rounded, onAbout, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(String label, IconData icon, VoidCallback onTap, bool isDark) {
    final color = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? SaaSTheme.surfaceDark.withValues(alpha: 0.6) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
