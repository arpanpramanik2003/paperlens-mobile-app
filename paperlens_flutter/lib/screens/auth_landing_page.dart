import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';

import 'landing/cta_section.dart';
import 'landing/features_section.dart';
import 'landing/hero_section.dart';
import 'landing/how_it_works_section.dart';
import 'landing/landing_footer.dart';
import 'landing/landing_navbar.dart';
import 'landing/landing_theme.dart';
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
    try {
      final auth = ClerkAuth.of(context, listen: false);
      if (auth.isSignedIn) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You are already signed in to PaperLens.')),
        );
        return;
      }
    } catch (_) {}

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (context) {
          return _AuthEntryPage(
            mode: mode,
            isDarkMode: widget.isDarkMode,
            logoAsset: _logoAsset,
          );
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
        final isDark = widget.isDarkMode;
        return AlertDialog(
          backgroundColor: isDark ? SaaSTheme.bgDarkSecondary : SaaSTheme.surfaceLight,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(_logoAsset, width: 28, height: 28),
              ),
              const SizedBox(width: 10),
              Text(
                'About PaperLens AI',
                style: TextStyle(
                  color: isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(
            'PaperLens AI is a next-generation research intelligence workspace designed for scientists, PhD candidates, and AI researchers. It synthesizes complex papers, maps visual citation networks, uncovers hidden research gaps, and formulates step-by-step experiment blueprints.',
            style: TextStyle(
              color: isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                foregroundColor: const Color(0xFF041814),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
    final isDark = widget.isDarkMode;

    return Scaffold(
      body: Container(
        decoration: SaaSTheme.backgroundDecoration(isDark),
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: LandingNavbar(
                  logoAsset: _logoAsset,
                  darkMode: isDark,
                  onToggleTheme: widget.onToggleTheme,
                  onHome: () => _scrollTo(_homeKey),
                  onExplore: () => _scrollTo(_featuresKey),
                  onHowItWorks: () => _scrollTo(_howKey),
                  onAbout: () => _scrollTo(_aboutKey),
                  onSignIn: () => _openAuthPage('Sign In'),
                ),
              ),
              SliverToBoxAdapter(
                key: _homeKey,
                child: _reveal(
                  order: 0,
                  child: HeroSection(
                    isDarkMode: isDark,
                    onGetStarted: () => _openAuthPage('Get Started'),
                    onExplore: () => _scrollTo(_featuresKey),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _reveal(
                  order: 1,
                  child: SocialProofSection(isDarkMode: isDark),
                ),
              ),
              SliverToBoxAdapter(
                key: _featuresKey,
                child: _reveal(
                  order: 2,
                  child: FeaturesSection(isDarkMode: isDark),
                ),
              ),
              SliverToBoxAdapter(
                key: _howKey,
                child: _reveal(
                  order: 3,
                  child: HowItWorksSection(isDarkMode: isDark),
                ),
              ),
              SliverToBoxAdapter(
                child: _reveal(
                  order: 4,
                  child: WhyPaperLensSection(isDarkMode: isDark),
                ),
              ),
              SliverToBoxAdapter(
                child: _reveal(
                  order: 5,
                  child: TestimonialsSection(isDarkMode: isDark),
                ),
              ),
              SliverToBoxAdapter(
                child: _reveal(
                  order: 6,
                  child: CtaSection(
                    isDarkMode: isDark,
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
                    isDarkMode: isDark,
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

class _AuthEntryPage extends StatefulWidget {
  const _AuthEntryPage({
    required this.mode,
    required this.isDarkMode,
    required this.logoAsset,
  });

  final String mode;
  final bool isDarkMode;
  final String logoAsset;

  @override
  State<_AuthEntryPage> createState() => _AuthEntryPageState();
}

class _AuthEntryPageState extends State<_AuthEntryPage> {
  void _dismissWhenSignedIn() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = ClerkAuth.of(context, listen: false);
      if (auth.isSignedIn && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    _dismissWhenSignedIn();

    return ClerkAuthBuilder(
      signedInBuilder: (context, authState) {
        _dismissWhenSignedIn();
        return Scaffold(
          backgroundColor: isDark ? SaaSTheme.bgDark : SaaSTheme.bgLight,
          body: Center(
            child: CircularProgressIndicator(
              color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
            ),
          ),
        );
      },
      signedOutBuilder: (context, authState) {
        return Scaffold(
          backgroundColor: isDark ? SaaSTheme.bgDark : SaaSTheme.bgLight,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.close_rounded, color: textColor),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.mode,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    children: [
                      // Brand Logo Header
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SaaSTheme.brandButtonGradient,
                          boxShadow: [
                            BoxShadow(
                              color: SaaSTheme.primaryTeal.withValues(alpha: 0.3),
                              blurRadius: 16,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: Image.asset(
                            widget.logoAsset,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Text(
                        'Welcome to PaperLens AI',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in or register to unlock instant paper analysis, citation graphs, and experiment blueprints.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: subtextColor,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Feature Pills
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _pillTag('📄 PDF Synthesis', isDark),
                          _pillTag('⚡ Citation Graph', isDark),
                          _pillTag('🔬 Experiment Roadmap', isDark),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Clerk Authentication Form Container
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: SaaSTheme.glassCardDecoration(
                          isDark: isDark,
                          borderRadius: 20,
                        ),
                        child: const ClerkAuthentication(),
                      ),

                      const SizedBox(height: 16),

                      // Security Footnote
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shield_outlined, size: 13, color: subtextColor),
                          const SizedBox(width: 6),
                          Text(
                            'Secured by Clerk • 256-bit SSL Encryption',
                            style: TextStyle(
                              fontSize: 11,
                              color: subtextColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _pillTag(String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight,
        ),
      ),
    );
  }
}
