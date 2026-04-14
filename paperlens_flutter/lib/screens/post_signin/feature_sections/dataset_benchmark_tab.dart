import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
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
  final _titleController = TextEditingController();
  final _planController = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  String _status = '';
  String _summary = '';

  List<Map<String, dynamic>> _datasets = const [];
  List<Map<String, dynamic>> _benchmarks = const [];
  List<Map<String, dynamic>> _technologies = const [];
  int? _expandedDatasetIndex;
  int? _expandedBenchmarkIndex;

  @override
  void dispose() {
    _titleController.dispose();
    _planController.dispose();
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

  List<Map<String, dynamic>> _asMapList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map<String, dynamic>>().toList(growable: false);
  }

  List<String> _asStringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  String _prettyKey(String key) {
    return key
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
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
      _status = '';
      _summary = '';
      _datasets = const [];
      _benchmarks = const [];
      _technologies = const [];
      _expandedDatasetIndex = null;
      _expandedBenchmarkIndex = null;
    });

    try {
      final data = await _withTokenRetry(
        (api) =>
            api.findDatasetsBenchmarks(projectTitle: title, projectPlan: plan),
      );

      setState(() {
        _summary = (data['domain_summary'] ?? '').toString();
        _datasets = _asMapList(data['datasets']);
        _benchmarks = _asMapList(data['benchmarks']);
        _technologies = _asMapList(data['technologies']);
        _expandedDatasetIndex = _datasets.isEmpty ? null : 0;
        _expandedBenchmarkIndex = _benchmarks.isEmpty ? null : 0;
        _status =
            'Loaded ${_datasets.length} datasets and ${_benchmarks.length} benchmarks.';
      });
    } catch (e) {
      setState(() => _status = 'Finder failed: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _saveRecommendations() async {
    if (_datasets.isEmpty && _benchmarks.isEmpty && _technologies.isEmpty) {
      setState(() => _status = 'Find recommendations before saving.');
      return;
    }

    setState(() {
      _saving = true;
      _status = '';
    });

    try {
      final title = _titleController.text.trim().isEmpty
          ? 'Dataset and Benchmark Recommendations'
          : _titleController.text.trim();

      await _withTokenRetry(
        (api) => api.createSavedItem(
          section: 'dataset_benchmark_finder',
          title: title,
          summary:
              '${_datasets.length} datasets • ${_benchmarks.length} benchmarks • ${_technologies.length} technologies',
          payload: {
            'project_title': _titleController.text.trim(),
            'project_plan': _planController.text.trim(),
            'domain_summary': _summary,
            'datasets': _datasets,
            'benchmarks': _benchmarks,
            'technologies': _technologies,
          },
        ),
      );

      if (!mounted) return;
      setState(() => _status = 'Recommendations saved.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Save failed: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Widget _itemCard({
    required BuildContext context,
    required int index,
    required bool expanded,
    required VoidCallback onToggle,
    required String title,
    required String description,
    String? score,
    List<String> tags = const [],
    Map<String, dynamic>? details,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.14,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    if (score != null && score.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          score,
                          style: TextStyle(color: colorScheme.primary),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.justify,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.9),
                height: 1.35,
              ),
            ),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags
                    .map(
                      (tag) => Chip(
                        label: Text(
                          tag,
                          style: TextStyle(
                            color: isDark
                                ? colorScheme.onSecondaryContainer
                                : const Color(0xFF2D4A45),
                          ),
                        ),
                        backgroundColor: isDark
                            ? colorScheme.secondaryContainer.withValues(
                                alpha: 0.45,
                              )
                            : const Color(0xFFEAF3F2),
                        side: BorderSide.none,
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: (details == null || details.isEmpty)
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        children: details.entries
                            .map((entry) {
                              final raw = entry.value;
                              final value = raw is List
                                  ? raw
                                        .map((e) => e.toString().trim())
                                        .where((e) => e.isNotEmpty)
                                        .join(', ')
                                  : raw.toString();
                              return Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _prettyKey(entry.key),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      value,
                                      textAlign: TextAlign.justify,
                                      style: const TextStyle(height: 1.34),
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        PostSigninSectionCard(
          title: 'Dataset & Benchmark Finder',
          icon: Icons.dataset_linked_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF1E324B), Color(0xFF2F4A6B)]
                        : const [Color(0xFFEBF3FF), Color(0xFFDDEAFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF456B97)
                        : const Color(0xFFC6D9FA),
                  ),
                ),
                child: Text(
                  'Discover suitable datasets, benchmarks, and commonly used technologies from your project title and plan details, then save the recommendation package for future use.',
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF274767),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                controller: _planController,
                minLines: 4,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: 'Project Plan (optional)',
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
                onPressed: _loading ? null : _find,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.travel_explore_rounded),
                label: Text(_loading ? 'Finding...' : 'Find Recommendations'),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 10),
                PostSigninInfoBox(text: _status),
              ],
            ],
          ),
        ),
        if (_summary.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.secondaryContainer.withValues(alpha: 0.28)
                  : const Color(0xFFEFF5FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? colorScheme.outline.withValues(alpha: 0.35)
                    : const Color(0xFFD5E4FF),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Domain Summary',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(_summary, textAlign: TextAlign.justify),
              ],
            ),
          ),
        ],
        const SizedBox(height: 10),
        if (_datasets.isNotEmpty ||
            _benchmarks.isNotEmpty ||
            _technologies.isNotEmpty) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_datasets.length} datasets • ${_benchmarks.length} benchmarks • ${_technologies.length} technologies',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _saving ? null : _saveRecommendations,
                icon: _saving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_add_rounded, size: 18),
                label: Text(_saving ? 'Saving...' : 'Save'),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        if (_datasets.isNotEmpty) ...[
          Text('Datasets', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._datasets.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final tags = _asStringList(item['best_for']);
            final score = item['fit_score']?.toString();
            return _itemCard(
              context: context,
              index: index,
              expanded: _expandedDatasetIndex == index,
              onToggle: () {
                setState(() {
                  _expandedDatasetIndex = _expandedDatasetIndex == index
                      ? null
                      : index;
                });
              },
              title: (item['name'] ?? 'Dataset').toString(),
              description: (item['short_description'] ?? '').toString(),
              score: score,
              tags: tags,
              details: (item['details'] as Map?)?.cast<String, dynamic>(),
            );
          }),
        ],
        if (_benchmarks.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Benchmarks', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ..._benchmarks.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final score = item['fit_score']?.toString();
            return _itemCard(
              context: context,
              index: index,
              expanded: _expandedBenchmarkIndex == index,
              onToggle: () {
                setState(() {
                  _expandedBenchmarkIndex = _expandedBenchmarkIndex == index
                      ? null
                      : index;
                });
              },
              title: (item['name'] ?? 'Benchmark').toString(),
              description: (item['short_description'] ?? '').toString(),
              score: score,
              details: (item['details'] as Map?)?.cast<String, dynamic>(),
            );
          }),
        ],
        if (_technologies.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Technologies', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _technologies
                .map(
                  (item) => Chip(
                    label: Text(
                      '${(item['name'] ?? '').toString()} (${(item['category'] ?? '').toString()})',
                    ),
                    backgroundColor: isDark
                        ? colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.45,
                          )
                        : const Color(0xFFE8EFF8),
                    side: BorderSide.none,
                  ),
                )
                .toList(growable: false),
          ),
        ],
        if (_datasets.isEmpty && _benchmarks.isEmpty && _technologies.isEmpty)
          const PostSigninInfoBox(
            text:
                'Enter project information to discover datasets and benchmarks.',
          ),
      ],
    );
  }
}
