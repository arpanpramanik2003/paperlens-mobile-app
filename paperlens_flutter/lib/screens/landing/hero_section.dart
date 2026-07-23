import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'landing_theme.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({
    super.key,
    required this.onGetStarted,
    required this.onExplore,
    required this.isDarkMode,
  });

  final VoidCallback onGetStarted;
  final VoidCallback onExplore;
  final bool isDarkMode;

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection> {
  bool _isSimulating = false;
  int _activeMetricTab = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final screenWidth = MediaQuery.of(context).size.width;
    final titleSize = screenWidth < 360 ? 28.0 : (screenWidth < 600 ? 34.0 : 44.0);

    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final mutedTextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Top Glowing Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: SaaSTheme.pillDecoration(
              isDark: isDark,
              glowColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                  size: 16,
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                 .scaleXY(begin: 0.9, end: 1.15, duration: 1200.ms),
                const SizedBox(width: 8),
                Text(
                  'Next-Gen AI Paper Intelligence Engine',
                  style: TextStyle(
                    color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, end: 0),

          const SizedBox(height: 18),

          // Main Headline with Gradient Accent
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                color: textColor,
                fontSize: titleSize,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -1,
                fontFamily: 'Plus Jakarta Sans',
              ),
              children: [
                const TextSpan(text: 'Understand Research Papers\nin '),
                WidgetSpan(
                  child: SaaSTheme.gradientText(
                    'Minutes, Not Hours',
                    style: TextStyle(
                      fontSize: titleSize,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                    gradient: isDark ? SaaSTheme.heroTextGradient : SaaSTheme.heroTextGradientLight,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms, duration: 600.ms).slideY(begin: 0.1, end: 0),

          const SizedBox(height: 14),

          // Subheadline
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Text(
              'PaperLens AI analyzes complex research papers, uncovers hidden citations & research gaps, generates novel hypotheses, and builds experiment blueprints in one unified AI workspace.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: mutedTextColor,
                fontSize: 15,
                height: 1.55,
                fontWeight: FontWeight.w400,
              ),
            ),
          ).animate().fadeIn(delay: 350.ms, duration: 600.ms),

          const SizedBox(height: 24),

          // CTA Action Buttons
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              // Primary CTA Gradient Button
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: SaaSTheme.brandButtonGradient,
                  boxShadow: [
                    BoxShadow(
                      color: SaaSTheme.primaryTeal.withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: widget.onGetStarted,
                  icon: const Text('✨', style: TextStyle(fontSize: 14)),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Start Researching Free',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF041814),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 16,
                        color: Color(0xFF041814),
                      ),
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              // Secondary CTA Outline Button
              OutlinedButton.icon(
                onPressed: widget.onExplore,
                icon: Icon(
                  Icons.explore_rounded,
                  color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                  size: 18,
                ),
                label: Text(
                  'Explore AI Capabilities',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  side: BorderSide(
                    color: isDark ? SaaSTheme.borderDarkGlowing : SaaSTheme.borderLight,
                    width: 1.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: isDark
                      ? SaaSTheme.surfaceDark.withValues(alpha: 0.6)
                      : SaaSTheme.surfaceLight,
                ),
              ),
            ],
          ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideY(begin: 0.15, end: 0),

          const SizedBox(height: 32),

          // --- Interactive Live App Mockup Card ---
          _buildInteractiveMockup(isDark, textColor, mutedTextColor),
        ],
      ),
    );
  }

  Widget _buildInteractiveMockup(bool isDark, Color textColor, Color mutedTextColor) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 720),
      decoration: SaaSTheme.glassCardDecoration(
        isDark: isDark,
        borderRadius: 24,
        isHovered: true,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mockup Card Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? SaaSTheme.bgDarkSecondary : SaaSTheme.bgLightSecondary,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                bottom: BorderSide(
                  color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
                ),
              ),
            ),
            child: LayoutBuilder(
              builder: (context, headerConstraints) {
                final isNarrow = headerConstraints.maxWidth < 360;
                return Row(
                  children: [
                    // Window traffic lights
                    Row(
                      children: [
                        _circleDot(const Color(0xFFFF5F56)),
                        const SizedBox(width: 4),
                        _circleDot(const Color(0xFFFFBD2E)),
                        const SizedBox(width: 4),
                        _circleDot(const Color(0xFF27C93F)),
                      ],
                    ),
                    SizedBox(width: isNarrow ? 8 : 12),
                    // URL / Search bar simulation
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isNarrow ? 6 : 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? SaaSTheme.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 11,
                              color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'paperlens.ai/analyzer',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: mutedTextColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: isNarrow ? 6 : 8),
                    // Live Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: SaaSTheme.primaryTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: SaaSTheme.primaryTeal,
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                           .fadeIn(duration: 800.ms),
                          const SizedBox(width: 4),
                          Text(
                            'LIVE DEMO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Mockup Card Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Paper Badge & Action
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: SaaSTheme.accentViolet.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'arXiv:1706.03762 • Computer Science',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: SaaSTheme.accentViolet,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _isSimulating = !_isSimulating;
                        });
                      },
                      tooltip: _isSimulating ? 'Pause Analysis' : 'Re-run AI Analysis',
                      icon: Icon(
                        _isSimulating ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                        color: SaaSTheme.primaryTeal,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Paper Title
                Text(
                  'Attention Is All You Need',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vaswani et al. (Google Brain & Google Research)',
                  style: TextStyle(
                    fontSize: 12,
                    color: mutedTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),

                // Interactive Metric Tabs - Scrollable on small screens
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _metricTab(0, 'Key Takeaways', Icons.summarize_rounded, isDark),
                      const SizedBox(width: 8),
                      _metricTab(1, 'Citation Graph', Icons.hub_rounded, isDark),
                      const SizedBox(width: 8),
                      _metricTab(2, 'Gaps & Ideas', Icons.lightbulb_rounded, isDark),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Tab Content Card
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? SaaSTheme.bgDarkSecondary : SaaSTheme.bgLightSecondary,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
                    ),
                  ),
                  child: _buildTabContent(isDark, textColor, mutedTextColor),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 650.ms, duration: 700.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _metricTab(int index, String label, IconData icon, bool isDark) {
    final isActive = _activeMetricTab == index;
    return InkWell(
      onTap: () {
        setState(() {
          _activeMetricTab = index;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? SaaSTheme.primaryTeal.withValues(alpha: 0.15) : SaaSTheme.primaryTealDark.withValues(alpha: 0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)
                : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive
                  ? (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)
                  : (isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)
                    : (isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(bool isDark, Color textColor, Color mutedTextColor) {
    switch (_activeMetricTab) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: SaaSTheme.accentEmerald, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Replaces recurrence & convolutions entirely with Self-Attention mechanisms.',
                    style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: SaaSTheme.accentEmerald, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Achieves 28.4 BLEU on WMT 2014 English-to-German, setting a new SOTA speed & accuracy.',
                    style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        );
      case 1:
        return Row(
          children: [
            const Icon(Icons.account_tree_rounded, color: SaaSTheme.accentCyan, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Citation Influence Score: 99.8 / 100',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Influenced 145,000+ downstream papers in Transformer LLM & Vision research.',
                    style: TextStyle(fontSize: 12, color: mutedTextColor),
                  ),
                ],
              ),
            ),
          ],
        );
      case 2:
      default:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_rounded, color: SaaSTheme.accentAmber, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Identified Research Gap:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'High O(N²) quadratic computational complexity during long-context sequence modeling.',
              style: TextStyle(fontSize: 12, color: mutedTextColor, height: 1.4),
            ),
          ],
        );
    }
  }

  Widget _circleDot(Color color) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
