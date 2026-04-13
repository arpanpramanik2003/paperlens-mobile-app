import 'package:flutter/material.dart';

class PostSigninStatusPill extends StatelessWidget {
  const PostSigninStatusPill({
    super.key,
    required this.label,
    required this.healthy,
  });

  final String label;
  final bool healthy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: healthy
            ? const Color(0xFFB9F6CA).withValues(alpha: 0.2)
            : Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: healthy
              ? const Color(0xFFB9F6CA).withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

class PostSigninSectionCard extends StatelessWidget {
  const PostSigninSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class PostSigninInfoBox extends StatelessWidget {
  const PostSigninInfoBox({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.55)
            : const Color(0xFFF6F8F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.5)
              : const Color(0xFFE0E8E8),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: isDark
              ? colorScheme.onSurface.withValues(alpha: 0.92)
              : colorScheme.onSurface.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}
