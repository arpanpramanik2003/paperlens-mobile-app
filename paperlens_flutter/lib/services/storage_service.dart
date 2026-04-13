import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StorageService {
  static const _apiBaseUrlKey = 'paperlens_api_base_url';
  static const _jwtTokenKey = 'paperlens_jwt_token';
  static const _legacyEmulatorBaseUrl = 'http://10.0.2.2:8000';
  static const _fallbackApiBaseUrl = 'https://paperlens-ai.onrender.com';

  String _defaultApiBaseUrl() {
    try {
      final fromEnv = dotenv.maybeGet('API_BASE_URL')?.trim() ?? '';
      if (fromEnv.isNotEmpty) {
        return fromEnv;
      }
    } catch (_) {
      // Tests and some startup paths may call this before dotenv is loaded.
    }

    return _fallbackApiBaseUrl;
  }

  Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_apiBaseUrlKey)?.trim() ?? '';
    if (saved.isEmpty || saved == _legacyEmulatorBaseUrl) {
      return _defaultApiBaseUrl();
    }

    return saved;
  }

  Future<String> getJwtToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_jwtTokenKey) ?? '';
  }

  Future<void> saveApiBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiBaseUrlKey, value.trim());
  }

  Future<void> saveJwtToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_jwtTokenKey, value.trim());
  }
}
