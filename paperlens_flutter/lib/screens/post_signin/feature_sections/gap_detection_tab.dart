import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/api_service.dart';
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

  Future<void> _detect() async {
    if (_mode == 'text' && _textController.text.trim().isEmpty) {
      setState(() => _status = 'Paste project text first.');
      _persistSession();
      return;
    }
    if (_mode == 'file' && (_filePath == null || _filePath!.isEmpty)) {
      setState(() => _status = 'Pick a PDF or DOCX file first.');
      _persistSession();
      return;
    }

    setState(() {
      _loading = true;
      _status = '';
      _gaps = const [];
      _expandedGapIndex = null;
    });
    _persistSession();

    try {
      final data = await _withTokenRetry(
        (api) => _mode == 'text'
            ? api.detectGapsFromText(text: _textController.text.trim())
            : api.detectGapsFromFile(File(_filePath!)),
      );

      final gaps = (data['gaps'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      setState(() {
        _gaps = gaps;
        _expandedGapIndex = gaps.isEmpty ? null : 0;
        _status = gaps.isEmpty
            ? 'No gaps returned by backend.'
            : 'Detected ${gaps.length} research gaps.';
      });
      _persistSession();
    } catch (e) {
      setState(() => _status = 'Gap detection failed: $e');
      _persistSession();
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _persistSession();
      }
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return const Color(0xFFC62828);
      case 'medium':
        return const Color(0xFFEF6C00);
      default:
        return const Color(0xFF546E7A);
    }
  }

  Future<void> _copyReport() async {
    if (_gaps.isEmpty) {
      setState(() => _status = 'No gap report available to copy.');
      _persistSession();
      return;
    }

    final report = _gaps
        .map(
          (gap) => [
            (gap['title'] ?? 'Untitled gap').toString(),
            'Severity: ${(gap['severity'] ?? 'low').toString()}',
            'Gap: ${(gap['explanation'] ?? '').toString()}',
            'Suggestion: ${(gap['suggestion'] ?? '').toString()}',
          ].join('\n'),
        )
        .join('\n\n');

    await Clipboard.setData(ClipboardData(text: report));
    if (!mounted) return;
    setState(() => _status = 'Gap report copied to clipboard.');
    _persistSession();
  }

  Future<void> _saveReport() async {
    if (_gaps.isEmpty) {
      setState(() => _status = 'Run detection before saving.');
      _persistSession();
      return;
    }

    if (widget.getJwtToken().trim().isEmpty) {
      setState(
        () => _status = 'Session token not ready. Please wait and retry.',
      );
      _persistSession();
      return;
    }

    setState(() {
      _saving = true;
      _status = '';
    });
    _persistSession();

    try {
      final title = _mode == 'text'
          ? 'Gap Analysis (Project Plan)'
          : 'Gap Analysis (Uploaded Paper)';
      final summary = '${_gaps.length} research gaps identified';

      await _withTokenRetry(
        (api) => api.createSavedItem(
          section: 'gap_detection',
          title: title,
          summary: summary,
          payload: {
            'mode': _mode,
            'source_text': _mode == 'text' ? _textController.text.trim() : null,
            'file_name': _filePath?.split(Platform.pathSeparator).last,
            'gaps': _gaps,
          },
        ),
      );
      if (!mounted) return;
      setState(() => _status = 'Gap report saved.');
      _persistSession();
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Save failed: $e');
      _persistSession();
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        _persistSession();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        PostSigninSectionCard(
          title: 'Gap Detection Engine',
          icon: Icons.search_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF3A2A47), Color(0xFF563A6D)]
                        : const [Color(0xFFF3EBFC), Color(0xFFEBDDFA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF755794)
                        : const Color(0xFFDAC5F2),
                  ),
                ),
                child: Text(
                  'Identify hidden weaknesses in a project plan or uploaded paper, then convert those weaknesses into concrete, actionable improvements.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF4B3560),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'text', label: Text('Project Plan')),
                  ButtonSegment(value: 'file', label: Text('Upload Paper')),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() => _mode = selection.first);
                  _persistSession();
                },
              ),
              const SizedBox(height: 10),
              if (_mode == 'text')
                TextField(
                  controller: _textController,
                  minLines: 6,
                  maxLines: 12,
                  decoration: InputDecoration(
                    labelText: 'Project Plan / Research Idea',
                    hintText: 'Paste your project plan to detect research gaps',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDark
                        ? colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          )
                        : Colors.white,
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.25,
                          )
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? colorScheme.outline.withValues(alpha: 0.45)
                          : const Color(0xFFE4EAF2),
                    ),
                  ),
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _pickFile,
                        icon: const Icon(Icons.upload_file_rounded),
                        label: const Text('Pick PDF/DOCX'),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _filePath == null
                              ? 'No file selected'
                              : _filePath!.split(Platform.pathSeparator).last,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _loading ? null : _detect,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(_loading ? 'Detecting...' : 'Detect Gaps'),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 10),
                PostSigninInfoBox(text: _status),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_gaps.isEmpty)
          const PostSigninInfoBox(text: 'Run detection to see identified gaps.')
        else ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_gaps.length} gaps identified',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _saving ? null : _saveReport,
                icon: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_add_rounded, size: 18),
                label: Text(_saving ? 'Saving...' : 'Save'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _copyReport,
                icon: const Icon(Icons.copy_all_rounded, size: 18),
                label: const Text('Copy'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._gaps.asMap().entries.map((entry) {
            final index = entry.key;
            final gap = entry.value;
            final severity = (gap['severity'] ?? 'low').toString();
            final color = _severityColor(severity);
            final isExpanded = _expandedGapIndex == index;
            final explanation = (gap['explanation'] ?? '').toString();
            final suggestion = (gap['suggestion'] ?? '').toString();

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _expandedGapIndex = isExpanded ? null : index;
                        });
                        _persistSession();
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                (gap['title'] ?? 'Untitled gap').toString(),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                severity.toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              isExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.75,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!isExpanded)
                      Text(
                        explanation,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.82),
                          height: 1.34,
                        ),
                      ),
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 220),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox.shrink(),
                      secondChild: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            explanation,
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.9,
                              ),
                              height: 1.38,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF143A32)
                                  : const Color(0xFFE9F4F2),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF2A665B)
                                    : const Color(0xFFCAE2DE),
                              ),
                            ),
                            child: Text(
                              'Suggestion: $suggestion',
                              textAlign: TextAlign.justify,
                              style: const TextStyle(height: 1.35),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
