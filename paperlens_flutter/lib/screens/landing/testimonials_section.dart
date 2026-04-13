import 'package:flutter/material.dart';

import 'landing_palette.dart';

class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = const [
      (
        'Dr. Sarah Chen',
        'ML Researcher, Stanford',
        'Saved me hours of literature review. The gap detection is remarkably accurate.',
      ),
      (
        'James Okonkwo',
        'PhD Candidate, MIT',
        'Best AI tool for academic work. The experiment planner changed how I approach research.',
      ),
      (
        'Prof. Maria Garcia',
        'Biomedical Engineering, ETH',
        'Finally, an AI tool that understands academic rigor. Highly recommended.',
      ),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2F2A).withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loved by Researchers',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...cards.map(
            (card) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF143A34),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: LandingPalette.accent,
                        size: 16,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: LandingPalette.accent,
                        size: 16,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: LandingPalette.accent,
                        size: 16,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: LandingPalette.accent,
                        size: 16,
                      ),
                      Icon(
                        Icons.star_rounded,
                        color: LandingPalette.accent,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '"${card.$3}"',
                    style: const TextStyle(
                      color: LandingPalette.textMuted,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    card.$1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    card.$2,
                    style: const TextStyle(
                      color: LandingPalette.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
