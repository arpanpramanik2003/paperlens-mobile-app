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
      'Citation Intelligence',
      'Inspect references, locate missing links, and build stronger reading paths for more rigorous projects.',
      Icons.auto_graph_rounded,
      ['Citation mapping', 'Coverage gaps', 'Reading guidance'],
    ),
    (
      'Gap Detection',
      'Identify underexplored opportunities from your text or uploaded documents and turn them into next actions.',
      Icons.search_rounded,
      ['Text or file input', 'Opportunity surfacing', 'Action suggestions'],
    ),
    (
      'Problem Generator',
      'Generate novel research ideas and expand promising directions into structured implementation briefs.',
      Icons.lightbulb_rounded,
      ['Idea brainstorming', 'Structured expansions', 'Save reusable briefs'],
    ),
    (
      'Dataset and Benchmark Finder',
      'Discover fitting datasets, benchmark targets, and tool recommendations aligned with your project scope.',
      Icons.dataset_rounded,
      ['Curated datasets', 'Benchmark mapping', 'Technology suggestions'],
    ),
    (
      'Experiment Planner',
      'Convert topics into practical, stepwise execution plans tailored by difficulty and clarity of scope.',
      Icons.science_rounded,
      ['Guided plan steps', 'Difficulty presets', 'Execution-friendly format'],
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
    final isDark = isDarkMode;
    final safeIndex = sectionIndex.clamp(0, _meta.length - 1);
    final section = _meta[safeIndex];

    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      decoration: SaaSTheme.glassCardDecoration(
        isDark: isDark,
        borderRadius: 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Row: Section Icon + Title + Compact User Badge & Actions
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      section.$3,
                      color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: SaaSTheme.primaryTeal,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Cloud Active',
                              style: TextStyle(
                                color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Compact User Profile Avatar (from Clerk)
                  Builder(
                    builder: (context) {
                      try {
                        final auth = ClerkAuth.of(context, listen: true);
                        final user = auth.user;
                        final firstName = user?.firstName ?? 'User';
                        final initial = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'U';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                                radius: 10,
                                backgroundColor: SaaSTheme.primaryTeal,
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    color: Color(0xFF041814),
                                    fontSize: 10,
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
                                    fontSize: 11,
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
                  const SizedBox(width: 4),

                  SizedBox(
                    width: 32,
                    height: 32,
                    child: IconButton(
                      onPressed: onRefreshToken,
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.sync_rounded,
                        color: isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight,
                        size: 16,
                      ),
                      tooltip: 'Sync Session Token',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Full Readable Description (No line cut off or "..." ellipsis)
              Text(
                section.$2,
                style: TextStyle(
                  color: subtextColor,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 8),

              // Compact Feature Badges
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: section.$4
                      .map(
                        (point) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? SaaSTheme.surfaceDark.withValues(alpha: 0.7)
                                  : SaaSTheme.bgLightSecondary,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
                              ),
                            ),
                            child: Text(
                              point,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
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
        ),
      ),
    );
  }
}
