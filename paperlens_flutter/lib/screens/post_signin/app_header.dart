import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import '../landing/landing_theme.dart';

class PostSigninHeader extends StatelessWidget {
  const PostSigninHeader({
    super.key,
    required this.sectionIndex,
    required this.onRefreshToken,
    this.isDarkMode = true,
    this.onToggleTheme,
  });

  final int sectionIndex;
  final VoidCallback onRefreshToken;
  final bool isDarkMode;
  final VoidCallback? onToggleTheme;

  static const _meta = [
    (
      'Dashboard Overview',
      'Track platform activity, spot research trends, and manage saved items.',
      Icons.dashboard_customize_rounded,
      ['Metrics snapshot', 'Trend visibility', 'Quick launchpad'],
    ),
    (
      'Paper Analyzer',
      'Extract key equations, summary proofs, and ask contextual paper questions.',
      Icons.description_rounded,
      ['Upload PDF/DOCX', 'Context Q&A', 'Evidence summary'],
    ),
    (
      'Citation Intelligence',
      'Inspect paper references, locate missing links, and map network impact.',
      Icons.auto_graph_rounded,
      ['Citation mapping', 'Coverage gaps', 'Reading paths'],
    ),
    (
      'Gap Detection',
      'Identify underexplored research opportunities from raw text or PDFs.',
      Icons.search_rounded,
      ['Literature scanning', 'Opportunity ranking', '1-Tap save'],
    ),
    (
      'Problem Generator',
      'Formulate novel hypotheses and expand directions into execution briefs.',
      Icons.lightbulb_rounded,
      ['Brainstorming', 'Hypothesis briefs', 'Methodology plans'],
    ),
    (
      'Dataset & Benchmark Finder',
      'Discover fitting datasets, benchmark targets, and tool recommendations.',
      Icons.dataset_rounded,
      ['Curated datasets', 'Leaderboard targets', 'Tool mapping'],
    ),
    (
      'Experiment Planner',
      'Convert topics into practical execution blueprints tailored by difficulty.',
      Icons.science_rounded,
      ['Stepwise plans', 'Difficulty presets', 'Execution format'],
    ),
    (
      'Settings & Workspace',
      'Manage profile details, visual appearance, and saved research items.',
      Icons.settings_rounded,
      ['Researcher profile', 'Theme controls', 'Saved briefs'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    final safeIndex = sectionIndex.clamp(0, _meta.length - 1);
    final section = _meta[safeIndex];

    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 2),
      decoration: SaaSTheme.glassCardDecoration(
        isDark: isDark,
        borderRadius: 14,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Section Icon + Title + Compact User Profile Avatar
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      section.$3,
                      color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      section.$1,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),

                  // Compact User Profile Avatar
                  Builder(
                    builder: (context) {
                      try {
                        final auth = ClerkAuth.of(context, listen: true);
                        final user = auth.user;
                        final firstName = user?.firstName ?? 'Researcher';
                        final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'R';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircleAvatar(
                                radius: 9,
                                backgroundColor: SaaSTheme.primaryTeal,
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Color(0xFF041814),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  firstName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } catch (_) {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Fixed Height Description Area (Never flexes or changes box size across tabs)
              SizedBox(
                height: 32,
                child: Text(
                  section.$2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 11,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
