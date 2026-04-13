import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import 'landing/cta_section.dart';
import 'landing/features_section.dart';
import 'landing/hero_section.dart';
import 'landing/how_it_works_section.dart';
import 'landing/landing_footer.dart';
import 'landing/landing_navbar.dart';
import 'landing/landing_palette.dart';
import 'landing/social_proof_section.dart';
import 'landing/testimonials_section.dart';
import 'landing/why_paperlens_section.dart';

class AuthLandingPage extends StatefulWidget {
  const AuthLandingPage({
    super.key,
    required this.isDarkMode,
    required this.onToggleTheme,
  });

  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  @override
  State<AuthLandingPage> createState() => _AuthLandingPageState();
}

class _AuthLandingPageState extends State<AuthLandingPage>
    with SingleTickerProviderStateMixin {
  static const _logoAsset = 'assets/branding/paperlens_logo_512.png';

  final _scrollController = ScrollController();
  final _homeKey = GlobalKey();
  final _featuresKey = GlobalKey();
  final _howKey = GlobalKey();
  final _aboutKey = GlobalKey();

  late final AnimationController _entryController;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openAuthPage(String mode) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) {
          return _AuthEntryPage(mode: mode);
        },
      ),
    );
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      alignment: 0.06,
    );
  }

  void _showAboutDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('About PaperLens AI'),
          content: const Text(
            'PaperLens AI helps researchers understand papers faster, generate project ideas, detect gaps, and build stronger experiments with confidence.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _reveal({
    required int order,
    required Widget child,
    double fromY = 18,
  }) {
    final start = (order * 0.08).clamp(0.0, 0.75);
    final end = (start + 0.24).clamp(0.0, 1.0);
    final curve = CurvedAnimation(
      parent: _entryController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curve,
      builder: (context, _) {
        return Opacity(
          opacity: curve.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curve.value) * fromY),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LandingPalette.background(widget.isDarkMode),
        ),
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: LandingNavbar(
                  logoAsset: _logoAsset,
                  darkMode: widget.isDarkMode,
                  onToggleTheme: widget.onToggleTheme,
                  onHome: () => _scrollTo(_homeKey),
                  onExplore: () => _scrollTo(_featuresKey),
                  onHowItWorks: () => _scrollTo(_howKey),
                  onAbout: () => _scrollTo(_aboutKey),
                ),
              ),
              SliverToBoxAdapter(
                key: _homeKey,
                child: _reveal(
                  order: 0,
                  child: HeroSection(
                    onGetStarted: () => _openAuthPage('Get Started'),
                    onExplore: () => _scrollTo(_featuresKey),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _reveal(order: 1, child: const SocialProofSection()),
              ),
              SliverToBoxAdapter(
                key: _featuresKey,
                child: _reveal(order: 2, child: const FeaturesSection()),
              ),
              SliverToBoxAdapter(
                key: _howKey,
                child: _reveal(order: 3, child: const HowItWorksSection()),
              ),
              SliverToBoxAdapter(
                child: _reveal(order: 4, child: const WhyPaperLensSection()),
              ),
              SliverToBoxAdapter(
                child: _reveal(order: 5, child: const TestimonialsSection()),
              ),
              SliverToBoxAdapter(
                child: _reveal(
                  order: 6,
                  child: CtaSection(
                    onGetStarted: () => _openAuthPage('Get Started Free'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                key: _aboutKey,
                child: _reveal(
                  order: 7,
                  child: LandingFooter(
                    logoAsset: _logoAsset,
                    onOpenAbout: _showAboutDialog,
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

class _AuthEntryPage extends StatelessWidget {
  const _AuthEntryPage({required this.mode});

  final String mode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(mode)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Continue with Google or email using Clerk.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              const ClerkAuthentication(),
            ],
          ),
        ),
      ),
    );
  }
}
