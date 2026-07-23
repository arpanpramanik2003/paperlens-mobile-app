import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import '../landing/landing_theme.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelectSection,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelectSection;
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  static const _logoAsset = 'assets/branding/paperlens_logo_512.png';

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: isDark ? SaaSTheme.bgDarkSecondary : SaaSTheme.surfaceLight,
        border: Border(
          right: BorderSide(
            color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Sidebar Header (Logo + Brand Name)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SaaSTheme.brandButtonGradient,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Image.asset(
                      _logoAsset,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'PaperLens',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 4),
                          SaaSTheme.gradientText(
                            'AI',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'v2.4.0 Suite',
                        style: TextStyle(
                          color: subtextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onToggleTheme,
                  icon: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 18,
                    color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.accentViolet,
                  ),
                ),
              ],
            ),
          ),
          Divider(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight, height: 1),

          // Navigation Links Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _categoryHeader('WORKSPACE', isDark),
                  _navTile(0, 'Dashboard', Icons.dashboard_customize_rounded, isDark),
                  _navTile(7, 'Settings & Setup', Icons.settings_rounded, isDark),

                  const SizedBox(height: 16),
                  _categoryHeader('AI SUITE', isDark),
                  _navTile(1, 'Paper Analyzer', Icons.description_rounded, isDark),
                  _navTile(2, 'Citation Intelligence', Icons.auto_graph_rounded, isDark),
                  _navTile(3, 'Gap Detection', Icons.search_rounded, isDark),
                  _navTile(4, 'Problem Generator', Icons.lightbulb_rounded, isDark),
                  _navTile(5, 'Dataset & Benchmarks', Icons.dataset_rounded, isDark),
                  _navTile(6, 'Experiment Planner', Icons.science_rounded, isDark),
                ],
              ),
            ),
          ),

          // Sidebar Footer (Clerk User Account Profile Card)
          Divider(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight, height: 1),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Builder(
              builder: (context) {
                try {
                  final auth = ClerkAuth.of(context, listen: true);
                  final user = auth.user;
                  final name = user?.firstName ?? 'Researcher';
                  final emails = user?.emailAddresses ?? const [];
                  final email = emails.isNotEmpty ? emails.first.emailAddress : 'user@paperlens.ai';
                  final initial = name.isNotEmpty ? name[0].toUpperCase() : 'P';

                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: SaaSTheme.primaryTeal,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Color(0xFF041814),
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                              Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: subtextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            try {
                              ClerkAuth.of(context, listen: false).signOut();
                            } catch (_) {}
                          },
                          tooltip: 'Sign Out',
                          icon: const Icon(Icons.logout_rounded, size: 16, color: Colors.redAccent),
                        ),
                      ],
                    ),
                  );
                } catch (_) {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: isDark ? SaaSTheme.textSubtleDark : SaaSTheme.textSubtleLight,
        ),
      ),
    );
  }

  Widget _navTile(int index, String title, IconData icon, bool isDark) {
    final isSelected = selectedIndex == index;
    final activeColor = isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: () => onSelectSection(index),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.15 : 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? activeColor.withValues(alpha: 0.4) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 19,
                color: isSelected
                    ? activeColor
                    : (isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? activeColor
                        : (isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight),
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: activeColor,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
