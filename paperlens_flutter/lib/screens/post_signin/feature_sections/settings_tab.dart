import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';
import '../../landing/landing_theme.dart';
import '../shared_widgets.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({
    super.key,
    required this.baseUrl,
    required this.jwtToken,
    required this.getJwtToken,
    required this.ensureToken,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.onSignOut,
    required this.onSyncToken,
  });

  final String baseUrl;
  final String jwtToken;
  final String Function() getJwtToken;
  final Future<void> Function({bool force}) ensureToken;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final Future<void> Function() onSignOut;
  final Future<void> Function() onSyncToken;

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  static const _fullNameKey = 'paperlens_profile_full_name';
  static const _emailKey = 'paperlens_profile_email';
  static const _institutionKey = 'paperlens_profile_institution';

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _institutionController = TextEditingController();

  bool _loadingSaved = false;
  bool _syncingToken = false;
  List<Map<String, dynamic>> _savedItems = const [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadSavedItems();
  }

  @override
  void didUpdateWidget(covariant SettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.jwtToken != widget.jwtToken) {
      _loadSavedItems();
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _institutionController.dispose();
    super.dispose();
  }

  ApiService _apiWithCurrentToken() {
    return ApiService(baseUrl: widget.baseUrl, jwtToken: widget.getJwtToken());
  }

  Future<T> _withTokenRetry<T>(Future<T> Function(ApiService api) request) async {
    await widget.ensureToken();
    var api = _apiWithCurrentToken();
    try {
      return await request(api);
    } on ApiException catch (e) {
      if (e.statusCode != 401) rethrow;
      await widget.ensureToken(force: true);
      api = _apiWithCurrentToken();
      return request(api);
    }
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fullNameController.text = prefs.getString(_fullNameKey) ?? '';
      _emailController.text = prefs.getString(_emailKey) ?? '';
      _institutionController.text = prefs.getString(_institutionKey) ?? '';
    });
  }

  Future<void> _saveProfile() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fullNameKey, _fullNameController.text.trim());
    await prefs.setString(_emailKey, _emailController.text.trim());
    await prefs.setString(_institutionKey, _institutionController.text.trim());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved successfully!')));
  }

  Future<void> _loadSavedItems() async {
    if (_loadingSaved) return;
    setState(() => _loadingSaved = true);

    try {
      final response = await _withTokenRetry((api) => api.getSavedItems());
      final rawList = response['items'] as List<dynamic>? ?? const [];
      final list = rawList.whereType<Map<String, dynamic>>().toList(growable: false);

      if (!mounted) return;
      setState(() {
        _savedItems = list;
        _loadingSaved = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSaved = false);
    }
  }

  Future<void> _deleteSavedItem(int itemId) async {
    try {
      await _withTokenRetry((api) => api.deleteSavedItem(itemId));
      await _loadSavedItems();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted item from workspace.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete item: $e')));
    }
  }

  Future<void> _handleSyncToken() async {
    if (_syncingToken) return;
    setState(() => _syncingToken = true);
    try {
      await widget.onSyncToken();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Credentials synchronized successfully!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to sync credentials: $e')));
    } finally {
      if (mounted) setState(() => _syncingToken = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    // Read Clerk user credentials safely
    String? clerkImageUrl;
    String? clerkEmail;
    String? clerkName;

    try {
      final auth = ClerkAuth.of(context, listen: true);
      final user = auth.user;
      clerkImageUrl = user?.imageUrl;
      final emails = user?.emailAddresses;
      if (emails != null && emails.isNotEmpty) {
        clerkEmail = emails.first.emailAddress;
      }
      final firstName = user?.firstName;
      if (firstName != null && firstName.isNotEmpty) {
        clerkName = '$firstName ${user?.lastName ?? ''}'.trim();
      } else {
        clerkName = user?.username;
      }
    } catch (_) {}

    final displayName = (_fullNameController.text.trim().isNotEmpty)
        ? _fullNameController.text.trim()
        : (clerkName ?? 'Researcher Account');

    final displayEmail = (_emailController.text.trim().isNotEmpty)
        ? _emailController.text.trim()
        : (clerkEmail ?? 'Authenticated Clerk Session');

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account & Security Controls Card (Upgraded SaaS Design)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: SaaSTheme.primaryTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.shield_rounded, color: SaaSTheme.primaryTeal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Account & Security', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                          Text('Manage authentication, active JWT security, and session credentials.', style: TextStyle(fontSize: 11, color: subtextColor)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // User Identity Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? SaaSTheme.surfaceDark.withValues(alpha: 0.6) : SaaSTheme.bgLightSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: isDark ? SaaSTheme.bgDarkSecondary : Colors.white,
                        backgroundImage: (clerkImageUrl != null && clerkImageUrl.isNotEmpty) ? NetworkImage(clerkImageUrl) : null,
                        child: (clerkImageUrl == null || clerkImageUrl.isEmpty)
                            ? Icon(Icons.person_rounded, size: 22, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(displayName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
                            Text(displayEmail, style: TextStyle(fontSize: 11, color: subtextColor)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: SaaSTheme.primaryTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: SaaSTheme.primaryTeal.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline_rounded, size: 11, color: SaaSTheme.primaryTeal),
                            const SizedBox(width: 4),
                            Text('JWT Active', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Credential Sync Action Item
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? SaaSTheme.bgDarkSecondary : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: SaaSTheme.accentCyan.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.sync_lock_rounded, color: SaaSTheme.accentCyan, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Sync Session Credentials', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
                            Text('Refreshes active Clerk JWT bearer tokens with PaperLens API services.', style: TextStyle(fontSize: 11, color: subtextColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _syncingToken ? null : _handleSyncToken,
                        icon: _syncingToken
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh_rounded, size: 14),
                        label: Text(_syncingToken ? 'Syncing...' : 'Sync'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Danger Zone Sign Out
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sign Out of Account', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.redAccent)),
                            Text('Terminates active Clerk session and clears local authentication cache.', style: TextStyle(fontSize: 11, color: subtextColor)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            await widget.onSignOut();
                          } catch (_) {
                            if (!context.mounted) return;
                            try {
                              ClerkAuth.of(context, listen: false).signOut();
                            } catch (_) {}
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, size: 14),
                        label: const Text('Sign Out'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent.withValues(alpha: 0.15),
                          foregroundColor: Colors.redAccent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Researcher Profile Settings Card
          PostSigninSectionCard(
            title: 'Researcher Profile',
            subtitle: 'Manage your personal profile, academic institution, and research credentials.',
            child: Column(
              children: [
                TextField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Dr. Alex Rivera',
                    hintStyle: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _institutionController,
                  decoration: InputDecoration(
                    labelText: 'University / R&D Institution',
                    hintText: 'e.g., Stanford AI Lab, MIT CSAIL',
                    hintStyle: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saveProfile,
                    icon: const Icon(Icons.save_rounded, size: 16),
                    label: const Text('Save Profile Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                      foregroundColor: const Color(0xFF041814),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Appearance & Theme Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.accentViolet, size: 20),
                    const SizedBox(width: 8),
                    Text('Appearance & Theme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: Text('Dark Glassmorphism Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
                  subtitle: Text('Deep space navy theme with glowing radial accents.', style: TextStyle(fontSize: 12, color: subtextColor)),
                  value: isDark,
                  onChanged: (val) => widget.onThemeChanged(val),
                  activeTrackColor: SaaSTheme.primaryTeal,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Saved Research Workspace Manager
          Container(
            padding: const EdgeInsets.all(20),
            decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.folder_special_rounded, color: SaaSTheme.accentAmber, size: 20),
                        const SizedBox(width: 8),
                        Text('Saved Workspace Items (${_savedItems.length})', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
                      ],
                    ),
                    IconButton(
                      onPressed: _loadSavedItems,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      tooltip: 'Refresh Saved Items',
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (_loadingSaved)
                  const Center(child: CircularProgressIndicator())
                else if (_savedItems.isEmpty)
                  Text('No saved items found in your cloud workspace.', style: TextStyle(fontSize: 12, color: subtextColor))
                else
                  ..._savedItems.map((item) {
                    final id = (item['id'] as num?)?.toInt() ?? 0;
                    final title = (item['title'] ?? 'Saved Item').toString();
                    final section = (item['section'] ?? '').toString().toUpperCase();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? SaaSTheme.bgDarkSecondary : SaaSTheme.bgLightSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor)),
                                Text(section, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: SaaSTheme.primaryTeal)),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: id > 0 ? () => _deleteSavedItem(id) : null,
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                            tooltip: 'Delete Item',
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
