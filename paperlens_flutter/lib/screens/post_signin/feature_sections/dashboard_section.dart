import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../landing/landing_theme.dart';

class PostSigninDashboardSection extends StatefulWidget {
  const PostSigninDashboardSection({
    super.key,
    required this.dashboard,
    required this.loadingDashboard,
    required this.onLoadDashboard,
    this.onTabChanged,
  });

  final Map<String, dynamic>? dashboard;
  final bool loadingDashboard;
  final VoidCallback onLoadDashboard;
  final ValueChanged<int>? onTabChanged;

  @override
  State<PostSigninDashboardSection> createState() => _PostSigninDashboardSectionState();
}

class _PostSigninDashboardSectionState extends State<PostSigninDashboardSection> {
  String _savedFilter = 'all';

  IconData _iconForLabel(String label) {
    final value = label.toLowerCase();
    if (value.contains('paper')) return Icons.description_rounded;
    if (value.contains('user')) return Icons.group_rounded;
    if (value.contains('analysis')) return Icons.analytics_rounded;
    if (value.contains('idea') || value.contains('problem')) return Icons.lightbulb_rounded;
    if (value.contains('gap')) return Icons.search_rounded;
    if (value.contains('citation') || value.contains('cite')) return Icons.auto_graph_rounded;
    if (value.contains('saved')) return Icons.bookmark_rounded;
    if (value.contains('plan') || value.contains('experiment')) return Icons.science_rounded;
    if (value.contains('dataset') || value.contains('benchmark')) return Icons.dataset_rounded;
    return Icons.auto_graph_rounded;
  }

  int _getTabIndexForLabel(String label) {
    final value = label.toLowerCase();
    if (value.contains('paper') || value.contains('analyzer')) return 1;
    if (value.contains('citation') || value.contains('cite')) return 2;
    if (value.contains('gap')) return 3;
    if (value.contains('idea') || value.contains('problem')) return 4;
    if (value.contains('dataset') || value.contains('benchmark')) return 5;
    if (value.contains('experiment') || value.contains('plan')) return 6;
    return 0;
  }

