import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';

import '../shared_widgets.dart';

class _PlannerStep {
  const _PlannerStep({
    required this.num,
    required this.title,
    required this.details,
    required this.params,
    required this.risks,
    required this.icon,
  });

  final int num;
  final String title;
  final String details;
  final String params;
  final String risks;
  final IconData icon;
}

class PostSigninPlannerSection extends StatefulWidget {
  const PostSigninPlannerSection({
    super.key,
    required this.topicController,
    required this.difficulty,
    required this.onDifficultyChanged,
    required this.loadingPlanner,
    required this.onPlanExperiment,
    required this.onSavePlan,
    required this.planSteps,
  });

  final TextEditingController topicController;
  final String difficulty;
  final ValueChanged<String> onDifficultyChanged;
  final bool loadingPlanner;
  final VoidCallback onPlanExperiment;
  final Future<void> Function() onSavePlan;
  final List<dynamic> planSteps;

  @override
  State<PostSigninPlannerSection> createState() =>
      _PostSigninPlannerSectionState();
}

class _PostSigninPlannerSectionState extends State<PostSigninPlannerSection> {
  int? _expandedIndex;
  int _visibleSteps = 0;
  bool _savingPlan = false;
  String _saveStatus = '';
  final List<Timer> _revealTimers = [];

  @override
  void didUpdateWidget(covariant PostSigninPlannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loadingPlanner) {
      _cancelRevealTimers();
      if (_visibleSteps != 0) {
        setState(() {
          _visibleSteps = 0;
        });
      }
      return;
    }

