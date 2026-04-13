import 'package:flutter/material.dart';

class PostSigninHeader extends StatelessWidget {
  const PostSigninHeader({
    super.key,
    required this.sectionIndex,
    required this.onRefreshToken,
  });

  final int sectionIndex;
  final VoidCallback onRefreshToken;

  static const _meta = [
    (
      'Dashboard Overview',
      'Track platform activity, spot usage patterns, and quickly validate what matters most right now.',
      Icons.dashboard_customize_rounded,
      [
        'Realtime metrics snapshot',
        'Faster trend visibility',
        'Action-oriented overview',
      ],
    ),
    (
      'Paper Analyzer',
      'Extract core ideas from dense papers and ask contextual follow-up questions without losing momentum.',
      Icons.description_rounded,
      ['Upload PDF or DOCX', 'Context-aware Q&A', 'Evidence-first summaries'],
    ),
    (
      'Experiment Planner',
      'Convert topics into practical, stepwise execution plans tailored by difficulty and clarity of scope.',
      Icons.science_rounded,
      ['Guided plan steps', 'Difficulty presets', 'Execution-friendly format'],
    ),
    (
      'Problem Generator',
      'Generate novel research ideas and expand promising directions into structured implementation briefs.',
      Icons.lightbulb_rounded,
      ['Idea brainstorming', 'Structured expansions', 'Save reusable briefs'],
    ),
    (
      'Gap Detection',
      'Identify underexplored opportunities from your text or uploaded documents and turn them into next actions.',
      Icons.search_rounded,
      ['Text or file input', 'Opportunity surfacing', 'Action suggestions'],
    ),
    (
      'Dataset and Benchmark Finder',
      'Discover fitting datasets, benchmark targets, and tool recommendations aligned with your project scope.',
      Icons.dataset_rounded,
      ['Curated datasets', 'Benchmark mapping', 'Technology suggestions'],
    ),
    (
      'Citation Intelligence',
      'Inspect references, locate missing links, and build stronger reading paths for more rigorous projects.',
      Icons.auto_graph_rounded,
      ['Citation mapping', 'Coverage gaps', 'Reading guidance'],
    ),
    (
      'Settings and Workspace',
      'Manage profile, theme, saved outputs, and session controls for a smoother day-to-day workflow.',
      Icons.settings_rounded,
      ['Profile settings', 'Saved items', 'Session controls'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final safeIndex = sectionIndex.clamp(0, _meta.length - 1);
    final section = _meta[safeIndex];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 178, maxHeight: 178),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D3B35), Color(0xFF0E5D52)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.$3, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  section.$1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: onRefreshToken,
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Refresh session token',
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            section.$2,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: section.$4
                  .map(
                    (point) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          point,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }
}
