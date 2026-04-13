import 'package:flutter/material.dart';

import 'landing_palette.dart';

class WhyPaperLensSection extends StatelessWidget {
  const WhyPaperLensSection({super.key});

  @override
  Widget build(BuildContext context) {
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
            'Why PaperLens AI?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _panel(
            title: 'Precisely configurable',
            points: const [
              'Custom inclusion and exclusion logic',
              'Criteria-level confidence signals',
              'One-tap recommendation override',
            ],
          ),
          const SizedBox(height: 8),
          _panel(
            title: 'Evidence-linked reasoning',
            points: const [
              'Transparent why-included explanation',
              'Criteria detail tags',
              'Quote-first interpretation workflow',
            ],
          ),
        ],
      ),
    );
  }

  Widget _panel({required String title, required List<String> points}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF143A34),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...points.map(
            (point) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: LandingPalette.accent,
                      size: 15,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      point,
                      style: const TextStyle(color: LandingPalette.textMuted),
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
