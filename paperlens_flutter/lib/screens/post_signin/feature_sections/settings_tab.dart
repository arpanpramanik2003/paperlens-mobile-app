import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/api_service.dart';
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
  bool _signingOut = false;
  String _status = '';
  List<Map<String, dynamic>> _savedItems = const [];

  static const Map<String, String> _sectionLabels = {
    'experiment_planner': 'Experiment Planner',
    'problem_generator': 'Problem Generator',
    'gap_detection': 'Gap Detection',
    'dataset_benchmark_finder': 'Dataset & Benchmark Finder',
    'citation_intelligence': 'Citation Intelligence',
  };

  static const List<String> _sectionOrder = [
    'problem_generator',
    'experiment_planner',
    'gap_detection',
    'dataset_benchmark_finder',
    'citation_intelligence',
  ];

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

  Future<T> _withTokenRetry<T>(
    Future<T> Function(ApiService api) request,
  ) async {
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
    setState(() => _status = 'Profile saved locally on this device.');
  }

  Future<void> _loadSavedItems() async {
    if (widget.getJwtToken().trim().isEmpty) {
      setState(() {
        _savedItems = const [];
        _status = 'Waiting for Clerk session token...';
      });
      return;
    }

    setState(() {
      _loadingSaved = true;
      _status = '';
    });

    try {
      final data = await _withTokenRetry((api) => api.getSavedItems());
      setState(() {
        _savedItems = (data['items'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
        _status = 'Loaded ${_savedItems.length} saved items.';
      });
    } catch (e) {
      setState(() => _status = 'Failed to load saved items: $e');
    } finally {
      if (mounted) {
        setState(() => _loadingSaved = false);
      }
    }
  }

  Future<void> _deleteSavedItem(int id) async {
    try {
      await _withTokenRetry((api) => api.deleteSavedItem(id));
      if (!mounted) return;
      setState(() {
        _savedItems = _savedItems.where((item) => item['id'] != id).toList();
        _status = 'Saved item deleted.';
      });
    } catch (e) {
      setState(() => _status = 'Delete failed: $e');
    }
  }

  Future<void> _signOut() async {
    setState(() => _signingOut = true);
    try {
      await widget.onSignOut();
    } finally {
      if (mounted) {
        setState(() => _signingOut = false);
      }
    }
  }

  void _showPayload(Map<String, dynamic> item) {
    final payload = item['payload'] ?? const {};
    final formatted = const JsonEncoder.withIndent('  ').convert(payload);

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text((item['title'] ?? 'Saved Item').toString()),
          content: SingleChildScrollView(child: SelectableText(formatted)),
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

  List<Map<String, dynamic>> _groupedSavedItems() {
    return _sectionOrder
        .map((section) {
          final items = _savedItems
              .where((item) => (item['section'] ?? '').toString() == section)
              .toList(growable: false);
          return {
            'section': section,
            'label': _sectionLabels[section] ?? section,
            'items': items,
          };
        })
        .where((group) => (group['items'] as List).isNotEmpty)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final grouped = _groupedSavedItems();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        PostSigninSectionCard(
          title: 'Settings Studio',
          icon: Icons.settings_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF2B3745), Color(0xFF3D5166)]
                        : const [Color(0xFFEFF5FF), Color(0xFFE3EDFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF5A738F)
                        : const Color(0xFFCADCF8),
                  ),
                ),
                child: Text(
                  'Manage your profile, appearance, account session, and saved research outputs in one place with quick controls.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF304D70),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        PostSigninSectionCard(
          title: 'Profile',
          icon: Icons.person_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        )
                      : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        )
                      : Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _institutionController,
                decoration: InputDecoration(
                  labelText: 'Institution',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        )
                      : Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _saveProfile,
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Profile'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        PostSigninSectionCard(
          title: 'Appearance',
          icon: Icons.palette_rounded,
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Dark Mode',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Switch(
                value: widget.isDarkMode,
                onChanged: widget.onThemeChanged,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        PostSigninSectionCard(
          title: 'Account',
          icon: Icons.shield_rounded,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: widget.onSyncToken,
                icon: const Icon(Icons.key_rounded),
                label: const Text('Refresh Session Token'),
              ),
              FilledButton.icon(
                onPressed: _signingOut ? null : _signOut,
                icon: const Icon(Icons.logout_rounded),
                label: Text(_signingOut ? 'Signing out...' : 'Sign Out'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        PostSigninSectionCard(
          title: 'Saved Content',
          icon: Icons.bookmarks_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _loadingSaved ? null : _loadSavedItems,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh'),
                  ),
                ],
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 6),
                PostSigninInfoBox(text: _status),
              ],
              const SizedBox(height: 8),
              if (_loadingSaved)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (grouped.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No saved items yet. Save outputs in each section to view them here.',
                  ),
                )
              else
                ...grouped.map((group) {
                  final label = (group['label'] ?? 'Other').toString();
                  final items = (group['items'] as List<dynamic>)
                      .whereType<Map<String, dynamic>>()
                      .toList(growable: false);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 6),
                        ...items.map((item) {
                          final id = item['id'] as int? ?? 0;
                          final createdAt = (item['created_at'] ?? '')
                              .toString();
                          return Card(
                            elevation: 0,
                            color: isDark
                                ? colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.35)
                                : const Color(0xFFF8FAFA),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                (item['title'] ?? 'Untitled').toString(),
                              ),
                              subtitle: Text(createdAt),
                              trailing: Wrap(
                                spacing: 4,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_rounded),
                                    onPressed: () => _showPayload(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                    onPressed: () => _deleteSavedItem(id),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}