  List<Map<String, dynamic>> _normalizedStats() {
    final raw = (widget.dashboard?['stats'] as List<dynamic>? ?? const []);
    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  List<Map<String, dynamic>> _recentPapers() {
    final raw = (widget.dashboard?['recentPapers'] as List<dynamic>? ?? const []);
    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  List<Map<String, dynamic>> _savedItems() {
    final raw = (widget.dashboard?['savedItems'] as List<dynamic>? ?? const []);
    final list = raw.whereType<Map<String, dynamic>>().toList(growable: false);
    if (_savedFilter == 'all') return list;
    return list.where((item) {
      final section = (item['section'] ?? '').toString().toLowerCase();
      return section.contains(_savedFilter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    final stats = _normalizedStats();
    final recent = _recentPapers();
    final saved = _savedItems();

    String userName = 'Researcher';
    try {
      final auth = ClerkAuth.of(context, listen: true);
      if (auth.user?.firstName != null && auth.user!.firstName!.isNotEmpty) {
        userName = auth.user!.firstName!;
      }
    } catch (_) {}

    return RefreshIndicator(
      onRefresh: () async => widget.onLoadDashboard(),
      color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SaaS Welcome Banner Card
            _buildWelcomeBanner(isDark, userName, textColor, subtextColor),
            const SizedBox(height: 20),

            // Quick Action Launchpad
            _buildQuickLaunchpad(isDark, textColor, subtextColor),
            const SizedBox(height: 24),

            // System Metrics Grid Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_rounded,
                      size: 18,
                      color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Research Workspace Metrics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                if (widget.loadingDashboard)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                    ),
                  )
                else
                  IconButton(
                    onPressed: widget.onLoadDashboard,
                    icon: Icon(
                      Icons.refresh_rounded,
                      size: 18,
                      color: subtextColor,
                    ),
                    tooltip: 'Refresh Metrics',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Metrics Cards Grid
            if (stats.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  final width = isWide ? (constraints.maxWidth - 12) / 2 : constraints.maxWidth;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: List.generate(stats.length, (index) {
                      final item = stats[index];
                      return SizedBox(
                        width: width,
                        child: _metricTile(item, index, isDark, textColor, subtextColor),
                      );
                    }),
                  );
                },
              )
            else
              _buildDefaultStats(isDark, textColor, subtextColor),

            const SizedBox(height: 24),

            // Recent Papers Section
            _buildSectionHeader('Recent Papers & Manuscripts', Icons.history_rounded, isDark, textColor),
            const SizedBox(height: 12),
            if (recent.isNotEmpty)
              ...recent.map((paper) => _recentPaperCard(paper, isDark, textColor, subtextColor))
            else
              _emptyCard('No recent papers analyzed yet.', 'Upload your first paper in Paper Analyzer to track history.', isDark, textColor, subtextColor),

            const SizedBox(height: 24),

            // Saved Items Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('Saved Research Briefs', Icons.bookmark_rounded, isDark, textColor),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _filterChip('all', 'All', isDark),
                      _filterChip('analyzer', 'Analyzer', isDark),
                      _filterChip('citation', 'Citations', isDark),
                      _filterChip('gap', 'Gaps', isDark),
                      _filterChip('problem', 'Ideas', isDark),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (saved.isNotEmpty)
              ...saved.map((item) => _savedItemCard(item, isDark, textColor, subtextColor))
            else
              _emptyCard('No saved items matching filter.', 'Save research briefs, citation graphs, and gap findings to review here.', isDark, textColor, subtextColor),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(bool isDark, String userName, Color textColor, Color subtextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF0F262C),
                  Color(0xFF142934),
                  Color(0xFF0C1E26),
                ]
              : const [
                  Color(0xFFECFDF5),
                  Color(0xFFF0FDFA),
                  Color(0xFFEFF6FF),
                ],
        ),
        border: Border.all(
          color: isDark ? SaaSTheme.borderDarkGlowing : SaaSTheme.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark).withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: SaaSTheme.pillDecoration(
                  isDark: isDark,
                  glowColor: SaaSTheme.primaryTeal,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.waving_hand_rounded, size: 13, color: SaaSTheme.primaryTeal),
                    SizedBox(width: 6),
                    Text(
                      'AI RESEARCH SUITE ACTIVE',
                      style: TextStyle(
                        color: SaaSTheme.primaryTeal,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Welcome back, $userName!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Synthesize research papers, uncover literature gaps, and build execution blueprints in one unified AI workspace.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: subtextColor,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }

  Widget _buildQuickLaunchpad(bool isDark, Color textColor, Color subtextColor) {
    final actions = [
      ('Analyze Paper', Icons.description_rounded, 1, SaaSTheme.primaryTeal, 'PDF Synthesis & Q&A'),
      ('Citation Graph', Icons.auto_graph_rounded, 2, SaaSTheme.accentCyan, 'Network Influence'),
      ('Detect Gaps', Icons.search_rounded, 3, SaaSTheme.accentViolet, 'Find Limitations'),
      ('Generate Ideas', Icons.lightbulb_rounded, 4, SaaSTheme.accentMagenta, 'Novel Hypotheses'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick AI Actions',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final width = isWide ? (constraints.maxWidth - 12) / 2 : (constraints.maxWidth - 10) / 2;

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: actions.map((act) {
                return SizedBox(
                  width: width,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => widget.onTabChanged?.call(act.$3),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: SaaSTheme.glassCardDecoration(
                          isDark: isDark,
                          borderRadius: 16,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: act.$4.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(act.$2, color: act.$4, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    act.$1,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    act.$5,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: subtextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _metricTile(
    Map<String, dynamic> item,
    int index,
    bool isDark,
    Color textColor,
    Color subtextColor,
  ) {
    final label = (item['label'] ?? 'Metric').toString();
    final value = (item['value'] ?? '0').toString();
    final icon = _iconForLabel(label);
    final targetTab = _getTabIndexForLabel(label);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onTabChanged?.call(targetTab),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: SaaSTheme.glassCardDecoration(
            isDark: isDark,
            borderRadius: 16,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: subtextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 12, color: subtextColor),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms, duration: 400.ms);
  }

  Widget _buildDefaultStats(bool isDark, Color textColor, Color subtextColor) {
    final defaultStats = [
      {'label': 'Papers Analyzed', 'value': '12'},
      {'label': 'Citations Mapped', 'value': '148'},
      {'label': 'Gaps Uncovered', 'value': '8'},
      {'label': 'Saved Briefs', 'value': '5'},
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(defaultStats.length, (index) {
        return _metricTile(defaultStats[index], index, isDark, textColor, subtextColor);
      }),
    );
  }

  Widget _recentPaperCard(Map<String, dynamic> paper, bool isDark, Color textColor, Color subtextColor) {
    final title = (paper['title'] ?? 'Untitled Paper').toString();
    final date = (paper['created_at'] ?? 'Recently').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: SaaSTheme.glassCardDecoration(
        isDark: isDark,
        borderRadius: 14,
      ),
      child: Row(
        children: [
          const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: TextStyle(fontSize: 10, color: subtextColor),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => widget.onTabChanged?.call(1),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
              foregroundColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Open', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _savedItemCard(Map<String, dynamic> item, bool isDark, Color textColor, Color subtextColor) {
    final title = (item['title'] ?? 'Saved Item').toString();
    final section = (item['section'] ?? 'workspace').toString().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: SaaSTheme.glassCardDecoration(
        isDark: isDark,
        borderRadius: 14,
      ),
      child: Row(
        children: [
          Icon(Icons.bookmark_rounded, color: isDark ? SaaSTheme.accentViolet : SaaSTheme.primaryTealDark, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 2),
                Text(section, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: SaaSTheme.accentViolet)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String key, String label, bool isDark) {
    final isSelected = _savedFilter == key;
    final activeColor = isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark;

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _savedFilter = key),
        selectedColor: activeColor.withValues(alpha: 0.2),
        backgroundColor: Colors.transparent,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          color: isSelected
              ? activeColor
              : (isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark, Color textColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
        ),
      ],
    );
  }

  Widget _emptyCard(String title, String desc, bool isDark, Color textColor, Color subtextColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 16),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
          const SizedBox(height: 4),
          Text(desc, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: subtextColor)),
        ],
      ),
    );
  }
}
