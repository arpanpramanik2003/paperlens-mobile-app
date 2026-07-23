import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../services/api_service.dart';
import '../../landing/landing_theme.dart';
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
  final _domainController = TextEditingController(text: 'Artificial Intelligence');
  final _subdomainController = TextEditingController(text: 'LLM Reasoning & Alignment');

  String _complexity = 'medium'; // 'low', 'medium', 'high', 'breakthrough'
  bool _loading = false;
  int? _expandingIndex;
  bool _saving = false;
  bool _copied = false;
  String _status = '';
  List<Map<String, dynamic>> _ideas = const [];
  int? _expandedIndex;
  final Map<int, Map<String, dynamic>> _ideaDetails = {};

  static const _presetDomains = [
    ('LLM Reasoning', 'Artificial Intelligence', 'LLM Reasoning & Alignment'),
    ('Computer Vision', 'Computer Vision', 'Multimodal Diffusion & Video Generation'),
    ('Medical Imaging', 'Medical Imaging', 'Radiology, MRI & Ultrasound Diagnosis'),
    ('Robotics', 'Robotics', 'Embodied AI & Manipulator Control'),
    ('Bioinformatics', 'Bioinformatics', 'Protein Structure & Drug Discovery'),
  ];

  static const _workflowGuide = [
    ('Define Domain', 'Set problem space & practical research constraints.', Icons.compass_calibration_rounded),
    ('Generate Candidates', 'Get ranked research proposals with complexity control.', Icons.auto_awesome_rounded),
    ('Expand to Brief', 'Convert one candidate idea into a complete execution roadmap.', Icons.insert_drive_file_rounded),
    ('Export & Execute', 'Save brief to workspace & execute research experiments.', Icons.download_rounded),
  ];

  @override
  void dispose() {
    _domainController.dispose();
    _subdomainController.dispose();
    super.dispose();
  }

  ApiService _apiWithCurrentToken() {
    return ApiService(baseUrl: widget.baseUrl, jwtToken: widget.getJwtToken());
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _generateIdeas() async {
    if (_domainController.text.trim().isEmpty) {
      setState(() => _status = 'Enter a research domain first.');
      return;
    }

    setState(() {
      _loading = true;
      _status = 'AI is formulating novel research proposals...';
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
            ? 'No research proposals returned.'
            : 'Generated ${ideas.length} novel research proposals!';
      });
    } catch (e) {
      setState(() => _status = 'Generation failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
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
      _status = 'Expanding execution methodology brief for idea #${index + 1}...';
    });

    try {
      final response = await _withTokenRetry(
        (api) => api.expandProblem(
          domain: _domainController.text.trim(),
          subdomain: _subdomainController.text.trim(),
          complexity: _complexity,
          idea: idea,
        ),
      );

      final expanded = (response['expanded_idea'] as Map<String, dynamic>?) ??
          (response['expanded'] as Map<String, dynamic>?) ??
          response;

      if (!mounted) return;
      setState(() {
        _ideaDetails[index] = expanded;
        _expandedIndex = index;
        _status = 'Expanded proposal brief for idea #${index + 1}.';
      });
    } catch (e) {
      _showSnack('Failed to expand proposal: $e');
    } finally {
      if (mounted) setState(() => _expandingIndex = null);
    }
  }

  Future<void> _saveIdea(Map<String, dynamic> idea, int index) async {
    if (_saving) return;
    final title = (idea['title'] ?? idea['name'] ?? 'Research Proposal').toString();
    final summary = (idea['desc'] ?? idea['summary'] ?? idea['problem_statement'] ?? '').toString();
    final fullPayload = Map<String, dynamic>.from(idea);
    if (_ideaDetails[index] != null) {
      fullPayload['expanded_details'] = _ideaDetails[index];
    }

    setState(() => _saving = true);
    try {
      await _withTokenRetry((api) => api.createSavedItem(
            section: 'problem',
            title: title,
            summary: summary.length > 140 ? '${summary.substring(0, 140)}...' : summary,
            payload: fullPayload,
          ));
      _showSnack('Saved "$title" to your Research Workspace!');
    } catch (e) {
      _showSnack('Failed to save proposal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _copyAllProposalsToClipboard() {
    if (_ideas.isEmpty) return;
    final text = _ideas.map((item) {
      final t = (item['title'] ?? item['name'] ?? 'Proposal').toString();
      final desc = (item['desc'] ?? item['summary'] ?? '').toString();
      final rating = item['rating']?.toString() ?? '4.8';
      return '### $t [Rating: $rating/5.0]\n$desc';
    }).join('\n\n---\n\n');

    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    _showSnack('Copied all proposals to clipboard!');
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
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
            title: 'Problem Generator & Hypothesis Creator',
            subtitle: 'Formulate novel research directions, testable hypotheses, and complete execution roadmaps.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preset Domain Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _presetDomains.map((preset) {
                      final isSelected = _domainController.text == preset.$2;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(preset.$1),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() {
                              _domainController.text = preset.$2;
                              _subdomainController.text = preset.$3;
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
                  controller: _domainController,
                  decoration: InputDecoration(
                    labelText: 'Research Domain',
                    hintText: 'e.g., Computer Vision, Natural Language Processing',
                    hintStyle: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _subdomainController,
                  decoration: InputDecoration(
                    labelText: 'Subdomain / Topic Focus',
                    hintText: 'e.g., Self-Supervised Vision Transformers, Diffusion Models',
                    hintStyle: TextStyle(fontSize: 12, color: subtextColor),
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  'Innovation Complexity Level',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _complexityChip('low', 'Incremental', isDark),
                    const SizedBox(width: 6),
                    _complexityChip('medium', 'Moderate', isDark),
                    const SizedBox(width: 6),
                    _complexityChip('high', 'High Impact', isDark),
                    const SizedBox(width: 6),
                    _complexityChip('breakthrough', 'Paradigm Shift', isDark),
                  ],
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
                                  _status.isEmpty ? 'Formulating novel research proposals...' : _status,
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
                    onPressed: _loading ? null : _generateIdeas,
                    icon: _loading
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF041814)))
                        : const Icon(Icons.auto_awesome_rounded, size: 18),
                    label: Text(
                      _loading ? 'Generating Proposals...' : 'Generate Research Proposals',
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
          if (_ideas.isEmpty)
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

          // Generated Proposals Output Section
          if (_ideas.isNotEmpty) ...[
            Text(
              '${_ideas.length} Novel Research Proposals Identified',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _copyAllProposalsToClipboard,
                  icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 14),
                  label: Text(_copied ? 'Copied All' : 'Copy All Proposals'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textColor,
                    side: BorderSide(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            ...List.generate(_ideas.length, (index) {
              final idea = _ideas[index];
              return _proposalCard(idea, index, isDark, textColor, subtextColor);
            }),
          ],
        ],
      ),
    );
  }

  Widget _complexityChip(String key, String label, bool isDark) {
    final isSelected = _complexity == key;
    final activeColor = isDark ? SaaSTheme.accentViolet : SaaSTheme.primaryTealDark;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _complexity = key),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? activeColor.withValues(alpha: 0.15) : (isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? activeColor : (isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight)),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500, color: isSelected ? activeColor : (isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _proposalCard(Map<String, dynamic> idea, int index, bool isDark, Color textColor, Color subtextColor) {
    final title = (idea['title'] ?? idea['name'] ?? 'Proposal #${index + 1}').toString();
    final summary = (idea['desc'] ?? idea['summary'] ?? idea['problem_statement'] ?? '').toString();
    final rating = (idea['rating'] as num?)?.toDouble() ?? 4.8;
    final tags = (idea['tags'] as List<dynamic>? ?? const []).map((t) => t.toString()).toList();

    final isExpanded = _expandedIndex == index;
    final isExpanding = _expandingIndex == index;
    final details = _ideaDetails[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor, height: 1.35),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: SaaSTheme.accentAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, size: 12, color: SaaSTheme.accentAmber),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: SaaSTheme.accentAmber),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                  ),
                  child: Text('#$tag', style: TextStyle(fontSize: 10, color: subtextColor, fontWeight: FontWeight.w600)),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 10),

          // Justified Summary Text
          SelectableText(
            summary,
            textAlign: TextAlign.justify,
            style: TextStyle(fontSize: 13, height: 1.55, color: subtextColor),
          ),

          // Expanded Execution Brief Details
          if (isExpanded && details != null) ...[
            const SizedBox(height: 14),
            Divider(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight, height: 1),
            const SizedBox(height: 14),
            Text('Execution Brief & Step-by-Step Roadmap', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 10),

            if (details['problem_statement'] != null) ...[
              Text('Problem Statement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)),
              const SizedBox(height: 4),
              SelectableText(details['problem_statement'].toString(), textAlign: TextAlign.justify, style: TextStyle(fontSize: 12, height: 1.45, color: subtextColor)),
              const SizedBox(height: 10),
            ],

            if (details['objective'] != null) ...[
              Text('Core Objective', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)),
              const SizedBox(height: 4),
              SelectableText(details['objective'].toString(), textAlign: TextAlign.justify, style: TextStyle(fontSize: 12, height: 1.45, color: subtextColor)),
              const SizedBox(height: 10),
            ],

            if (details['step_by_step'] is List && (details['step_by_step'] as List).isNotEmpty) ...[
              Text('Step-by-Step Execution Plan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)),
              const SizedBox(height: 6),
              ...(details['step_by_step'] as List).map((stepObj) {
                final sMap = stepObj is Map ? stepObj : {};
                final stepNum = sMap['step'] ?? 1;
                final sTitle = (sMap['title'] ?? '').toString();
                final sDetails = (sMap['details'] ?? '').toString();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: SaaSTheme.primaryTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Step $stepNum', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: SaaSTheme.primaryTeal)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(sTitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor)),
                            if (sDetails.isNotEmpty) Text(sDetails, style: TextStyle(fontSize: 11, color: subtextColor, height: 1.4)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],

          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: isExpanding ? null : () => _toggleIdeaDetails(index),
                icon: isExpanding
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : Icon(isExpanded ? Icons.expand_less_rounded : Icons.read_more_rounded, size: 14),
                label: Text(isExpanding ? 'Collapsing...' : (isExpanded ? 'Hide Brief' : 'Expand Brief')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _saveIdea(idea, index),
                icon: const Icon(Icons.bookmark_border_rounded, size: 14),
                label: const Text('Save Idea'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                  foregroundColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms, duration: 350.ms);
  }
}
