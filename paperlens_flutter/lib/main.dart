import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_fonts/google_fonts.dart';

import 'screens/auth_landing_page.dart';
import 'screens/landing/landing_theme.dart';
import 'screens/migration_step_one_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('PaperLens: Environment variables loaded successfully.');
  } catch (e) {
    debugPrint('PaperLens Warning: Could not load .env file: $e');
  }

  runApp(const PaperLensFlutterApp());
}

class PaperLensFlutterApp extends StatefulWidget {
  const PaperLensFlutterApp({super.key});

  @override
  State<PaperLensFlutterApp> createState() => _PaperLensFlutterAppState();
}

class _PaperLensFlutterAppState extends State<PaperLensFlutterApp> {
  static const _themePreferenceKey = 'paperlens-theme';
  ThemeMode _themeMode = ThemeMode.dark;

  String _publishableKey() {
    final primary = dotenv.maybeGet('CLERK_PUBLISHABLE_KEY')?.trim() ?? '';
    if (primary.isNotEmpty) return primary;
    
    final secondary = dotenv.maybeGet('VITE_CLERK_PUBLISHABLE_KEY')?.trim() ?? '';
    if (secondary.isNotEmpty) return secondary;

    debugPrint('PaperLens Error: CLERK_PUBLISHABLE_KEY not found in .env');
    return '';
  }

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_themePreferenceKey);
    if (!mounted) return;
    setState(() {
      _themeMode = value == 'light' ? ThemeMode.light : ThemeMode.dark;
    });
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _themePreferenceKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
    if (!mounted) return;
    setState(() {
      _themeMode = mode;
    });
  }

  Future<void> _toggleTheme() async {
    final nextMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await _setThemeMode(nextMode);
  }

  @override
  Widget build(BuildContext context) {
    final publishableKey = _publishableKey();

    // 1. Handle missing configuration immediately
    if (publishableKey.isEmpty) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFF0A1614),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  const Text(
                    'Configuration Error',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'CLERK_PUBLISHABLE_KEY is missing in your .env file.\n\nPlease add it and restart the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final lightScheme = ColorScheme.fromSeed(
      seedColor: SaaSTheme.primaryTealDark,
      primary: SaaSTheme.primaryTealDark,
      secondary: SaaSTheme.accentViolet,
      surface: SaaSTheme.surfaceLight,
      brightness: Brightness.light,
    );

    final darkScheme = ColorScheme.fromSeed(
      seedColor: SaaSTheme.primaryTeal,
      primary: SaaSTheme.primaryTeal,
      secondary: SaaSTheme.accentViolet,
      surface: SaaSTheme.surfaceDark,
      brightness: Brightness.dark,
    );

    final app = MaterialApp(
      title: 'PaperLens AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: lightScheme,
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
        scaffoldBackgroundColor: SaaSTheme.bgLight,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: SaaSTheme.cardLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: SaaSTheme.borderLight, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SaaSTheme.cardLightHover,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: SaaSTheme.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: SaaSTheme.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: SaaSTheme.primaryTealDark, width: 2),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        useMaterial3: true,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
        scaffoldBackgroundColor: SaaSTheme.bgDark,
        cardTheme: CardThemeData(
          elevation: 0,
          color: SaaSTheme.cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: SaaSTheme.borderDark, width: 1),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SaaSTheme.surfaceDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: SaaSTheme.borderDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: SaaSTheme.borderDark),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: SaaSTheme.primaryTeal, width: 2),
          ),
        ),
      ),
      themeMode: _themeMode,
      home: ClerkAuthBuilder(
        signedInBuilder: (context, authState) {
          return MigrationStepOnePage(
            isDarkMode: _themeMode == ThemeMode.dark,
            onThemeChanged: (isDark) {
              _setThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
            },
          );
        },
        signedOutBuilder: (context, authState) {
          return AuthLandingPage(
            isDarkMode: _themeMode == ThemeMode.dark,
            onToggleTheme: _toggleTheme,
          );
        },
      ),
    );

    return ClerkAuth(
      config: ClerkAuthConfig(publishableKey: publishableKey),
      child: app,
    );
  }
}
