import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'landing_theme.dart';

class FeatureItem {
  final IconData icon;
  final String title;
  final String category;
  final String description;
  final String detailedPreview;
  final Color accentColor;

  const FeatureItem({
    required this.icon,
    required this.title,
    required this.category,
    required this.description,
    required this.detailedPreview,
    required this.accentColor,
  });
}

class FeaturesSection extends StatefulWidget {
  const FeaturesSection({
    super.key,
    this.isDarkMode = true,
  });

  final bool isDarkMode;

  @override
  State<FeaturesSection> createState() => _FeaturesSectionState();
}

class _FeaturesSectionState extends State<FeaturesSection> {
  int? _hoveredIndex;

  static const List<FeatureItem> _features = [
    FeatureItem(
      icon: Icons.psychology_rounded,
      title: 'Paper Analyzer',
      category: 'CORE SYNTHESIS',
      description: 'Instant PDF breakdown into core methodology, equations, key claims, and contextual Q&A.',
      detailedPreview: '• Extracts key equations and mathematical proofs into plain English.\n• Identifies dataset specs, hardware baseline, and reported metrics.\n• Interactive paper chat powered by multi-modal LLM reasoning.',
      accentColor: SaaSTheme.primaryTeal,
    ),
    FeatureItem(
      icon: Icons.hub_rounded,
      title: 'Citation Intelligence',
      category: 'GRAPH NETWORK',
      description: 'Interactive citation influence graphs, reference impact scores, and paper pedigree mapping.',
      detailedPreview: '• Maps foundational ancestor papers and downstream derivative works.\n• Scores citation influence vs self-citation metrics.\n• Detects missing literature links in your reference drafts.',
      accentColor: SaaSTheme.accentCyan,
    ),
    FeatureItem(
      icon: Icons.find_in_page_rounded,
      title: 'Gap Detection',
      category: 'OPPORTUNITY MINER',
      description: 'Uncover unaddressed limitations, parameter edge-cases, and unexplored research avenues.',
      detailedPreview: '• Scans paper discussion & limitation sections for open challenges.\n• Cross-references competing methodologies to spot unverified assumptions.\n• Ranks research gaps by feasibility & publication potential.',
      accentColor: SaaSTheme.accentViolet,
    ),
    FeatureItem(
      icon: Icons.auto_awesome_rounded,
      title: 'Problem Generator',
      category: 'HYPOTHESIS CREATOR',
      description: 'AI-driven formulation of novel research questions, problem statements, and test hypotheses.',
      detailedPreview: '• Generates high-impact research proposals tailored to your field.\n• Adjustable difficulty & innovation sliders (Incremental vs Paradigm Shift).\n• Synthesizes multi-disciplinary paper concepts into fresh project ideas.',
      accentColor: SaaSTheme.accentMagenta,
    ),
    FeatureItem(
      icon: Icons.dataset_rounded,
      title: 'Dataset & Benchmark Finder',
      category: 'SOTA MATRIX',
      description: 'Discover state-of-the-art benchmarks, evaluation metrics, and open-source dataset repos.',
      detailedPreview: '• Live SOTA leaderboards across ImageNet, SuperGLUE, MMLU, and custom benchmarks.\n• Recommends domain-specific dataset splits and preprocessing scripts.\n• Compares model FLOPs, parameter counts, and latency tradeoffs.',
      accentColor: SaaSTheme.accentAmber,
    ),
    FeatureItem(
      icon: Icons.science_rounded,
      title: 'Experiment Planner',
      category: 'ROADMAP BUILDER',
      description: 'Step-by-step experiment blueprints, ablation study matrices, and statistical validation checklists.',
      detailedPreview: '• Generates structured methodology steps from hypothesis to manuscript.\n• Prepares ablation study tables to isolate key module contributions.\n• Suggests statistical confidence tests (p-value, ANOVA) for your domain.',
      accentColor: SaaSTheme.accentEmerald,
    ),
  ];

  void _showFeatureDetails(BuildContext context, FeatureItem item, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? SaaSTheme.bgDarkSecondary : SaaSTheme.bgLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: item.accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(item.icon, color: item.accentColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.category,
                          style: TextStyle(
                            color: item.accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.title,
                          style: TextStyle(
                            color: isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item.description,
                style: TextStyle(
                  color: isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 14, color: item.accentColor),
                        const SizedBox(width: 6),
                        Text(
                          'Capabilities Breakdown',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.detailedPreview,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text('Got It'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.accentColor,
                    foregroundColor: const Color(0xFF041814),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Section Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: SaaSTheme.pillDecoration(
              isDark: isDark,
              glowColor: SaaSTheme.accentViolet,
            ),
            child: const Text(
              'INTELLIGENT RESEARCH SUITE',
              style: TextStyle(
                color: SaaSTheme.accentViolet,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Section Title
          Text(
            'Everything You Need to Master Research',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '6 powerful AI tools built specifically for scientists, PhD candidates, and AI engineers.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtextColor,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Feature Grid Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 640;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: List.generate(_features.length, (index) {
                  final item = _features[index];
                  final isHovered = _hoveredIndex == index;
                  final width = isWide ? (constraints.maxWidth - 14) / 2 : constraints.maxWidth;

                  return SizedBox(
                    width: width,
                    child: MouseRegion(
                      onEnter: (_) => setState(() => _hoveredIndex = index),
                      onExit: (_) => setState(() => _hoveredIndex = null),
                      child: GestureDetector(
                        onTap: () => _showFeatureDetails(context, item, isDark),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(18),
                          decoration: SaaSTheme.glassCardDecoration(
                            isDark: isDark,
                            borderRadius: 18,
                            isHovered: isHovered,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: item.accentColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: item.accentColor.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Icon(item.icon, color: item.accentColor, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.category,
                                          style: TextStyle(
                                            color: item.accentColor,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 1.1,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            color: textColor,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: isHovered
                                        ? item.accentColor
                                        : (isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.description,
                                style: TextStyle(
                                  color: subtextColor,
                                  fontSize: 13,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: (100 * index).ms, duration: 500.ms);
                }),
              );
            },
          ),
        ],
      ),
    );
  }
}
