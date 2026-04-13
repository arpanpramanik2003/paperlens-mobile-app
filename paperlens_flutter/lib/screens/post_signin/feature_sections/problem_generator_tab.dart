import 'package:flutter/material.dart';

import '../../../services/api_service.dart';
import '../shared_widgets.dart';

class ProblemGeneratorTab extends StatefulWidget {
  const ProblemGeneratorTab({
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
  State<ProblemGeneratorTab> createState() => _ProblemGeneratorTabState();
}

class _ProblemGeneratorTabState extends State<ProblemGeneratorTab> {
  final _domainController = TextEditingController();
  final _subdomainController = TextEditingController();

  String _complexity = 'medium';
  bool _loading = false;
  int? _expandingIndex;
  bool _saving = false;
  String _status = '';
  List<Map<String, dynamic>> _ideas = const [];
  int? _expandedIndex;
  final Map<int, Map<String, dynamic>> _ideaDetails = {};

  @override
  void dispose() {
    _domainController.dispose();
    _subdomainController.dispose();
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

  Future<void> _generateIdeas() async {
    if (_domainController.text.trim().isEmpty) {
      setState(() => _status = 'Enter a domain first.');
      return;
    }

    setState(() {
      _loading = true;
      _status = '';
      _ideas = const [];
      _expandedIndex = null;
      _ideaDetails.clear();
    });

    try {
      final response = await _withTokenRetry(
        (api) => api.generateProblems(
          domain: _domainController.text.trim(),
          subdomain: _subdomainController.text.trim(),
          complexity: _complexity,
        ),
      );

      final ideas = (response['ideas'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .toList(growable: false);

      setState(() {
        _ideas = ideas;
        _status = ideas.isEmpty
            ? 'No ideas returned.'
            : 'Generated ${ideas.length} ideas.';
      });
    } catch (e) {
      setState(() => _status = 'Generation failed: $e');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _toggleIdeaDetails(int index) async {
    if (_expandedIndex == index) {
      setState(() => _expandedIndex = null);
      return;
    }

    if (_ideaDetails[index] != null) {
      setState(() => _expandedIndex = index);
      return;
    }

    final idea = _ideas[index];
    setState(() {
      _expandingIndex = index;
      _status = '';
    });

    try {
      final data = await _withTokenRetry(
        (api) => api.expandProblem(
          domain: _domainController.text.trim(),
          subdomain: _subdomainController.text.trim(),
          complexity: _complexity,
          idea: idea,
        ),
      );

      setState(() {
        _ideaDetails[index] = {
          'title': (data['title'] ?? idea['title'] ?? 'Untitled idea')
              .toString(),
          'problem_statement': (data['problem_statement'] ?? idea['desc'] ?? '')
              .toString(),
          'objective': (data['objective'] ?? '').toString(),
          'step_by_step': (data['step_by_step'] as List<dynamic>? ?? const []),
          'datasets': (data['datasets'] as List<dynamic>? ?? const []),
          'evaluation_metrics':
              (data['evaluation_metrics'] as List<dynamic>? ?? const []),
          'expected_outcomes':
              (data['expected_outcomes'] as List<dynamic>? ?? const []),
        };
        _expandedIndex = index;
      });
    } catch (e) {
      setState(() => _status = 'Could not load details: $e');
    } finally {
      if (mounted) {
        setState(() => _expandingIndex = null);
      }
    }
  }

  Future<void> _saveBrief(int index) async {
    final details = _ideaDetails[index];
    if (details == null) {
      setState(() => _status = 'Open idea details before saving.');
      return;
    }
    if (widget.jwtToken.trim().isEmpty) {
      setState(() => _status = 'Add JWT token in Setup to save items.');
      return;
    }

    final idea = _ideas[index];
    setState(() {
      _saving = true;
      _status = '';
    });

    try {
      await _withTokenRetry(
        (api) => api.createSavedItem(
          section: 'problem_generator',
          title: (details['title'] ?? 'Problem Brief').toString(),
          summary: (details['problem_statement'] ?? '').toString(),
          payload: {
            'domain': _domainController.text.trim(),
            'subdomain': _subdomainController.text.trim(),
            'complexity': _complexity,
            'idea': idea,
            'brief': details,
          },
        ),
      );
      setState(() => _status = 'Problem brief saved.');
    } catch (e) {
      setState(() => _status = 'Save failed: $e');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  List<String> _toStringList(dynamic value) {
    if (value is! List) return const [];
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  Widget _detailSection(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.45)
            : const Color(0xFFF7FAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.4)
              : const Color(0xFFE2ECEB),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          child,
        ],
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
          title: 'Idea Lab Pro',
          icon: Icons.lightbulb_rounded,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? const [Color(0xFF193A45), Color(0xFF22586A)]
                        : const [Color(0xFFE8F7FD), Color(0xFFD7EDF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF35667A)
                        : const Color(0xFFB9DFF1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generate High-Quality Research Ideas',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF153D4C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Define your domain and complexity, then explore strong problem candidates with structured expansion into objective, roadmap, datasets, and measurable outcomes.',
                      style: TextStyle(
                        height: 1.35,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.85)
                            : const Color(0xFF325A68),
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _domainController,
                decoration: InputDecoration(
                  labelText: 'Domain',
                  hintText: 'e.g. NLP, CV, Healthcare AI',
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
                controller: _subdomainController,
                decoration: InputDecoration(
                  labelText: 'Subdomain',
                  hintText: 'e.g. Text Summarization',
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
                initialValue: _complexity,
                decoration: InputDecoration(
                  labelText: 'Complexity',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: isDark
                      ? colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        )
                      : Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _complexity = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _loading ? null : _generateIdeas,
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2.2),
                      )
                    : const Icon(Icons.auto_awesome_rounded),
                label: Text(_loading ? 'Generating...' : 'Generate Ideas'),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 10),
                PostSigninInfoBox(text: _status),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_ideas.isEmpty)
          const PostSigninInfoBox(
            text: 'Generate ideas to see research problems here.',
          )
        else ...[
          Text(
            'Generated Ideas',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          ..._ideas.asMap().entries.map((entry) {
            final idea = entry.value;
            final tags = (idea['tags'] as List<dynamic>? ?? const [])
                .map((e) => e.toString())
                .toList();
            final rating = (idea['rating'] ?? 3).toString();

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            (idea['title'] ?? 'Untitled idea').toString(),
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
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'Rating $rating',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (idea['desc'] ?? '').toString(),
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.9),
                        height: 1.38,
                      ),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                visualDensity: VisualDensity.compact,
                                side: BorderSide.none,
                                backgroundColor: isDark
                                    ? colorScheme.surfaceContainerHighest
                                          .withValues(alpha: 0.45)
                                    : const Color(0xFFF0F5F5),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _expandingIndex == entry.key
                              ? null
                              : () => _toggleIdeaDetails(entry.key),
                          icon: const Icon(Icons.arrow_outward_rounded),
                          label: Text(
                            _expandingIndex == entry.key
                                ? 'Loading details...'
                                : _expandedIndex == entry.key
                                ? 'Hide details'
                                : 'Use this idea',
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _saving
                              ? null
                              : () => _saveBrief(entry.key),
                          icon: const Icon(Icons.bookmark_add_rounded),
                          label: Text(_saving ? 'Saving...' : 'Save brief'),
                        ),
                      ],
                    ),
                    if (_expandedIndex == entry.key &&
                        _ideaDetails[entry.key] != null) ...[
                      const SizedBox(height: 10),
                      Builder(
                        builder: (context) {
                          final details = _ideaDetails[entry.key]!;
                          final steps =
                              (details['step_by_step'] as List<dynamic>? ??
                                      const [])
                                  .whereType<Map<String, dynamic>>()
                                  .toList(growable: false);
                          final datasets = _toStringList(details['datasets']);
                          final metrics = _toStringList(
                            details['evaluation_metrics'],
                          );
                          final outcomes = _toStringList(
                            details['expected_outcomes'],
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _detailSection(
                                context,
                                title: 'Problem Statement',
                                child: Text(
                                  (details['problem_statement'] ?? '')
                                      .toString(),
                                  textAlign: TextAlign.justify,
                                  style: const TextStyle(height: 1.36),
                                ),
                              ),
                              _detailSection(
                                context,
                                title: 'Primary Objective',
                                child: Text(
                                  (details['objective'] ?? '').toString(),
                                  textAlign: TextAlign.justify,
                                  style: const TextStyle(height: 1.36),
                                ),
                              ),
                              _detailSection(
                                context,
                                title: 'Execution Roadmap',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: steps.isEmpty
                                      ? const [Text('No steps returned.')]
                                      : steps
                                            .asMap()
                                            .entries
                                            .map((stepEntry) {
                                              final step = stepEntry.value;
                                              final num =
                                                  (step['step'] ??
                                                          stepEntry.key + 1)
                                                      .toString();
                                              final stepTitle =
                                                  (step['title'] ?? 'Step')
                                                      .toString();
                                              final stepDetails =
                                                  (step['details'] ?? '')
                                                      .toString();
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 8,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '$num. $stepTitle',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      stepDetails,
                                                      textAlign:
                                                          TextAlign.justify,
                                                    ),
                                                  ],
                                                ),
                                              );
                                            })
                                            .toList(growable: false),
                                ),
                              ),
                              _detailSection(
                                context,
                                title: 'Datasets and Tools',
                                child: datasets.isEmpty
                                    ? const Text('Not provided')
                                    : Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: datasets
                                            .map(
                                              (item) => Chip(
                                                label: Text(item),
                                                side: BorderSide.none,
                                                backgroundColor: isDark
                                                    ? const Color(0xFF18474A)
                                                    : const Color(0xFFEAF3F2),
                                              ),
                                            )
                                            .toList(growable: false),
                                      ),
                              ),
                              _detailSection(
                                context,
                                title: 'Evaluation Metrics',
                                child: metrics.isEmpty
                                    ? const Text('Not provided')
                                    : Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: metrics
                                            .map(
                                              (item) => Chip(
                                                label: Text(item),
                                                side: BorderSide.none,
                                                backgroundColor: isDark
                                                    ? const Color(0xFF3A3457)
                                                    : const Color(0xFFF0EEF9),
                                              ),
                                            )
                                            .toList(growable: false),
                                      ),
                              ),
                              _detailSection(
                                context,
                                title: 'Expected Outcomes',
                                child: outcomes.isEmpty
                                    ? const Text('Not provided')
                                    : Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: outcomes
                                            .map(
                                              (item) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 4,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Text('• '),
                                                    Expanded(
                                                      child: Text(
                                                        item,
                                                        textAlign:
                                                            TextAlign.justify,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(growable: false),
                                      ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
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
