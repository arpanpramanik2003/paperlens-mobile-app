import 'package:flutter/material.dart';

import 'landing_palette.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({
    super.key,
    required this.onGetStarted,
    required this.onExplore,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final titleSize = width < 360 ? 30.0 : (width < 440 ? 36.0 : 44.0);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: LandingPalette.accent,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'AI-Powered Research Assistant',
                  style: TextStyle(
                    color: LandingPalette.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Understand Research Papers\nin Minutes, Not Hours',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: titleSize,
              fontWeight: FontWeight.w800,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Analyze papers, generate ideas, detect research gaps, and plan experiments with one unified AI workflow.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: LandingPalette.textMuted,
              height: 1.5,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onGetStarted,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Get Started'),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF05342D),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onExplore,
                icon: const Icon(Icons.explore_rounded),
                label: const Text('Explore'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
