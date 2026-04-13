import 'package:flutter/material.dart';

import 'landing_palette.dart';

class FeaturesSection extends StatelessWidget {
  const FeaturesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final features = const [
      (
        Icons.description_rounded,
        'Paper Analyzer',
        'Upload and summarize dense papers with contextual follow-up Q&A.',
      ),
      (
        Icons.science_rounded,
        'Experiment Planner',
        'Turn a topic into a practical experiment roadmap with stepwise outputs.',
      ),
      (
        Icons.lightbulb_rounded,
        'Problem Generator',
        'Generate novel research ideas and expand them by complexity level.',
      ),
      (
        Icons.search_rounded,
        'Gap Detection',
        'Find underexplored angles from your notes or uploaded papers.',
      ),
      (
        Icons.dataset_rounded,
        'Dataset Finder',
        'Get dataset and benchmark recommendations tailored to your project.',
      ),
      (
        Icons.auto_graph_rounded,
        'Citation Intelligence',
        'Analyze references, identify missing citations, and improve rigor.',
      ),
    ];

    return _sectionShell(
      title: 'Explore Features',
      child: Column(
        children: features
            .map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF143A34),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: LandingPalette.accent.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.$1, color: LandingPalette.accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$2,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.$3,
                            style: const TextStyle(
                              color: LandingPalette.textMuted,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _sectionShell({required String title, required Widget child}) {
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
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
