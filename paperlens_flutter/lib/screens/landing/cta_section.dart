import 'package:flutter/material.dart';

import 'landing_palette.dart';

class CtaSection extends StatelessWidget {
  const CtaSection({super.key, required this.onGetStarted});

  final VoidCallback onGetStarted;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: LandingPalette.accent.withValues(alpha: 0.16),
        border: Border.all(
          color: LandingPalette.accent.withValues(alpha: 0.38),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready to accelerate your research?',
            style: TextStyle(
              fontSize: 19,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start analyzing papers in minutes. No credit card required.',
            style: TextStyle(color: LandingPalette.textMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onGetStarted,
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('Get Started Free'),
            style: FilledButton.styleFrom(
              backgroundColor: LandingPalette.accent,
              foregroundColor: const Color(0xFF05342D),
            ),
          ),
        ],
      ),
    );
  }
}
