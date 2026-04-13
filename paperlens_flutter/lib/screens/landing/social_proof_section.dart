import 'package:flutter/material.dart';

import 'landing_palette.dart';

class SocialProofSection extends StatelessWidget {
  const SocialProofSection({super.key});

  @override
  Widget build(BuildContext context) {
    final brands = const ['Nature', 'IEEE', 'arXiv', 'Springer', 'ACM'];
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0A2F2A).withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          const Text(
            'TRUSTED BY RESEARCHERS AT',
            style: TextStyle(
              color: LandingPalette.textMuted,
              letterSpacing: 1.3,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: brands
                .map(
                  (brand) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: const Color(0xFF103A34),
                    ),
                    child: Text(
                      brand,
                      style: const TextStyle(
                        color: LandingPalette.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}