    if (oldWidget.planSteps != widget.planSteps &&
        widget.planSteps.isNotEmpty) {
      _startStaggeredReveal(widget.planSteps.length);
      if (_saveStatus.isNotEmpty) {
        setState(() {
          _saveStatus = '';
        });
      }
    }
  }

  @override
  void dispose() {
    _cancelRevealTimers();
    super.dispose();
  }

  void _cancelRevealTimers() {
    for (final timer in _revealTimers) {
      timer.cancel();
    }
    _revealTimers.clear();
  }

  void _startStaggeredReveal(int total) {
    _cancelRevealTimers();
    setState(() {
      _visibleSteps = 0;
      _expandedIndex = total > 0 ? 0 : null;
    });

    for (var i = 0; i < total; i++) {
      _revealTimers.add(
        Timer(Duration(milliseconds: 140 * (i + 1)), () {
          if (!mounted) return;
          setState(() {
            _visibleSteps = i + 1;
          });
        }),
      );
    }
  }

  Future<void> _handleSavePlan() async {
    if (widget.planSteps.isEmpty || _savingPlan) return;
    setState(() {
      _savingPlan = true;
      _saveStatus = '';
    });
    try {
      await widget.onSavePlan();
      if (!mounted) return;
      setState(() {
        _saveStatus = 'Plan saved to your account.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saveStatus = 'Save failed: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _savingPlan = false;
        });
      }
    }
  }

  String _prettyLabel(String key) {
    return key
        .trim()
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  List<String> _extractMapLikeTokens(String raw) {
    String stringifyValue(dynamic value) {
      if (value is List) {
        return value
            .map((v) => v.toString().trim())
            .where((v) => v.isNotEmpty)
            .join(', ');
      }
      if (value is Map) {
        return value.entries
            .map((e) => '${_prettyLabel(e.key.toString())}: ${e.value}')
            .join(' | ');
      }
      return value.toString().trim();
    }

    final decodedCandidates = <dynamic>[];
    try {
      decodedCandidates.add(jsonDecode(raw));
    } catch (_) {
      // Try a quote-normalized pass for Python-like dict strings.
    }
    try {
      decodedCandidates.add(jsonDecode(raw.replaceAll("'", '"')));
    } catch (_) {
      // Ignore parse failure and use regex fallback.
    }

    for (final decoded in decodedCandidates) {
      if (decoded is Map) {
        final tokens = decoded.entries
            .map((entry) {
              final key = _prettyLabel(entry.key.toString());
              final value = stringifyValue(entry.value);
              if (value.isEmpty) return '';
              return '$key: $value';
            })
            .where((token) => token.isNotEmpty)
            .toList(growable: false);
        if (tokens.isNotEmpty) return tokens;
      }
    }

    final pairRegex = RegExp(r"'?(\w+)'?\s*:\s*\[(.*?)\]");
    final matches = pairRegex.allMatches(raw);
    if (matches.isEmpty) return const [];

    final tokens = <String>[];
    for (final match in matches) {
      final key = _prettyLabel((match.group(1) ?? '').trim());
      final listBody = (match.group(2) ?? '').trim();
      if (key.isEmpty || listBody.isEmpty) continue;
      final values = listBody
          .split(',')
          .map((v) => v.trim().replaceAll("'", '').replaceAll('"', ''))
          .where((v) => v.isNotEmpty)
          .join(', ');
      if (values.isEmpty) continue;
      tokens.add('$key: $values');
    }
    return tokens;
  }

  List<String> _extractListTokens(String value) {
    final raw = value.trim();
    if (raw.isEmpty) return const [];

    if (raw.startsWith('{') && raw.endsWith('}')) {
      final mappedTokens = _extractMapLikeTokens(raw);
      if (mappedTokens.isNotEmpty) {
        return mappedTokens;
      }
    }

    if (raw.startsWith('[') && raw.endsWith(']')) {
      try {
        final dynamic decoded = jsonDecode(raw);
        final dynamic list = decoded is List ? decoded : null;
        if (list is List) {
          final tokens = list
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .toList(growable: false);
          if (tokens.length >= 2) return tokens;
        }
      } catch (_) {
        // Fall back to delimiter parsing.
      }
    }

    final normalized = raw
        .replaceAll('•', ',')
        .replaceAll(';', ',')
        .replaceAll('|', ',')
        .replaceAll('\n', ',')
        .replaceAll('\r', ',');

    final chunks = normalized
        .split(',')
        .map((s) => s.trim().replaceFirst(RegExp(r'^[-*\d\.)\s]+'), '').trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);

    if (chunks.length < 2) {
      return const [];
    }

    final longPhraseCount = chunks
        .where((chunk) => chunk.split(RegExp(r'\s+')).length >= 7)
        .length;
    if (longPhraseCount >= 2) {
      // This is likely natural prose, not list items.
      return const [];
    }

    final unique = <String>[];
    for (final chunk in chunks) {
      if (!unique.contains(chunk)) {
        unique.add(chunk);
      }
      if (unique.length == 10) break;
    }
    return unique;
  }

  Widget _chipWrap({
    required List<String> values,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    required double maxChipWidth,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: values
          .map(
            (value) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxChipWidth),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 12, color: textColor),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        value,
                        softWrap: true,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  String _fallbackRisk(String title) {
    final t = title.toLowerCase();
    if (t.contains('dataset') || t.contains('curation')) {
      return 'Data leakage, imbalance, or annotation quality may reduce generalization.';
    }
    if (t.contains('preprocess') || t.contains('feature')) {
      return 'Preprocessing choices can distort signal and hurt downstream metrics.';
    }
    if (t.contains('model') || t.contains('architecture')) {
      return 'Architecture mismatch can overfit local patterns and miss robust behavior.';
    }
    if (t.contains('train') || t.contains('optimization')) {
      return 'Unstable optimization or weak hyperparameter ranges may block convergence.';
    }
    if (t.contains('evaluation') || t.contains('ablation')) {
      return 'Weak baselines or metric mismatch can produce misleading conclusions.';
    }
    if (t.contains('deploy') || t.contains('monitor')) {
      return 'Drift and infrastructure constraints may degrade production reliability.';
    }
    return 'Integration and reproducibility issues can appear if assumptions are not validated.';
  }

  IconData _iconForName(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'database':
        return Icons.storage_rounded;
      case 'cog':
        return Icons.settings_rounded;
      case 'cpu':
        return Icons.memory_rounded;
      case 'play':
        return Icons.play_arrow_rounded;
      case 'barchart3':
        return Icons.bar_chart_rounded;
      case 'flaskconical':
        return Icons.science_rounded;
      case 'eye':
        return Icons.visibility_rounded;
      case 'cloud':
        return Icons.cloud_rounded;
      case 'shield':
        return Icons.security_rounded;
      case 'checkcircle':
        return Icons.check_circle_rounded;
      case 'activity':
        return Icons.monitor_heart_rounded;
      case 'zap':
        return Icons.bolt_rounded;
      default:
        return Icons.auto_fix_high_rounded;
    }
  }

  List<_PlannerStep> _normalizedSteps() {
    return widget.planSteps
        .asMap()
        .entries
        .map((entry) {
          final raw =
              (entry.value as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{};

          final title = (raw['title'] ?? '').toString().trim().isEmpty
              ? 'Stage ${entry.key + 1}'
              : (raw['title'] ?? '').toString().trim();

          final detailsRaw = (raw['details'] ?? '').toString().trim();
          final paramsRaw = (raw['params'] ?? '').toString().trim();
          final risksRaw = (raw['risks'] ?? '').toString().trim();
          final iconName = (raw['iconName'] ?? 'Cog').toString().trim();

          return _PlannerStep(
            num: (raw['num'] is int)
                ? raw['num'] as int
                : int.tryParse((raw['num'] ?? '').toString()) ??
                      (entry.key + 1),
            title: title,
            details: detailsRaw.isEmpty
                ? 'Define and execute this stage with concrete checkpoints and measurable outcomes.'
                : detailsRaw,
            params: paramsRaw.isEmpty
                ? 'Specify core parameters, measurable targets, and acceptance thresholds.'
                : paramsRaw,
            risks: risksRaw.isEmpty ? _fallbackRisk(title) : risksRaw,
            icon: _iconForName(iconName),
          );
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final steps = _normalizedSteps();
    final maxChipWidth = (MediaQuery.sizeOf(context).width - 120)
        .clamp(220, 520)
        .toDouble();
    final visibleSteps = steps
        .take(_visibleSteps.clamp(0, steps.length))
        .toList(growable: false);

    return PostSigninSectionCard(
      title: 'Experiment Planner Pro',
      icon: Icons.science_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? const [Color(0xFF103A34), Color(0xFF146455)]
                    : const [Color(0xFFE9F8F3), Color(0xFFD7F2EB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1C6B5F)
                    : const Color(0xFFBFE4D8),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Design a Reliable Execution Plan',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0D3B33),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Generate stage-by-stage steps with explicit parameters and risk notes, aligned to your selected difficulty.',
                  style: TextStyle(
                    height: 1.35,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.85)
                        : const Color(0xFF2C5A52),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: widget.topicController,
                  decoration: InputDecoration(
                    labelText: 'Research Topic',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0D2B26) : Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: widget.difficulty,
                  items: const [
                    DropdownMenuItem(
                      value: 'beginner',
                      child: Text('Beginner'),
                    ),
                    DropdownMenuItem(
                      value: 'intermediate',
                      child: Text('Intermediate'),
                    ),
                    DropdownMenuItem(
                      value: 'advanced',
                      child: Text('Advanced'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      widget.onDifficultyChanged(v);
                    }
                  },
                  decoration: InputDecoration(
                    labelText: 'Difficulty',
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0D2B26) : Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                FilledButton.icon(
                  onPressed: widget.loadingPlanner
                      ? null
                      : widget.onPlanExperiment,
                  icon: widget.loadingPlanner
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.science_rounded),
                  label: Text(
                    widget.loadingPlanner ? 'Planning...' : 'Generate Plan',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (steps.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Execution Timeline',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _savingPlan ? null : _handleSavePlan,
                  icon: _savingPlan
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.bookmark_add_rounded, size: 18),
                  label: Text(_savingPlan ? 'Saving...' : 'Save Plan'),
                ),
              ],
            ),
            if (_saveStatus.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                _saveStatus,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _saveStatus.startsWith('Save failed')
                      ? colorScheme.error
                      : const Color(0xFF0F6A59),
                ),
              ),
            ],
            const SizedBox(height: 8),
            ...visibleSteps.asMap().entries.map((entry) {
              final i = entry.key;
              final step = entry.value;
              final expanded = _expandedIndex == i;
              final paramTokens = _extractListTokens(step.params);
              final riskTokens = _extractListTokens(step.risks);

              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 240),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset((1 - value) * 14, 0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: expanded
                          ? colorScheme.primary.withValues(alpha: 0.55)
                          : colorScheme.outline.withValues(alpha: 0.4),
                    ),
                    color: colorScheme.surface,
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            _expandedIndex = expanded ? null : i;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 15,
                                backgroundColor: colorScheme.primary.withValues(
                                  alpha: 0.18,
                                ),
                                child: Text(
                                  '${step.num}',
                                  style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                step.icon,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
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
                          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                step.details,
                                style: TextStyle(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.88,
                                  ),
                                  height: 1.38,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer
                                      .withValues(alpha: isDark ? 0.3 : 0.8),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Parameters',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (paramTokens.isNotEmpty)
                                      _chipWrap(
                                        values: paramTokens,
                                        backgroundColor: colorScheme.primary
                                            .withValues(
                                              alpha: isDark ? 0.25 : 0.12,
                                            ),
                                        textColor: colorScheme.primary,
                                        icon: Icons.tune_rounded,
                                        maxChipWidth: maxChipWidth,
                                      )
                                    else
                                      Text(step.params),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(
                                          0xFF4A2A13,
                                        ).withValues(alpha: 0.35)
                                      : const Color(0xFFFFF1E8),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(
                                            0xFFFFA26B,
                                          ).withValues(alpha: 0.35)
                                        : const Color(0xFFFFD4B8),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: Color(0xFFE65100),
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Risk Notes',
                                          style: TextStyle(
                                            color: Color(0xFF8E3D00),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    if (riskTokens.isNotEmpty)
                                      _chipWrap(
                                        values: riskTokens,
                                        backgroundColor: const Color(
                                          0xFFFFE3CF,
                                        ),
                                        textColor: const Color(0xFF8E3D00),
                                        icon: Icons.warning_rounded,
                                        maxChipWidth: maxChipWidth,
                                      )
                                    else
                                      Text(
                                        step.risks,
                                        style: const TextStyle(
                                          color: Color(0xFF8E3D00),
                                          height: 1.35,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
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
            }),
          ] else
            PostSigninInfoBox(
              text: widget.loadingPlanner
                  ? 'Building your experiment roadmap...'
                  : 'Generate a plan to view structured stages, parameters, and risk notes.',
            ),
        ],
      ),
    );
  }
}
