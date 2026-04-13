import 'package:flutter/material.dart';

import '../shared_widgets.dart';

class PostSigninDashboardSection extends StatelessWidget {
  const PostSigninDashboardSection({
    super.key,
    required this.dashboard,
    required this.loadingDashboard,
    required this.onLoadDashboard,
  });

  final Map<String, dynamic>? dashboard;
  final bool loadingDashboard;
  final VoidCallback onLoadDashboard;

  IconData _iconForLabel(String label) {
    final value = label.toLowerCase();
    if (value.contains('paper')) return Icons.description_rounded;
    if (value.contains('user')) return Icons.group_rounded;
    if (value.contains('analysis')) return Icons.analytics_rounded;
    if (value.contains('idea') || value.contains('problem')) {
      return Icons.lightbulb_rounded;
    }
    if (value.contains('gap')) return Icons.search_rounded;
    if (value.contains('citation') || value.contains('cite')) {
      return Icons.auto_graph_rounded;
    }
    if (value.contains('saved')) return Icons.bookmark_rounded;
    if (value.contains('session')) return Icons.timer_rounded;
    if (value.contains('plan') || value.contains('experiment')) {
      return Icons.science_rounded;
    }
    if (value.contains('dataset') || value.contains('benchmark')) {
      return Icons.dataset_rounded;
    }
    return Icons.auto_graph_rounded;
  }

  List<Map<String, dynamic>> _normalizedStats() {
    final raw = (dashboard?['stats'] as List<dynamic>? ?? const []);
    return raw.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Widget _metricCard(
    BuildContext context,
    Map<String, dynamic> item,
    int index,
  ) {
    final label = (item['label'] ?? 'Metric').toString();
    final value = (item['value'] ?? '--').toString();

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 380 + (index * 90)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * 14),
            child: child,
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 132),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE0EBE9)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12004D40),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFF0E5D52).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                _iconForLabel(label),
                color: const Color(0xFF0E5D52),
                size: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0C2E29),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 34,
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF4B6560),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightTile({required IconData icon, required String text}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4FAF9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF0E5D52)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF2B4D47),
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = _normalizedStats();
    final now = DateTime.now();
    final refreshedLabel =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return PostSigninSectionCard(
      title: 'Dashboard Command Center',
      icon: Icons.dashboard_customize_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0E5D52), Color(0xFF1A7A6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.insights_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Performance Snapshot',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'This dashboard highlights the most important activity signals across your workspace so you can spot trends and take action quickly.',
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Section: Dashboard',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Refreshed $refreshedLabel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: loadingDashboard ? null : onLoadDashboard,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                loadingDashboard ? 'Refreshing...' : 'Refresh Metrics',
              ),
            ),
          ),
          const SizedBox(height: 10),
          if (stats.isEmpty)
            const PostSigninInfoBox(
              text:
                  'No metrics available yet. Refresh to load your latest dashboard signals.',
            )
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 10.0;
                final cardWidth = (constraints.maxWidth - spacing) / 2;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: stats
                      .asMap()
                      .entries
                      .map(
                        (entry) => SizedBox(
                          width: cardWidth,
                          child: _metricCard(context, entry.value, entry.key),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFCFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE3ECEA)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Insights',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _insightTile(
                    icon: Icons.trending_up_rounded,
                    text:
                        'Use this panel to validate week-over-week momentum before diving into individual tools.',
                  ),
                  _insightTile(
                    icon: Icons.flag_circle_rounded,
                    text:
                        'Prioritize sections with low activity to rebalance your research workflow and improve output consistency.',
                  ),
                  _insightTile(
                    icon: Icons.track_changes_rounded,
                    text:
                        'Refresh metrics after major actions to quickly assess impact and adjust your next steps.',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
