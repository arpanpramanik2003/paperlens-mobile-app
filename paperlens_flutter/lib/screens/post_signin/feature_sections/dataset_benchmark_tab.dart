import 'package:flutter/material.dart';
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
  String _status = '';
  String _summary = '';

  List<Map<String, dynamic>> _datasets = const [];
  List<Map<String, dynamic>> _benchmarks = const [];
  List<Map<String, dynamic>> _technologies = const [];

  static const _presets = [
    ('Vision-Language', 'Multimodal VQA Reasoning', 'Evaluate zero-shot visual question answering accuracy across open-domain scientific diagrams.'),
    ('Medical Imaging', 'Brain MRI Tumor Segmentation', 'Segment 3D MRI scans using UNet3D and Transformer encoder baselines.'),
    ('Financial NLP', 'Stock Sentiment & Earnings Call Parsing', 'Classify financial news sentiment and correlate with stock volatility metrics.'),
    ('Robotic Control', 'Quadruped Locomotion RL', 'Train PPO policies for rough-terrain quadruped locomotion in Isaac Gym simulation.'),
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
      setState(() => _status = 'Enter project title or plan first.');
      return;
    }

    setState(() {
      _loading = true;
      _status = 'AI is searching SOTA datasets and benchmark leaderboards...';
      _summary = '';
      _datasets = const [];
      _benchmarks = const [];
      _technologies = const [];
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
        _status = 'Found ${_datasets.length} datasets and ${_benchmarks.length} benchmark targets!';
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
            title: 'Dataset & Benchmark Finder Studio',
            subtitle: 'Locate SOTA evaluation datasets, leaderboards, baseline metrics, and hardware requirements.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preset Project Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _presets.map((preset) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(preset.$1),
                          onPressed: () {
                            setState(() {
                              _titleController.text = preset.$2;
                              _planController.text = preset.$3;
                            });
                          },
                          backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                          labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight),
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

                if (_status.isNotEmpty)
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
                      _loading ? 'Searching SOTA Repositories...' : 'Find Datasets & Benchmarks',
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

          // Domain Summary Card
          if (_summary.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.analytics_rounded, color: SaaSTheme.accentAmber, size: 20),
                      const SizedBox(width: 8),
                      Text('Domain Intelligence Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _saveResults,
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
                  const SizedBox(height: 10),
                  Text(_summary, style: TextStyle(fontSize: 13, height: 1.5, color: subtextColor)),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Datasets List
          if (_datasets.isNotEmpty) ...[
            Text('Recommended Datasets (${_datasets.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 12),
            ...List.generate(_datasets.length, (index) {
              final ds = _datasets[index];
              final name = (ds['name'] ?? ds['title'] ?? 'Dataset #${index + 1}').toString();
              final desc = (ds['description'] ?? ds['summary'] ?? '').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: SaaSTheme.primaryTeal.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.dataset_rounded, color: SaaSTheme.primaryTeal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
                          const SizedBox(height: 2),
                          Text(desc, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: subtextColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms);
            }),
          ],

          const SizedBox(height: 20),

          // Benchmarks List
          if (_benchmarks.isNotEmpty) ...[
            Text('SOTA Benchmarks & Leaderboards (${_benchmarks.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 12),
            ...List.generate(_benchmarks.length, (index) {
              final bm = _benchmarks[index];
              final name = (bm['name'] ?? bm['benchmark'] ?? 'Benchmark #${index + 1}').toString();
              final metric = (bm['metric'] ?? bm['target'] ?? '').toString();

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: SaaSTheme.accentCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.verified_rounded, color: SaaSTheme.accentCyan, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
                          if (metric.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text('Target Metric: $metric', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? SaaSTheme.accentCyan : SaaSTheme.primaryTealDark)),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms);
            }),
          ],
        ],
      ),
    );
  }
}
