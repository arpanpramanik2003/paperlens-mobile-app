import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../landing/landing_theme.dart';
import '../shared_widgets.dart';

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
  State<PostSigninPlannerSection> createState() => _PostSigninPlannerSectionState();
}

class _PostSigninPlannerSectionState extends State<PostSigninPlannerSection> {
  int? _expandedIndex;
  int _visibleSteps = 0;
  bool _savingPlan = false;
  bool _copied = false;
  String _saveStatus = '';
  final List<Timer> _revealTimers = [];

  static const _presetTopics = [
    ('LoRA Fine-Tuning', 'LoRA vs Full Fine-Tuning Llama-3 8B on Medical QA'),
    ('ViT Ablation', 'Vision Transformer (ViT-B/16) Patch Size Ablation on ImageNet'),
    ('Diffusion Sweep', 'Classifier-Free Guidance Scale Sweep for Text-to-Image Generation'),
    ('RLHF Alignment', 'DPO vs PPO Preference Alignment for Open-Source LLMs'),
  ];

  static const _workflowGuide = [
    ('Define Scope', 'Clarify hypothesis, constraints, and expected outcome.', Icons.center_focus_strong_rounded),
    ('Design Pipeline', 'Select data, model stack, and evaluation strategy.', Icons.account_tree_rounded),
    ('Mitigate Risk', 'Identify failure modes and add validation checkpoints.', Icons.shield_rounded),
    ('Execute', 'Run staged experiments and compare ablation outcomes.', Icons.rocket_launch_rounded),
  ];

  @override
  void didUpdateWidget(covariant PostSigninPlannerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loadingPlanner) {
      _cancelRevealTimers();
      if (_visibleSteps != 0) setState(() => _visibleSteps = 0);
      return;
    }

