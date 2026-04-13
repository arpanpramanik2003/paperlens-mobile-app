import 'package:flutter/material.dart';

import 'landing_palette.dart';

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
  });

  final String logoAsset;
  final bool darkMode;
  final VoidCallback onToggleTheme;
  final VoidCallback onHome;
  final VoidCallback onExplore;
  final VoidCallback onHowItWorks;
  final VoidCallback onAbout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 520;
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.16),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              compact ? 12 : 16,
              10,
              compact ? 12 : 16,
              10,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.asset(
                              logoAsset,
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'PaperLens AI',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: LandingPalette.textStrong,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onToggleTheme,
                      tooltip: darkMode
                          ? 'Switch to light mode'
                          : 'Switch to dark mode',
                      icon: Icon(
                        darkMode
                            ? Icons.light_mode_rounded
                            : Icons.dark_mode_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _navPill('Home', onHome),
                      _navPill('Explore', onExplore),
                      _navPill('How it works', onHowItWorks),
                      _navPill('About', onAbout),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _navPill(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            color: Colors.white.withValues(alpha: 0.06),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: LandingPalette.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
