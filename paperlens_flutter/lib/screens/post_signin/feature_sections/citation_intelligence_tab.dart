import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../services/api_service.dart';
import '../../landing/landing_theme.dart';
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
  State<CitationIntelligenceTab> createState() => _CitationIntelligenceTabState();
}

class _CitationIntelligenceTabState extends State<CitationIntelligenceTab> {
  String _mode = 'upload'; // 'upload' or 'discover'
  String _sortOrder = 'highest'; // 'highest', 'newest', 'oldest', 'lowest'
  String _topicPreset = 'auto'; // 'auto', 'plant_pathology', 'medical_imaging', etc.
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

  static const _topicPresets = [
    ('auto', 'Auto Detect', 'Infer best domain preset'),
    ('plant_pathology', 'Plant Pathology', 'Crop disease & agricultural vision'),
    ('medical_imaging', 'Medical Imaging', 'Radiology, MRI, CT & ultrasound'),
    ('medical_diagnosis', 'Medical Diagnosis', 'Clinical decision support'),
    ('remote_sensing', 'Remote Sensing', 'Satellite & earth observation'),
  ];

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
        'Analyzing project domain intent...',
        'Querying Semantic Scholar repositories...',
        'Ranking papers by impact and citation count...',
        'Formulating AI reading roadmap & coverage gaps...',
      ];
    }
    return const [
      'Uploading paper document...',
      'Extracting bibliography references section...',
      'Matching entries with Semantic Scholar API...',
      'Calculating citation impact & network influence...',
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
    if (result == null || result.files.single.path == null) return;

    setState(() {
      _filePath = result.files.single.path;
      _status = 'Selected file: ${result.files.single.name}';
    });
  }

  String _buildPaperContext(Map<String, dynamic> report) {
    final topCited = (report['top_cited'] as List<dynamic>? ?? const [])
        .take(8)
        .map((entry) => (entry as Map<String, dynamic>)['title']?.toString() ?? '')
        .where((title) => title.isNotEmpty)
        .join('; ');

    return 'Top cited references: $topCited';
  }

  Future<void> _openPaperUrl(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null) {
      setState(() => _status = 'Invalid paper URL.');
      return;
    }

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      setState(() => _status = 'Could not open paper URL.');
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

  Future<void> _loadRecommendations(Map<String, dynamic> report, String mode) async {
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
          projectTitle: mode == 'discover' ? _titleController.text.trim() : null,
          basicDetails: mode == 'discover' ? _detailsController.text.trim() : null,
        ),
      );

      if (!mounted) return;
      setState(() => _recommendations = rec);
    } catch (_) {
      // Recommendations optional fallback
    }
  }

  Future<void> _runUploadStream() async {
    final path = _filePath ?? '';
    if (path.isEmpty || !File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a valid PDF or DOCX file first.')));
      return;
    }

    setState(() {
      _loading = true;
      _status = 'Connecting to Semantic Scholar citation graph...';
      _report = null;
      _recommendations = null;
      _progress = null;
    });
    _startLoadingAnimation();

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
            };
          });
        } else if (type == 'progress') {
          final currentMatched = ((_progress?['matchedCount'] as int?) ?? 0) + ((event['matched'] ?? false) == true ? 1 : 0);
          setState(() {
            _progress = {
              'current': event['current'] ?? 0,
              'total': event['total'] ?? (_progress?['total'] ?? 0),
              'extracted': _progress?['extracted'] ?? event['total'] ?? 0,
              'matchedCount': currentMatched,
              'latestTitle': event['matched'] == true ? event['title']?.toString() : null,
              'latestRef': event['reference_text']?.toString() ?? '',
            };
          });
        } else if (type == 'done') {
          final report = Map<String, dynamic>.from(event);
          report.remove('type');
          setState(() {
            _report = report;
            _progress = null;
            _status = 'Processed ${(report['references_processed'] ?? 0)} citations successfully!';
          });
          _loadRecommendations(report, 'upload');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Citation stream failed: $e');
    } finally {
      _stopLoadingAnimation();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _runDiscover() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a project title or domain topic.')));
      return;
    }

    setState(() {
      _loading = true;
      _status = 'Mining Semantic Scholar for domain citations...';
      _report = null;
      _recommendations = null;
      _progress = null;
    });
    _startLoadingAnimation();

    try {
      final report = await _withTokenRetry(
        (api) => api.discoverCitations(
          projectTitle: title,
          basicDetails: _detailsController.text.trim(),
          topicPreset: _topicPreset,
        ),
      );

      if (!mounted) return;
      setState(() {
        _report = report;
        _status = 'Discovered ${(report['top_cited'] as List?)?.length ?? 0} high-impact papers!';
      });
      _loadRecommendations(report, 'discover');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Discovery failed: $e');
    } finally {
      _stopLoadingAnimation();
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveMatrix() async {
    if (_report == null || _saving) return;
    final title = _mode == 'discover' ? (_titleController.text.trim().isEmpty ? 'Citation Discovery' : _titleController.text.trim()) : 'Paper Citation Graph';

    setState(() => _saving = true);
    try {
      await _withTokenRetry((api) => api.createSavedItem(
            section: 'citation',
            title: title,
            summary: 'Citation Intelligence report with ${(_report!['top_cited'] as List?)?.length ?? 0} ranked references.',
            payload: {
              'report': _report,
              'recommendations': _recommendations,
              'mode': _mode,
            },
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved "$title" to Research Workspace!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save matrix: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    final topCitedList = _sortedTopCited();
    final steps = _processStepsForMode();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostSigninSectionCard(
            title: 'Citation Intelligence Studio',
            subtitle: 'Map paper bibliography impact, uncover missing literature links, and generate AI reading roadmaps.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode Switcher Tabs
                Row(
                  children: [
                    _modeChip('upload', 'Upload Paper PDF/DOCX', Icons.upload_file_rounded, isDark),
                    const SizedBox(width: 8),
                    _modeChip('discover', 'Discover Topic Citations', Icons.travel_explore_rounded, isDark),
                  ],
                ),
                const SizedBox(height: 16),

                if (_mode == 'upload') ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? SaaSTheme.surfaceDark.withValues(alpha: 0.6) : SaaSTheme.bgLightSecondary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.picture_as_pdf_rounded, size: 30, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark),
                        const SizedBox(height: 8),
                        Text(
                          _filePath != null ? File(_filePath!).path.split(Platform.pathSeparator).last : 'Select PDF or DOCX File',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.folder_open_rounded, size: 16),
                          label: Text(_filePath != null ? 'Change File' : 'Browse Paper File'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textColor,
                            side: BorderSide(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Preset domain chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _topicPresets.map((preset) {
                        final isSelected = _topicPreset == preset.$1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(preset.$2),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _topicPreset = preset.$1),
                            selectedColor: isDark ? SaaSTheme.primaryTeal.withValues(alpha: 0.2) : SaaSTheme.primaryTealDark.withValues(alpha: 0.15),
                            backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                            labelStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                              color: isSelected ? (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark) : subtextColor,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Project / Paper Title',
                      hintText: 'e.g., Deep Residual Learning for Image Recognition',
                      hintStyle: TextStyle(fontSize: 12, color: subtextColor),
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextField(
                    controller: _detailsController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Research Scope & Domain Details',
                      hintText: 'Describe key methods, evaluation baselines, or target domains...',
                      hintStyle: TextStyle(fontSize: 12, color: subtextColor),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Loading Status Ticker
                if (_loading)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                steps[_loadingStepIndex.clamp(0, steps.length - 1)],
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        if (_progress != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Matched ${_progress!['matchedCount']} / ${_progress!['total']} references with Semantic Scholar',
                            style: TextStyle(fontSize: 10, color: subtextColor),
                          ),
                        ],
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
                    onPressed: _loading ? null : (_mode == 'upload' ? _runUploadStream : _runDiscover),
                    icon: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF041814)))
                        : const Icon(Icons.auto_graph_rounded, size: 18),
                    label: Text(
                      _loading ? 'Processing Citation Graph...' : (_mode == 'upload' ? 'Map Paper Bibliography' : 'Discover Topic Citation Network'),
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

          // Output Citation Results
          if (_report != null) ...[
            // Report Summary Header & Sort Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: SaaSTheme.primaryTeal, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Ranked Citations (${topCitedList.length})',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _saveMatrix,
                  icon: const Icon(Icons.bookmark_border_rounded, size: 14),
                  label: const Text('Save Matrix'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                    foregroundColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Sort Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _sortChip('highest', 'Highest Citations 🔥', isDark),
                  const SizedBox(width: 4),
                  _sortChip('newest', 'Newest First 📅', isDark),
                  const SizedBox(width: 4),
                  _sortChip('oldest', 'Oldest First ⏳', isDark),
                  const SizedBox(width: 4),
                  _sortChip('lowest', 'Lowest Citations', isDark),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // AI Recommendations Box
            if (_recommendations != null) ...[
              _buildRecommendationsBox(_recommendations!, isDark, textColor, subtextColor),
              const SizedBox(height: 16),
            ],

            // Citation Cards List
            ...List.generate(topCitedList.length, (index) {
              final paper = topCitedList[index];
              return _citationCard(paper, index, isDark, textColor, subtextColor);
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

  Widget _sortChip(String key, String label, bool isDark) {
    final isSelected = _sortOrder == key;
    final activeColor = isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _sortOrder = key),
      selectedColor: activeColor.withValues(alpha: 0.2),
      backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        color: isSelected ? activeColor : (isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight),
      ),
    );
  }

  Widget _citationCard(Map<String, dynamic> paper, int index, bool isDark, Color textColor, Color subtextColor) {
    final title = (paper['title'] ?? paper['reference_text'] ?? 'Untitled Citation Entry #${index + 1}').toString();
    final year = (paper['year'] ?? '').toString();
    final venue = (paper['venue'] ?? '').toString();
    final citations = (paper['citation_count'] as num?)?.toInt() ?? 0;
    final url = (paper['url'] ?? paper['paper_url'] ?? '').toString();
    final isMatched = (paper['matched'] ?? true) == true;

    final authorsList = (paper['authors'] as List<dynamic>? ?? const [])
        .map((a) => a.toString())
        .where((a) => a.isNotEmpty)
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SaaSTheme.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🔥 $citations citations',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: SaaSTheme.accentCyan),
                ),
              ),
              const SizedBox(width: 8),
              if (isMatched)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('Semantic Scholar Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.greenAccent)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor, height: 1.35),
          ),
          if (authorsList.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(authorsList, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: subtextColor)),
          ],
          if (venue.isNotEmpty || year.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text('$venue ${year.isNotEmpty ? "($year)" : ""}', style: TextStyle(fontSize: 10, color: subtextColor, fontWeight: FontWeight.w600)),
          ],

          if (url.isNotEmpty) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _openPaperUrl(url),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text('Open Paper Link'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                  side: BorderSide(color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark).withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: (index * 40).ms, duration: 350.ms);
  }

  Widget _buildRecommendationsBox(Map<String, dynamic> rec, bool isDark, Color textColor, Color subtextColor) {
    final focus = (rec['paper_focus'] ?? '').toString();
    final mustRead = (rec['must_read'] as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();
    final path = (rec['reading_path'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
    final gaps = (rec['coverage_gaps'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded, color: SaaSTheme.accentViolet, size: 20),
              const SizedBox(width: 8),
              Text('AI Reading Roadmap & Coverage Analysis', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
            ],
          ),
          if (focus.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(focus, style: TextStyle(fontSize: 12, height: 1.45, color: subtextColor)),
          ],

          if (mustRead.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Must-Read References', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 6),
            ...mustRead.map((item) {
              final t = (item['title'] ?? '').toString();
              final why = (item['why_read'] ?? '').toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.star_rounded, size: 14, color: SaaSTheme.accentAmber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor)),
                          if (why.isNotEmpty) Text(why, style: TextStyle(fontSize: 11, color: subtextColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          if (path.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Recommended Reading Path', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 6),
            ...List.generate(path.length, (idx) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('${idx + 1}. ', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: SaaSTheme.primaryTeal)),
                    Expanded(child: Text(path[idx], style: TextStyle(fontSize: 12, color: subtextColor))),
                  ],
                ),
              );
            }),
          ],

          if (gaps.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text('Identified Literature Gaps', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 6),
            ...gaps.map((gap) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, size: 14, color: SaaSTheme.accentMagenta),
                    const SizedBox(width: 6),
                    Expanded(child: Text(gap, style: TextStyle(fontSize: 12, color: subtextColor))),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