    if (oldWidget.planSteps != widget.planSteps && widget.planSteps.isNotEmpty) {
      _startStaggeredReveal(widget.planSteps.length);
      if (_saveStatus.isNotEmpty) setState(() => _saveStatus = '');
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
        Timer(Duration(milliseconds: 100 * (i + 1)), () {
          if (!mounted) return;
          setState(() => _visibleSteps = i + 1);
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved experiment blueprint to Research Workspace!')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save blueprint: $e')));
    } finally {
      if (mounted) setState(() => _savingPlan = false);
    }
  }

  void _copyPlanToClipboard() {
    if (widget.planSteps.isEmpty) return;
    final topic = widget.topicController.text.trim();
    final buffer = StringBuffer();
    if (topic.isNotEmpty) buffer.writeln('# $topic — Experiment Execution Blueprint\n');

    for (var i = 0; i < widget.planSteps.length; i++) {
      final s = widget.planSteps[i];
      final map = s is Map ? Map<String, dynamic>.from(s) : <String, dynamic>{};
      final num = map['num'] ?? map['step_number'] ?? map['number'] ?? (i + 1);
      final title = (map['title'] ?? map['name'] ?? 'Stage $num').toString();
      final details = (map['details'] ?? map['description'] ?? '').toString();
      final params = (map['params'] ?? map['parameters'] ?? '').toString();
      final risks = (map['risks'] ?? map['risk_mitigation'] ?? '').toString();

      buffer.writeln('### Stage $num: $title');
      if (details.isNotEmpty) buffer.writeln('$details\n');
      if (params.isNotEmpty) buffer.writeln('**Parameters & Metrics**: $params');
      if (risks.isNotEmpty) buffer.writeln('**Risk Mitigation**: $risks');
      buffer.writeln('\n---');
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied experiment blueprint to clipboard!')));
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    final steps = widget.planSteps;
    final count = steps.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostSigninSectionCard(
            title: 'Experiment Planner Studio',
            subtitle: 'Turn research topics into step-by-step methodology blueprints, baseline recommendations, and metric checklists.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Topic presets
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _presetTopics.map((preset) {
                      final isSelected = widget.topicController.text == preset.$2;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(preset.$1),
                          selected: isSelected,
                          onSelected: (_) => setState(() => widget.topicController.text = preset.$2),
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
                  controller: widget.topicController,
                  decoration: InputDecoration(
                    labelText: 'Experiment Topic / Research Hypothesis',
                    hintText: 'e.g., Evaluating LoRA vs Full Fine-Tuning for Medical VQA',
                    hintStyle: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ),
                const SizedBox(height: 14),

                Text('Difficulty Level', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _diffChip('beginner', 'Beginner', isDark),
                    const SizedBox(width: 6),
                    _diffChip('intermediate', 'Intermediate', isDark),
                    const SizedBox(width: 6),
                    _diffChip('advanced', 'Advanced / PhD', isDark),
                  ],
                ),
                const SizedBox(height: 16),

                // Fixed-Height Loading Indicator Box (Never flexes or changes box height)
                if (widget.loadingPlanner)
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
                                  'Formulating staged experiment execution blueprint...',
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
                  ),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: widget.loadingPlanner ? null : widget.onPlanExperiment,
                    icon: widget.loadingPlanner
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF041814)))
                        : const Icon(Icons.science_rounded, size: 18),
                    label: Text(
                      widget.loadingPlanner ? 'Formulating Execution Blueprint...' : 'Generate Experiment Blueprint',
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
          if (count == 0)
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

          // Plan Steps Results Section
          if (count > 0) ...[
            Text(
              '$count-Stage Experiment Execution Blueprint',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _copyPlanToClipboard,
                  icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 14),
                  label: Text(_copied ? 'Copied' : 'Copy Blueprint'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _savingPlan ? null : _handleSavePlan,
                  icon: _savingPlan
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.bookmark_border_rounded, size: 14),
                  label: const Text('Save Blueprint'),
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

            ...List.generate(_visibleSteps.clamp(0, count), (index) {
              final step = steps[index];
              return _stepCard(step, index, isDark, textColor, subtextColor);
            }),
          ],
        ],
      ),
    );
  }

  Widget _diffChip(String key, String label, bool isDark) {
    final isSelected = widget.difficulty == key;
    final activeColor = isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onDifficultyChanged(key),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.15) : (isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? activeColor : (isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? activeColor : (isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stepCard(dynamic stepData, int index, bool isDark, Color textColor, Color subtextColor) {
    final map = stepData is Map ? Map<String, dynamic>.from(stepData) : <String, dynamic>{};
    final num = map['num'] ?? map['step_number'] ?? map['number'] ?? (index + 1);
    final title = (map['title'] ?? map['name'] ?? 'Stage $num').toString();
    final details = (map['details'] ?? map['description'] ?? '').toString();
    final params = (map['params'] ?? map['parameters'] ?? '').toString();
    final risks = (map['risks'] ?? map['risk_mitigation'] ?? '').toString();

    final isExpanded = _expandedIndex == index;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 16),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          onExpansionChanged: (exp) => setState(() => _expandedIndex = exp ? index : null),
          leading: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Stage $num', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)),
          ),
          title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (details.isNotEmpty) ...[
                    SelectableText(details, textAlign: TextAlign.justify, style: TextStyle(fontSize: 13, height: 1.55, color: subtextColor)),
                    const SizedBox(height: 12),
                  ],

                  if (params.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? SaaSTheme.surfaceDark.withValues(alpha: 0.6) : SaaSTheme.bgLightSecondary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.tune_rounded, size: 16, color: SaaSTheme.accentCyan),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Parameters & Evaluation Metrics', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? SaaSTheme.accentCyan : SaaSTheme.primaryTealDark)),
                                const SizedBox(height: 2),
                                SelectableText(params, style: TextStyle(fontSize: 12, height: 1.4, color: subtextColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (risks.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SaaSTheme.accentAmber.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SaaSTheme.accentAmber.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.shield_rounded, size: 16, color: SaaSTheme.accentAmber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Risk Mitigation Checkpoint', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: SaaSTheme.accentAmber)),
                                const SizedBox(height: 2),
                                SelectableText(risks, style: TextStyle(fontSize: 12, height: 1.4, color: textColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
