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

  String _mode = 'text'; // 'text' or 'file'
  bool _loading = false;
  bool _saving = false;
  bool _copied = false;
  String _status = '';
  String? _filePath;
  List<Map<String, dynamic>> _gaps = const [];

  static const _workflowGuide = [
    ('Provide Input', 'Paste project plan text or upload paper PDF/DOCX.', Icons.description_rounded),
    ('Analyze Structure', 'Detect missing assumptions, weak baselines & unstated risks.', Icons.manage_search_rounded),
    ('Prioritize Risks', 'Classify opportunities by severity and research impact.', Icons.shield_moon_rounded),
    ('Improve Plan', 'Apply targeted remediation suggestions to close gaps.', Icons.lightbulb_rounded),
  ];

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
    _textController.text = (cache['text'] ?? '').toString();

    final rawGaps = cache['gaps'];
    if (rawGaps is List) {
      _gaps = rawGaps.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false);
    }
  }

  void _persistSession() {
    _sessionCache = {
      'mode': _mode,
      'status': _status,
      'filePath': _filePath,
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

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx'],
      withData: false,
    );
    if (result == null || result.files.single.path == null) return;

    setState(() {
      _filePath = result.files.single.path;
      _status = 'Selected file: ${result.files.single.name}';
    });
    _persistSession();
  }

  Future<void> _detectGaps() async {
    if (_loading) return;

    if (_mode == 'text') {
      final value = _textController.text.trim();
      if (value.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paste project plan text or literature notes first.')));
        return;
      }
    } else {
      final path = _filePath ?? '';
      if (path.isEmpty || !File(path).existsSync()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a valid PDF or DOCX paper file first.')));
        return;
      }
    }

    setState(() {
      _loading = true;
      _status = 'Scanning literature structure for unaddressed research gaps...';
      _gaps = const [];
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
      final parsed = rawList.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList(growable: false);

      if (!mounted) return;
      setState(() {
        _gaps = parsed;
        _status = 'Successfully identified ${parsed.length} research opportunities!';
      });
      _persistSession();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = 'Gap analysis failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _persistSession();
      }
    }
  }

  Future<void> _saveAllGaps() async {
    if (_gaps.isEmpty || _saving) return;

    setState(() => _saving = true);
    final title = _mode == 'text' ? 'Gap Analysis Report (Project Plan)' : 'Gap Analysis Report (Uploaded Paper)';

    try {
      await _withTokenRetry((api) {
        return api.createSavedItem(
          section: 'gap',
          title: title,
          summary: '${_gaps.length} research gaps identified',
          payload: {
            'mode': _mode,
            'gaps': _gaps,
          },
        );
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved "$title" to Research Workspace!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save gap report: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _copyAllGapsToClipboard() {
    if (_gaps.isEmpty) return;
    final text = _gaps.map((g) {
      final t = (g['title'] ?? g['gap_title'] ?? 'Gap Opportunity').toString();
      final sev = (g['severity'] ?? g['impact'] ?? 'HIGH').toString().toUpperCase();
      final exp = (g['explanation'] ?? g['description'] ?? g['summary'] ?? '').toString();
      final sug = (g['suggestion'] ?? g['remediation'] ?? '').toString();

      return '### $t [$sev Risk]\n$exp${sug.isNotEmpty ? "\n\nRemediation Suggestion:\n$sug" : ""}';
    }).join('\n\n---\n\n');

    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied complete gap report to clipboard!')));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
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
            title: 'Research Gap Detection Engine',
            subtitle: 'Identify blind spots, unstated assumptions, and high-impact open research directions.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Input Mode Segment Switcher
                Row(
                  children: [
                    _modeChip('text', 'Project Plan Text', Icons.text_snippet_rounded, isDark),
                    const SizedBox(width: 8),
                    _modeChip('file', 'Upload Paper File', Icons.upload_file_rounded, isDark),
                  ],
                ),
                const SizedBox(height: 16),

                if (_mode == 'text') ...[
                  TextField(
                    controller: _textController,
                    minLines: 5,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: 'Paste your project plan, proposal draft, or literature review notes here...',
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
                        Icon(Icons.picture_as_pdf_rounded, size: 32, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark),
                        const SizedBox(height: 8),
                        Text(
                          _filePath != null ? File(_filePath!).path.split(Platform.pathSeparator).last : 'Click to select PDF or DOCX File',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                        ),
                        const SizedBox(height: 4),
                        Text('Supports arXiv, IEEE, Springer, and custom papers (Max 10MB)', style: TextStyle(fontSize: 11, color: subtextColor)),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open_rounded, size: 16),
                          label: Text(_filePath != null ? 'Change Selected File' : 'Browse File'),
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

                // Fixed-Height Loading Indicator Box (Never flexes or changes box height)
                if (_loading)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? SaaSTheme.bgDarkSecondary : SaaSTheme.bgLightSecondary,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                    ),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                          backgroundColor: isDark ? SaaSTheme.surfaceDark : Colors.white,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 24,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _status.isEmpty ? 'Mining literature for hidden research gaps...' : _status,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_status.isNotEmpty)
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

          // 4-Stage Workflow Guide Card (Only shown before results arrive)
          if (_gaps.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Workflow Example', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
                      Text('4 STAGES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: subtextColor, letterSpacing: 1.0)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;

                      return GridView.count(
                        crossAxisCount: isWide ? 2 : 1,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: isWide ? 3.6 : 3.8,
                        children: List.generate(_workflowGuide.length, (idx) {
                          final item = _workflowGuide[idx];
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? SaaSTheme.surfaceDark.withValues(alpha: 0.5) : SaaSTheme.bgLightSecondary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(item.$3, size: 14, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${idx + 1}. ${item.$1}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor),
                                      ),
                                      Text(
                                        item.$2,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 10, color: subtextColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ],
              ),
            ),

          // Discovered Gaps Output Section
          if (_gaps.isNotEmpty) ...[
            Text(
              '${_gaps.length} Research Gaps Identified',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _copyAllGapsToClipboard,
                  icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 14),
                  label: Text(_copied ? 'Copied Report' : 'Copy Report'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _saveAllGaps,
                  icon: const Icon(Icons.bookmark_border_rounded, size: 14),
                  label: const Text('Save to Workspace'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                    foregroundColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            ...List.generate(_gaps.length, (index) {
              final gap = _gaps[index];
              return _gapOpportunityCard(gap, index, isDark, textColor, subtextColor);
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? activeColor : (isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _gapOpportunityCard(Map<String, dynamic> gap, int index, bool isDark, Color textColor, Color subtextColor) {
    final title = (gap['title'] ?? gap['gap_title'] ?? 'Research Gap Opportunity #${index + 1}').toString();
    final explanation = (gap['explanation'] ?? gap['description'] ?? gap['summary'] ?? '').toString();
    final severity = (gap['severity'] ?? gap['impact'] ?? 'HIGH').toString().toUpperCase();
    final suggestion = (gap['suggestion'] ?? gap['remediation'] ?? gap['remedy'] ?? '').toString();

    final isHigh = severity.contains('HIGH') || severity.contains('CRITICAL');
    final isMed = severity.contains('MED');

    final severityColor = isHigh ? Colors.redAccent : (isMed ? SaaSTheme.accentAmber : SaaSTheme.primaryTeal);
    final badgeLabel = isHigh ? 'HIGH RISK' : (isMed ? 'MEDIUM SEVERITY' : 'LOW RISK');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor, height: 1.35),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: severityColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: severityColor, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Justified Explanation Text
          SelectableText(
            explanation,
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 13, height: 1.55, color: subtextColor),
          ),

          // Targeted Remediation Suggestion Box
          if (suggestion.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SaaSTheme.primaryTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SaaSTheme.primaryTeal.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_rounded, size: 16, color: SaaSTheme.primaryTeal),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SelectableText(
                      suggestion,
                      textAlign: TextAlign.justify,
                      style: TextStyle(fontSize: 12, height: 1.45, fontStyle: FontStyle.italic, color: textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms, duration: 350.ms);
  }
}
