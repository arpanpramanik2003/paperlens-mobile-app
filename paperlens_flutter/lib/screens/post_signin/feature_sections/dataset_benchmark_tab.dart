import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/api_service.dart';
import '../../landing/landing_theme.dart';
import '../shared_widgets.dart';

class DatasetBenchmarkTab extends StatefulWidget {
  const DatasetBenchmarkTab({
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
  State<DatasetBenchmarkTab> createState() => _DatasetBenchmarkTabState();
}

class _DatasetBenchmarkTabState extends State<DatasetBenchmarkTab> {
  final _titleController = TextEditingController(text: 'Multimodal Vision-Language Reasoning');
  final _planController = TextEditingController(text: 'Evaluate zero-shot visual question answering accuracy across open-domain scientific diagrams.');

  bool _loading = false;
  bool _saving = false;
  bool _copied = false;
  String _status = '';
  String _summary = '';

  List<Map<String, dynamic>> _datasets = const [];
  List<Map<String, dynamic>> _benchmarks = const [];
  List<Map<String, dynamic>> _technologies = const [];
  int? _expandedDatasetIndex;
  int? _expandedBenchmarkIndex;

  static const _presets = [
    ('Vision-Language', 'Multimodal VQA Reasoning', 'Evaluate zero-shot visual question answering accuracy across open-domain scientific diagrams.'),
    ('Medical Imaging', 'Brain MRI Tumor Segmentation', 'Segment 3D MRI scans using UNet3D and Transformer encoder baselines.'),
    ('Financial NLP', 'Stock Sentiment & Earnings Call Parsing', 'Classify financial news sentiment and correlate with stock volatility metrics.'),
    ('Robotic Control', 'Quadruped Locomotion RL', 'Train PPO policies for rough-terrain quadruped locomotion in Isaac Gym simulation.'),
  ];

  static const _workflowGuide = [
    ('Describe Project', 'Provide title and optional implementation plan scope.', Icons.compass_calibration_rounded),
    ('Match Assets', 'Find high-fit datasets and benchmark suites.', Icons.search_rounded),
    ('Compare Options', 'Review fit score, use cases, tasks and constraints.', Icons.tune_rounded),
    ('Finalize Stack', 'Choose tools and save recommendations to workspace.', Icons.verified_rounded),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _planController.dispose();
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

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  Future<void> _find() async {
    final title = _titleController.text.trim();
    final plan = _planController.text.trim();
    if (title.isEmpty && plan.isEmpty) {
      setState(() => _status = 'Enter project title or methodology plan first.');
      return;
    }

    setState(() {
      _loading = true;
      _status = 'Searching SOTA datasets, leaderboards, and technology suites...';
      _summary = '';
      _datasets = const [];
      _benchmarks = const [];
      _technologies = const [];
      _expandedDatasetIndex = null;
      _expandedBenchmarkIndex = null;
    });

    try {
      final data = await _withTokenRetry(
        (api) => api.findDatasetsBenchmarks(projectTitle: title, projectPlan: plan),
      );

      setState(() {
        _summary = (data['domain_summary'] ?? '').toString();
        _datasets = _asMapList(data['datasets']);
        _benchmarks = _asMapList(data['benchmarks']);
        _technologies = _asMapList(data['technologies']);
        _status = 'Found ${_datasets.length} datasets, ${_benchmarks.length} benchmark suites & ${_technologies.length} tools!';
      });
    } catch (e) {
      setState(() => _status = 'Search failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveResults() async {
    if (_saving) return;
    final title = _titleController.text.trim().isEmpty ? 'Dataset & Benchmark Report' : _titleController.text.trim();
    final summary = _summary.isNotEmpty ? _summary : 'Dataset and benchmark matrix mapping.';

    setState(() => _saving = true);
    try {
      await _withTokenRetry((api) => api.createSavedItem(
            section: 'dataset',
            title: title,
            summary: summary.length > 140 ? '${summary.substring(0, 140)}...' : summary,
            payload: {
              'project_title': title,
              'domain_summary': _summary,
              'datasets': _datasets,
              'benchmarks': _benchmarks,
              'technologies': _technologies,
            },
          ));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Saved "$title" matrix to Research Workspace!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save matrix: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _copySummaryToClipboard() {
    final title = _titleController.text.trim();
    final buffer = StringBuffer();
    if (title.isNotEmpty) buffer.writeln('# $title — Dataset & Benchmark Matrix\n');
    if (_summary.isNotEmpty) buffer.writeln('## Domain Summary\n$_summary\n');

    if (_datasets.isNotEmpty) {
      buffer.writeln('## Recommended Datasets');
      for (final ds in _datasets) {
        final name = (ds['name'] ?? ds['title'] ?? 'Dataset').toString();
        final desc = (ds['short_description'] ?? ds['description'] ?? '').toString();
        buffer.writeln('- **$name**: $desc');
      }
      buffer.writeln();
    }

    if (_benchmarks.isNotEmpty) {
      buffer.writeln('## SOTA Benchmarks');
      for (final bm in _benchmarks) {
        final name = (bm['name'] ?? bm['benchmark'] ?? 'Benchmark').toString();
        final desc = (bm['short_description'] ?? bm['description'] ?? '').toString();
        buffer.writeln('- **$name**: $desc');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied dataset & benchmark matrix to clipboard!')));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    final hasResults = _datasets.isNotEmpty || _benchmarks.isNotEmpty || _summary.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostSigninSectionCard(
            title: 'Dataset & Benchmark Finder Studio',
            subtitle: 'Locate SOTA evaluation datasets, leaderboards, baseline metrics, and hardware requirements.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preset Project Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _presets.map((preset) {
                      final isSelected = _titleController.text == preset.$2;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(preset.$1),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _titleController.text = preset.$2;
                              _planController.text = preset.$3;
                            });
                          },
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
                const SizedBox(height: 14),

                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Project Title',
                    hintText: 'e.g., Multimodal Vision-Language Reasoning',
                    hintStyle: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _planController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Project Methodology & Plan Scope',
                    hintText: 'Describe target domain, model architecture, or evaluation goals...',
                    hintStyle: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ),
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
                                  _status.isEmpty ? 'Searching SOTA datasets & leaderboards...' : _status,
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
                    onPressed: _loading ? null : _find,
                    icon: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF041814)))
                        : const Icon(Icons.search_rounded, size: 18),
                    label: Text(
                      _loading ? 'Searching Repositories...' : 'Find Datasets & Benchmarks',
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
          if (!hasResults)
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

          // Domain Summary & Results Section
          if (hasResults) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Domain Intelligence Summary',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                        ),
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _copySummaryToClipboard,
                            icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 14),
                            label: Text(_copied ? 'Copied' : 'Copy Matrix'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: textColor,
                              side: BorderSide(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ElevatedButton.icon(
                            onPressed: _saving ? null : _saveResults,
                            icon: const Icon(Icons.bookmark_border_rounded, size: 14),
                            label: const Text('Save Matrix'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                              foregroundColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              elevation: 0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (_summary.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    SelectableText(_summary, textAlign: TextAlign.justify, style: TextStyle(fontSize: 13, height: 1.5, color: subtextColor)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Datasets List
            if (_datasets.isNotEmpty) ...[
              Text('Recommended Evaluation Datasets (${_datasets.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 12),
              ...List.generate(_datasets.length, (index) {
                final ds = _datasets[index];
                return _datasetCard(ds, index, isDark, textColor, subtextColor);
              }),
              const SizedBox(height: 20),
            ],

            // Benchmarks List
            if (_benchmarks.isNotEmpty) ...[
              Text('SOTA Benchmarks & Leaderboards (${_benchmarks.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 12),
              ...List.generate(_benchmarks.length, (index) {
                final bm = _benchmarks[index];
                return _benchmarkCard(bm, index, isDark, textColor, subtextColor);
              }),
              const SizedBox(height: 20),
            ],

            // Technologies List
            if (_technologies.isNotEmpty) ...[
              Text('Recommended Technology Stack (${_technologies.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 600;
                  return GridView.count(
                    crossAxisCount: isWide ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: isWide ? 3.4 : 3.6,
                    children: List.generate(_technologies.length, (idx) {
                      final tech = _technologies[idx];
                      final name = (tech['name'] ?? 'Tool').toString();
                      final cat = (tech['category'] ?? 'Framework').toString();
                      final reason = (tech['reason'] ?? '').toString();

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: SaaSTheme.accentViolet.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.build_circle_rounded, color: SaaSTheme.accentViolet, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor))),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: SaaSTheme.accentViolet.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(cat, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: SaaSTheme.accentViolet)),
                                      ),
                                    ],
                                  ),
                                  if (reason.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(reason, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: subtextColor)),
                                  ],
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
          ],
        ],
      ),
    );
  }

  Widget _datasetCard(Map<String, dynamic> ds, int index, bool isDark, Color textColor, Color subtextColor) {
    final name = (ds['name'] ?? ds['title'] ?? 'Dataset #${index + 1}').toString();
    final desc = (ds['short_description'] ?? ds['description'] ?? ds['summary'] ?? '').toString();
    final fitScore = (ds['fit_score'] as num?)?.toDouble() ?? 4.8;
    final bestFor = (ds['best_for'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
    final details = (ds['details'] as Map<String, dynamic>?) ?? {};
    final isExpanded = _expandedDatasetIndex == index;

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
              Expanded(
                child: Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor, height: 1.35)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SaaSTheme.primaryTeal.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 12, color: SaaSTheme.primaryTeal),
                    const SizedBox(width: 4),
                    Text('Fit: ${fitScore.toStringAsFixed(1)}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)),
                  ],
                ),
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(desc, textAlign: TextAlign.justify, style: TextStyle(fontSize: 13, height: 1.45, color: subtextColor)),
          ],

          if (bestFor.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: bestFor.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                  ),
                  child: Text('#$item', style: TextStyle(fontSize: 10, color: subtextColor, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
          ],

          if (isExpanded && details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight, height: 1),
            const SizedBox(height: 10),
            Text('Dataset Details & Specifications', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)),
            const SizedBox(height: 6),
            if (details['modality'] != null) Text('Modality: ${details['modality']}', style: TextStyle(fontSize: 11, color: subtextColor)),
            if (details['size'] != null) Text('Size: ${details['size']}', style: TextStyle(fontSize: 11, color: subtextColor)),
            if (details['license'] != null) Text('License: ${details['license']}', style: TextStyle(fontSize: 11, color: subtextColor)),
          ],

          const SizedBox(height: 10),
          if (details.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _expandedDatasetIndex = isExpanded ? null : index),
                icon: Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 14),
                label: Text(isExpanded ? 'Hide Specs' : 'View Specs'),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 40).ms, duration: 350.ms);
  }

  Widget _benchmarkCard(Map<String, dynamic> bm, int index, bool isDark, Color textColor, Color subtextColor) {
    final name = (bm['name'] ?? bm['benchmark'] ?? 'Benchmark #${index + 1}').toString();
    final desc = (bm['short_description'] ?? bm['description'] ?? bm['summary'] ?? '').toString();
    final fitScore = (bm['fit_score'] as num?)?.toDouble() ?? 4.6;
    final details = (bm['details'] as Map<String, dynamic>?) ?? {};
    final metrics = (details['primary_metrics'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList();
    final isExpanded = _expandedBenchmarkIndex == index;

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
              Expanded(
                child: Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor, height: 1.35)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SaaSTheme.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Fit: ${fitScore.toStringAsFixed(1)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: SaaSTheme.accentCyan)),
              ),
            ],
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(desc, textAlign: TextAlign.justify, style: TextStyle(fontSize: 13, height: 1.45, color: subtextColor)),
          ],

          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: metrics.map((m) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: SaaSTheme.accentCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: SaaSTheme.accentCyan.withValues(alpha: 0.3)),
                  ),
                  child: Text('Metric: $m', style: const TextStyle(fontSize: 10, color: SaaSTheme.accentCyan, fontWeight: FontWeight.w700)),
                );
              }).toList(),
            ),
          ],

          if (isExpanded && details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Divider(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight, height: 1),
            const SizedBox(height: 10),
            Text('Evaluation Protocol & Baselines', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? SaaSTheme.accentCyan : SaaSTheme.primaryTealDark)),
            const SizedBox(height: 6),
            if (details['evaluation_protocol'] != null) Text('Protocol: ${details['evaluation_protocol']}', style: TextStyle(fontSize: 11, color: subtextColor)),
            if (details['baselines'] != null) Text('Baselines: ${(details['baselines'] as List).join(", ")}', style: TextStyle(fontSize: 11, color: subtextColor)),
          ],

          const SizedBox(height: 10),
          if (details.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _expandedBenchmarkIndex = isExpanded ? null : index),
                icon: Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, size: 14),
                label: Text(isExpanded ? 'Hide Protocol' : 'View Protocol'),
                style: TextButton.styleFrom(
                  foregroundColor: isDark ? SaaSTheme.accentCyan : SaaSTheme.primaryTealDark,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 40).ms, duration: 350.ms);
  }
}
