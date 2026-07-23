import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../services/api_service.dart';
import '../../landing/landing_theme.dart';
import '../shared_widgets.dart';

class GapDetectionTab extends StatefulWidget {
  const GapDetectionTab({
    super.key,
    required this.baseUrl,
    required this.jwtToken,
    required this.getJwtToken,
    required this.ensureToken,
  });

  final String baseUrl;
  final String jwtToken;
  final String Function() getJwtToken;
  final Future<void> Function({bool force}) ensureToken;

  @override
  State<GapDetectionTab> createState() => _GapDetectionTabState();
}

class _GapDetectionTabState extends State<GapDetectionTab> {
  static Map<String, dynamic>? _sessionCache;

  final _textController = TextEditingController();

  String _mode = 'text';
  bool _loading = false;
  bool _saving = false;
  String _status = '';
  String? _filePath;
  List<Map<String, dynamic>> _gaps = const [];
  int? _expandedGapIndex;

  @override
  void initState() {
    super.initState();
    _restoreSession();
    _textController.addListener(_persistSession);
  }

  void _restoreSession() {
    final cache = _sessionCache;
    if (cache == null) return;

    _mode = (cache['mode'] ?? 'text').toString();
    _status = (cache['status'] ?? '').toString();
    _filePath = (cache['filePath'] as String?);
    _expandedGapIndex = cache['expandedGapIndex'] as int?;
    _textController.text = (cache['text'] ?? '').toString();

    final rawGaps = cache['gaps'];
    if (rawGaps is List) {
      _gaps = rawGaps
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }
  }

  void _persistSession() {
    _sessionCache = {
      'mode': _mode,
      'status': _status,
      'filePath': _filePath,
      'expandedGapIndex': _expandedGapIndex,
      'text': _textController.text,
      'gaps': _gaps.map((e) => Map<String, dynamic>.from(e)).toList(),
    };
  }

  @override
  void dispose() {
    _textController.removeListener(_persistSession);
    _textController.dispose();
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx'],
      withData: false,
    );
    if (result == null || result.files.single.path == null) {
      return;
    }

    setState(() {
      _filePath = result.files.single.path;
      _status = 'File selected: ${result.files.single.name}';
    });
    _persistSession();
  }

  Future<void> _detectGaps() async {
    if (_loading) return;

    if (_mode == 'text') {
      final value = _textController.text.trim();
      if (value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paste raw notes or literature text first.')),
        );
        return;
      }
    } else {
      final path = _filePath ?? '';
      if (path.isEmpty || !File(path).existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a valid PDF/DOCX file.')),
        );
        return;
      }
    }

    setState(() {
      _loading = true;
      _status = 'AI is scanning literature for unaddressed research gaps...';
      _gaps = const [];
      _expandedGapIndex = null;
    });
    _persistSession();

    try {
      final response = await _withTokenRetry((api) {
        if (_mode == 'text') {
          return api.detectGapsFromText(text: _textController.text.trim());
        } else {
          return api.detectGapsFromFile(File(_filePath!));
        }
      });

      final rawList = response['gaps'] as List<dynamic>? ?? const [];
      final parsed = rawList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _gaps = parsed;
        _status = 'Successfully identified ${parsed.length} research gap opportunities!';
      });
      _persistSession();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Gap detection failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _persistSession();
      }
    }
  }

  Future<void> _saveGap(Map<String, dynamic> gap) async {
    if (_saving) return;
    final title = (gap['title'] ?? gap['gap_title'] ?? 'Research Gap').toString();
    final summary = (gap['description'] ?? gap['summary'] ?? '').toString();

    setState(() => _saving = true);
    try {
      await _withTokenRetry((api) {
        return api.createSavedItem(
          section: 'gap',
          title: title,
          summary: summary.length > 140 ? '${summary.substring(0, 140)}...' : summary,
          payload: gap,
        );
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "$title" to your Research Workspace!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save gap item: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostSigninSectionCard(
            title: 'Research Gap Detection Studio',
            subtitle: 'Uncover unaddressed limitations, contradictory claims, and high-impact open research questions.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Mode Segmented Control
                Row(
                  children: [
                    _modeChip('text', 'Paste Literature Notes', Icons.text_snippet_rounded, isDark),
                    const SizedBox(width: 8),
                    _modeChip('file', 'Upload Paper Document', Icons.upload_file_rounded, isDark),
                  ],
                ),
                const SizedBox(height: 16),

                if (_mode == 'text') ...[
                  TextField(
                    controller: _textController,
                    minLines: 4,
                    maxLines: 7,
                    decoration: InputDecoration(
                      hintText: 'Paste literature excerpts, discussion notes, or abstract summaries...',
                      hintStyle: TextStyle(fontSize: 12, color: subtextColor),
                    ),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? SaaSTheme.surfaceDark.withValues(alpha: 0.6) : SaaSTheme.bgLightSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.file_present_rounded, size: 32, color: isDark ? SaaSTheme.accentViolet : SaaSTheme.primaryTealDark),
                        const SizedBox(height: 8),
                        Text(
                          _filePath != null ? File(_filePath!).path.split(Platform.pathSeparator).last : 'No document selected yet',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open_rounded, size: 16),
                          label: Text(_filePath != null ? 'Choose Different File' : 'Browse PDF/DOCX File'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            side: BorderSide(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                if (_status.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(_status, style: TextStyle(fontSize: 12, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark, fontWeight: FontWeight.w600)),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _detectGaps,
                    icon: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF041814)))
                        : const Icon(Icons.travel_explore_rounded, size: 18),
                    label: Text(
                      _loading ? 'Mining Research Gaps...' : 'Detect Hidden Research Gaps',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
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

          // Discovered Gaps Grid
          if (_gaps.isNotEmpty) ...[
            Text(
              'Identified Research Opportunities (${_gaps.length})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 12),
            ...List.generate(_gaps.length, (index) {
              final gap = _gaps[index];
              return _gapCard(gap, index, isDark, textColor, subtextColor);
            }),
          ],
        ],
      ),
    );
  }

  Widget _modeChip(String key, String label, IconData icon, bool isDark) {
    final isSelected = _mode == key;
    final activeColor = isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _mode = key),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.15) : (isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? activeColor : (isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: isSelected ? activeColor : (isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? activeColor : (isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gapCard(Map<String, dynamic> gap, int index, bool isDark, Color textColor, Color subtextColor) {
    final title = (gap['title'] ?? gap['gap_title'] ?? 'Research Gap Opportunity #${index + 1}').toString();
    final description = (gap['description'] ?? gap['summary'] ?? '').toString();
    final severity = (gap['severity'] ?? gap['impact'] ?? 'HIGH').toString().toUpperCase();
    final isExpanded = _expandedGapIndex == index;

    final severityColor = severity.contains('HIGH')
        ? SaaSTheme.accentMagenta
        : (severity.contains('MED') ? SaaSTheme.accentAmber : SaaSTheme.accentEmerald);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (exp) => setState(() => _expandedGapIndex = exp ? index : null),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  severity,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: severityColor),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor),
                ),
              ),
            ],
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: TextStyle(fontSize: 13, height: 1.5, color: subtextColor),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: '$title\n\n$description'));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied gap brief to clipboard!')));
                        },
                        icon: const Icon(Icons.copy_rounded, size: 14),
                        label: const Text('Copy Brief'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _saveGap(gap),
                        icon: const Icon(Icons.bookmark_border_rounded, size: 14),
                        label: const Text('Save to Workspace'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                          foregroundColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms);
  }
}
