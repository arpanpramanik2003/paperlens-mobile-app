import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/api_service.dart';
import '../shared_widgets.dart';

class CitationIntelligenceTab extends StatefulWidget {
  const CitationIntelligenceTab({
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
  State<CitationIntelligenceTab> createState() =>
      _CitationIntelligenceTabState();
}

class _CitationIntelligenceTabState extends State<CitationIntelligenceTab> {
  String _mode = 'upload';
  String _sortOrder = 'newest';
  String _topicPreset = 'auto';
  bool _loading = false;
  bool _saving = false;
  String _status = '';

  String? _filePath;
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();

  Map<String, dynamic>? _report;
  Map<String, dynamic>? _recommendations;
  Map<String, dynamic>? _progress;
  int _loadingStepIndex = 0;
  Timer? _loadingStepTimer;

  bool _expandTopCited = true;
  bool _expandYearwise = false;
  bool _expandUnmatched = false;
  bool _expandGuidance = true;

  @override
  void dispose() {
    _loadingStepTimer?.cancel();
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  List<String> _processStepsForMode() {
    if (_mode == 'discover') {
      return const [
        'Understanding project domain',
        'Searching related papers',
        'Ranking by recency and citations',
        'Preparing AI reading recommendations',
      ];
    }
    return const [
      'Uploading document',
      'Extracting references',
      'Matching with Semantic Scholar',
      'Ranking evidence by impact',
    ];
  }

  void _startLoadingAnimation() {
    _loadingStepTimer?.cancel();
    _loadingStepIndex = 0;
    _loadingStepTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (!mounted) return;
      final steps = _processStepsForMode();
      setState(() {
        _loadingStepIndex = (_loadingStepIndex + 1) % steps.length;
      });
    });
  }

  void _stopLoadingAnimation() {
    _loadingStepTimer?.cancel();
    _loadingStepTimer = null;
    _loadingStepIndex = 0;
  }

  String _friendlyError(Object e, String fallback) {
    if (e is ApiException) {
      return e.message.isEmpty ? fallback : e.message;
    }
    final text = e.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  Widget _expandableBlock({
    required BuildContext context,
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    required Widget child,
    String? trailing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          trailing,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: child,
              ),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
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

  Stream<Map<String, dynamic>> _streamWithTokenRetry(File file) async* {
    await widget.ensureToken();
    var api = _apiWithCurrentToken();
    try {
      await for (final event in api.streamCitationIntelligence(file)) {
        yield event;
      }
      return;
    } on ApiException catch (e) {
      if (e.statusCode != 401) rethrow;
    }

    await widget.ensureToken(force: true);
    api = _apiWithCurrentToken();
    await for (final event in api.streamCitationIntelligence(file)) {
      yield event;
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
      _status = 'Picked ${result.files.single.name}';
    });
  }

  String _buildPaperContext(Map<String, dynamic> report) {
    final topCited = (report['top_cited'] as List<dynamic>? ?? const [])
        .take(8)
        .map(
          (entry) => (entry as Map<String, dynamic>)['title']?.toString() ?? '',
        )
        .where((title) => title.isNotEmpty)
        .join('; ');

    return 'Top cited references: $topCited';
  }

  List<Map<String, dynamic>> _allReferences() {
    return (_report?['references'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _missingReferences() {
    return _allReferences()
        .where((entry) => (entry['matched'] ?? false) != true)
        .toList(growable: false);
  }

  List<Map<String, int>> _yearwiseCounts() {
    final counts = <int, int>{};
    for (final entry in _allReferences()) {
      final rawYear = entry['year'];
      final year = rawYear is int
          ? rawYear
          : int.tryParse(rawYear?.toString() ?? '');
      if (year == null || year <= 0) continue;
      counts.update(year, (value) => value + 1, ifAbsent: () => 1);
    }

    final items = counts.entries
        .map((entry) => {'year': entry.key, 'count': entry.value})
        .toList(growable: true);
    items.sort((a, b) => (b['year'] ?? 0).compareTo(a['year'] ?? 0));
    return items;
  }

  Future<void> _openPaperUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      setState(() => _status = 'Invalid paper URL.');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      setState(() => _status = 'Could not open this paper URL.');
    }
  }

  List<Map<String, dynamic>> _sortedTopCited() {
    final items = (_report?['top_cited'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList(growable: true);

    int yearValue(Map<String, dynamic> row) {
      final year = row['year'];
      if (year is int) return year;
      return int.tryParse(year?.toString() ?? '') ?? -1;
    }

    int citationValue(Map<String, dynamic> row) {
      final citation = row['citation_count'];
      if (citation is int) return citation;
      return int.tryParse(citation?.toString() ?? '') ?? 0;
    }

    if (_sortOrder == 'highest') {
      items.sort((a, b) => citationValue(b).compareTo(citationValue(a)));
    } else if (_sortOrder == 'lowest') {
      items.sort((a, b) => citationValue(a).compareTo(citationValue(b)));
    } else if (_sortOrder == 'oldest') {
      items.sort((a, b) {
        final byYear = yearValue(a).compareTo(yearValue(b));
        if (byYear != 0) return byYear;
        return citationValue(b).compareTo(citationValue(a));
      });
    } else {
      items.sort((a, b) {
        final byYear = yearValue(b).compareTo(yearValue(a));
        if (byYear != 0) return byYear;
        return citationValue(b).compareTo(citationValue(a));
      });
    }

    return items;
  }

  Future<void> _loadRecommendations(
    Map<String, dynamic> report,
    String mode,
  ) async {
    final refs = (report['references'] as List<dynamic>? ?? const []);
    final missing = refs
        .whereType<Map<String, dynamic>>()
        .where((r) => (r['matched'] ?? false) != true)
        .map((r) => (r['reference_text'] ?? '').toString())
        .where((text) => text.isNotEmpty)
        .take(20)
        .toList(growable: false);

    try {
      final rec = await _withTokenRetry(
        (api) => api.citationRecommendations(
          paperContext: _buildPaperContext(report),
          topCited: (report['top_cited'] as List<dynamic>? ?? const []),
          missingReferences: missing,
          recommendationMode: mode,
          projectTitle: mode == 'discover'
              ? _titleController.text.trim()
              : null,
          basicDetails: mode == 'discover'
              ? _detailsController.text.trim()
              : null,
        ),
      );

      if (!mounted) return;
      setState(() {
        _recommendations = rec;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recommendations = null;
        _status =
            'Citation analysis completed, but recommendation generation failed: ${_friendlyError(e, 'Unknown error')}';
      });
    }
  }

  Future<void> _runUploadStream() async {
    setState(() {
      _loading = true;
      _status = '';
      _report = null;
      _recommendations = null;
      _progress = null;
    });

    try {
      await for (final event in _streamWithTokenRetry(File(_filePath!))) {
        final type = (event['type'] ?? '').toString();
        if (type == 'start') {
          setState(() {
            _progress = {
              'current': 0,
              'total': event['total'] ?? 0,
              'extracted': event['extracted'] ?? event['total'] ?? 0,
              'matchedCount': 0,
              'latestTitle': null,
              'latestRef': '',
              'lastResult': null,
            };
          });
        } else if (type == 'progress') {
          final currentMatched =
              ((_progress?['matchedCount'] as int?) ?? 0) +
              ((event['matched'] ?? false) == true ? 1 : 0);
          setState(() {
            _progress = {
              'current': event['current'] ?? 0,
              'total': event['total'] ?? (_progress?['total'] ?? 0),
              'extracted': _progress?['extracted'] ?? event['total'] ?? 0,
              'matchedCount': currentMatched,
              'latestTitle': event['matched'] == true
                  ? event['title']?.toString()
                  : null,
              'latestRef': event['reference_text']?.toString() ?? '',
              'lastResult': event['matched'] == true ? 'matched' : 'miss',
            };
          });
        } else if (type == 'done') {
          final report = Map<String, dynamic>.from(event);
          report.remove('type');
          setState(() {
            _report = report;
            _progress = null;
            _status =
                'Loaded citation report (${(report['references_processed'] ?? 0)} references processed).';
          });
          await _loadRecommendations(report, 'upload');
        } else if (type == 'error') {
          throw Exception(event['message']?.toString() ?? 'Server error');
        }
      }
    } catch (e) {
      setState(
        () => _status =
            'Citation intelligence failed: ${_friendlyError(e, 'Request failed')}',
      );
    } finally {
      _stopLoadingAnimation();
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveResult() async {
    if (_report == null) {
      return;
    }
    if (widget.jwtToken.trim().isEmpty) {
      setState(
        () => _status = 'Add JWT token in Setup to save citation results.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _status = '';
    });

    try {
      final title = _mode == 'discover'
          ? (_titleController.text.trim().isEmpty
                ? 'Project Discovery Citations'
                : _titleController.text.trim())
          : (_filePath == null
                ? 'Uploaded Paper Citations'
                : _filePath!.split(Platform.pathSeparator).last);

      final summary =
          '${(_report?['references_processed'] ?? 0)} processed • ${(_report?['matched_count'] ?? 0)} matched';

      await _withTokenRetry(
        (api) => api.createSavedItem(
          section: 'citation_intelligence',
          title: title,
          summary: summary,
          payload: {
            'mode': _mode,
            'projectTitle': _titleController.text.trim(),
            'basicDetails': _detailsController.text.trim(),
            'topicPreset': _topicPreset,
            'report': _report,
            'recommendations': _recommendations,
          },
        ),
      );

      setState(() => _status = 'Citation result saved.');
    } catch (e) {
      setState(
        () => _status = 'Save failed: ${_friendlyError(e, 'Request failed')}',
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _run() async {
    if (_mode == 'upload' && (_filePath == null || _filePath!.isEmpty)) {
      setState(() => _status = 'Pick a file first.');
      return;
    }
    if (_mode == 'discover' && _titleController.text.trim().isEmpty) {
      setState(() => _status = 'Enter project title first.');
      return;
    }

    setState(() {
      _loading = true;
      _startLoadingAnimation();
      _status = '';
      _report = null;
      _recommendations = null;
      _progress = null;
    });

    try {
      if (_mode == 'upload') {
        await _runUploadStream();
        return;
      }

      final report = await _withTokenRetry(
        (api) => api.discoverCitations(
          projectTitle: _titleController.text.trim(),
          basicDetails: _detailsController.text.trim(),
          topicPreset: _topicPreset == 'auto' ? null : _topicPreset,
        ),
      );

      setState(() {
        _report = report;
        _status =
            'Loaded citation report (${(report['references_processed'] ?? 0)} references processed).';
      });
      await _loadRecommendations(report, 'discover');
    } catch (e) {
      setState(
        () => _status =
            'Citation intelligence failed: ${_friendlyError(e, 'Request failed')}',
      );
    } finally {
      _stopLoadingAnimation();
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final topCited = _sortedTopCited();
    final yearCounts = _yearwiseCounts();
    final missingRefs = _missingReferences();
    final maxYearCount = yearCounts.fold<int>(
      1,
      (prev, item) => (item['count'] ?? 0) > prev ? (item['count'] ?? 0) : prev,
    );
    final progressCurrent = (_progress?['current'] as int?) ?? 0;
    final progressTotal = (_progress?['total'] as int?) ?? 0;
    final progressValue = progressTotal > 0
        ? progressCurrent / progressTotal
        : null;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        PostSigninSectionCard(
          title: 'Citation Intelligence Pro',
          icon: Icons.auto_graph_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF2A3448), Color(0xFF3D4A66)]
                        : const [Color(0xFFECF2FF), Color(0xFFDEE8FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF5A6A8F)
                        : const Color(0xFFC8D8FA),
                  ),
                ),
                child: Text(
                  'Analyze uploaded references or discover domain papers, rank evidence by citation impact and recency, and generate guided reading priorities.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF2D456D),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'upload', label: Text('Upload Paper')),
                  ButtonSegment(
                    value: 'discover',
                    label: Text('Discover Topic'),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) {
                  setState(() => _mode = selection.first);
                },
              ),
              const SizedBox(height: 10),
              if (_mode == 'upload')
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
                )
              else ...[
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Project Title',
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
                  controller: _detailsController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Basic Details',
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
                DropdownButtonFormField<String>(
                  initialValue: _topicPreset,
                  decoration: InputDecoration(
                    labelText: 'Topic Preset',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDark
                        ? colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.3,
                          )
                        : Colors.white,
                  ),
                  items: const [
                    DropdownMenuItem(value: 'auto', child: Text('Auto Detect')),
                    DropdownMenuItem(
                      value: 'plant_pathology',
                      child: Text('Plant Pathology'),
                    ),
                    DropdownMenuItem(
                      value: 'agricultural_disease',
                      child: Text('Agricultural Disease'),
                    ),
                    DropdownMenuItem(
                      value: 'medical_imaging',
                      child: Text('Medical Imaging'),
                    ),
                    DropdownMenuItem(
                      value: 'medical_diagnosis',
                      child: Text('Medical Diagnosis'),
                    ),
                    DropdownMenuItem(
                      value: 'remote_sensing',
                      child: Text('Remote Sensing'),
                    ),
                    DropdownMenuItem(
                      value: 'climate_earth_observation',
                      child: Text('Climate / Earth Observation'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _topicPreset = value);
                    }
                  },
                ),
              ],
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _loading ? null : _run,
                icon: const Icon(Icons.play_circle_fill_rounded),
                label: Text(_loading ? 'Running...' : 'Run Citation Analysis'),
              ),
              if (_loading) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark
                        ? colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.35,
                          )
                        : const Color(0xFFF4F8FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? colorScheme.outline.withValues(alpha: 0.35)
                          : const Color(0xFFD8E4FA),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Finding papers...',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ..._processStepsForMode().asMap().entries.map((entry) {
                        final active = entry.key == _loadingStepIndex;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(
                                active
                                    ? Icons.timelapse_rounded
                                    : Icons.check_circle_outline_rounded,
                                size: 14,
                                color: active
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 220),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: active
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: active
                                        ? colorScheme.primary
                                        : colorScheme.onSurface.withValues(
                                            alpha: 0.75,
                                          ),
                                  ),
                                  child: Text(entry.value),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 10),
                PostSigninInfoBox(text: _status),
              ],
              if (_progress != null) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF5F4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Streaming progress: $progressCurrent / $progressTotal',
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: progressValue),
                      const SizedBox(height: 8),
                      Text('Matched: ${(_progress?['matchedCount'] ?? 0)}'),
                      if (((_progress?['latestRef'] ?? '') as String)
                          .isNotEmpty)
                        Text(
                          'Latest reference: ${(_progress?['latestRef'] ?? '').toString()}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.justify,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (_report != null)
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saving ? null : _saveResult,
                  icon: const Icon(Icons.bookmark_add_rounded),
                  label: Text(_saving ? 'Saving...' : 'Save Results'),
                ),
              ),
            ],
          ),
        if (_report != null) const SizedBox(height: 10),
        if (_report != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Wrap(
                alignment: WrapAlignment.spaceEvenly,
                spacing: 20,
                runSpacing: 10,
                children: [
                  _metric(
                    context,
                    'Processed',
                    (_report?['references_processed'] ?? '0').toString(),
                  ),
                  _metric(
                    context,
                    'Matched',
                    (_report?['matched_count'] ?? '0').toString(),
                  ),
                  _metric(
                    context,
                    'Missing',
                    (_report?['missing_count'] ?? '0').toString(),
                  ),
                ],
              ),
            ),
          ),
        if (topCited.isNotEmpty) ...[
          const SizedBox(height: 10),
          _expandableBlock(
            context: context,
            title: 'Top Cited Papers',
            trailing: '${topCited.length}',
            expanded: _expandTopCited,
            onToggle: () {
              setState(() => _expandTopCited = !_expandTopCited);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    initialValue: _sortOrder,
                    decoration: const InputDecoration(
                      labelText: 'Sort',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'newest', child: Text('Newest')),
                      DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
                      DropdownMenuItem(
                        value: 'highest',
                        child: Text('Highest Citations'),
                      ),
                      DropdownMenuItem(
                        value: 'lowest',
                        child: Text('Lowest Citations'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _sortOrder = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 8),
                ...topCited.take(12).map((entry) {
                  final url = (entry['url'] ?? '').toString();
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.35,
                            )
                          : const Color(0xFFF7FAFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark
                            ? colorScheme.outline.withValues(alpha: 0.35)
                            : const Color(0xFFE1EAF8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (entry['title'] ?? 'Unknown title').toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(entry['year'] ?? '-').toString()} • citations: ${(entry['citation_count'] ?? '0').toString()}',
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.78,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (url.isNotEmpty)
                          IconButton(
                            tooltip: 'Open paper',
                            icon: const Icon(Icons.open_in_new_rounded),
                            onPressed: () => _openPaperUrl(url),
                          ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        if (yearCounts.isNotEmpty) ...[
          const SizedBox(height: 10),
          _expandableBlock(
            context: context,
            title: 'Year-wise Distribution',
            trailing: '${yearCounts.length}',
            expanded: _expandYearwise,
            onToggle: () {
              setState(() => _expandYearwise = !_expandYearwise);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...yearCounts.take(10).map((item) {
                  final year = (item['year'] ?? 0).toString();
                  final count = item['count'] ?? 0;
                  final fraction = maxYearCount > 0
                      ? count / maxYearCount
                      : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(width: 56, child: Text(year)),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: fraction,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          child: Text('$count', textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        if (missingRefs.isNotEmpty) ...[
          const SizedBox(height: 10),
          _expandableBlock(
            context: context,
            title: 'Unmatched References',
            trailing: '${missingRefs.length}',
            expanded: _expandUnmatched,
            onToggle: () {
              setState(() => _expandUnmatched = !_expandUnmatched);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...missingRefs.take(10).map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? colorScheme.surfaceContainerHighest.withValues(
                                alpha: 0.35,
                              )
                            : const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (entry['reference_text'] ?? 'Unknown reference')
                            .toString(),
                        textAlign: TextAlign.justify,
                        style: const TextStyle(height: 1.34),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        if (_recommendations != null) ...[
          const SizedBox(height: 10),
          _expandableBlock(
            context: context,
            title: 'AI Reading Guidance',
            trailing:
                '${((_recommendations?['reading_path'] as List<dynamic>?) ?? const []).length}',
            expanded: _expandGuidance,
            onToggle: () {
              setState(() => _expandGuidance = !_expandGuidance);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (((_recommendations?['reading_path'] as List<dynamic>?) ??
                        const [])
                    .isEmpty)
                  const Text('No reading path suggestions returned.')
                else
                  ...((_recommendations?['reading_path'] as List<dynamic>).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(
                            child: Text(
                              item.toString(),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                if (((_recommendations?['coverage_gaps'] as List<dynamic>?) ??
                        const [])
                    .isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    'Coverage Gaps',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  ...((_recommendations?['coverage_gaps'] as List<dynamic>).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• '),
                          Expanded(
                            child: Text(
                              item.toString(),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        Text(label),
      ],
    );
  }
}
