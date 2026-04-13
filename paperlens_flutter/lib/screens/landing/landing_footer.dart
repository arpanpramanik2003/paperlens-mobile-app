import 'package:flutter/material.dart';

import 'landing_palette.dart';

class LandingFooter extends StatelessWidget {
  const LandingFooter({
    super.key,
    required this.logoAsset,
    required this.onOpenAbout,
  });

  final String logoAsset;
  final VoidCallback onOpenAbout;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2F2A).withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  logoAsset,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PaperLens AI',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'AI-powered research assistant for students, engineers, and researchers.',
            style: TextStyle(color: LandingPalette.textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton(
                onPressed: onOpenAbout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white54),
                ),
                child: const Text('About'),
              ),
              const Chip(
                label: Text('© 2026 PaperLens AI'),
                backgroundColor: Color(0xFF143A34),
                labelStyle: TextStyle(color: LandingPalette.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
