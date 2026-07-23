import 'dart:async';
import 'package:flutter/material.dart';
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
  String _saveStatus = '';
  final List<Timer> _revealTimers = [];

  static const _presetTopics = [
    ('LoRA Fine-Tuning', 'LoRA vs Full Fine-Tuning Llama-3 8B on Medical QA'),
    ('ViT Ablation', 'Vision Transformer (ViT-B/16) Patch Size Ablation on ImageNet'),
    ('Diffusion Sweep', 'Classifier-Free Guidance Scale Sweep for Text-to-Image Generation'),
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
        Timer(Duration(milliseconds: 120 * (i + 1)), () {
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
      setState(() => _saveStatus = 'Saved experiment plan to Research Workspace!');
    } catch (e) {
      if (!mounted) return;
      setState(() => _saveStatus = 'Failed to save plan: $e');
    } finally {
      if (mounted) setState(() => _savingPlan = false);
    }
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
                  child: Row(
                    children: _presetTopics.map((preset) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(preset.$1),
                          onPressed: () => widget.topicController.text = preset.$2,
                          backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                          labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight),
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
                    const SizedBox(width: 8),
                    _diffChip('intermediate', 'Intermediate', isDark),
                    const SizedBox(width: 8),
                    _diffChip('advanced', 'Advanced / PhD', isDark),
                  ],
                ),
                const SizedBox(height: 16),

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

          // Plan Steps Results Timeline
          if (count > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Experiment Execution Steps ($count)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                ),
                ElevatedButton.icon(
                  onPressed: _savingPlan ? null : _handleSavePlan,
                  icon: _savingPlan
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.bookmark_border_rounded, size: 14),
                  label: const Text('Save Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                    foregroundColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                    elevation: 0,
                  ),
                ),
              ],
            ),
            if (_saveStatus.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(_saveStatus, style: TextStyle(fontSize: 12, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark, fontWeight: FontWeight.w600)),
            ],
            const SizedBox(height: 12),

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
    final num = map['step_number'] ?? map['number'] ?? (index + 1);
    final title = (map['title'] ?? map['name'] ?? 'Step $num').toString();
    final details = (map['description'] ?? map['details'] ?? '').toString();
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
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Text('$num', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)),
          ),
          title: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
          children: [
            if (details.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(details, style: TextStyle(fontSize: 13, height: 1.5, color: subtextColor)),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
