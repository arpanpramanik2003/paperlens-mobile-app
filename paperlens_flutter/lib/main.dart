import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/auth_landing_page.dart';
import 'screens/migration_step_one_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // Allow startup to continue if .env is missing in local setups.
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
    if (primary.isNotEmpty) {
      return primary;
    }
    return dotenv.maybeGet('VITE_CLERK_PUBLISHABLE_KEY')?.trim() ?? '';
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
    final lightScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF005E54),
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2AAE9F),
      brightness: Brightness.dark,
    );

    final app = MaterialApp(
      title: 'PaperLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: lightScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF0F5F5),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: darkScheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A1614),
        cardTheme: CardThemeData(
          elevation: 0,
          color: const Color(0xFF13211F),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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

    final publishableKey = _publishableKey();
    if (publishableKey.isEmpty) {
      return app;
    }

    return ClerkAuth(
      config: ClerkAuthConfig(publishableKey: publishableKey),
      child: app,
    );
  }
}
