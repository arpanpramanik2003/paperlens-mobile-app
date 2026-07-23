import 'package:flutter/material.dart';
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

  String _complexity = 'medium';
  bool _loading = false;
  int? _expandingIndex;
  bool _saving = false;
  String _status = '';
  List<Map<String, dynamic>> _ideas = const [];
  int? _expandedIndex;
  final Map<int, Map<String, dynamic>> _ideaDetails = {};

  static const _presetDomains = [
    ('LLM Reasoning', 'Artificial Intelligence', 'LLM Reasoning & Chain of Thought'),
    ('Computer Vision', 'Computer Vision', 'Multimodal Diffusion & Video Generation'),
    ('Robotics', 'Robotics', 'Embodied AI & Manipulation'),
    ('Bioinformatics', 'Bioinformatics', 'Protein Folding & Drug Discovery'),
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
      setState(() => _status = 'Enter a domain first.');
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
      _status = 'Expanding methodology & evaluation plan...';
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
    final summary = (idea['summary'] ?? idea['problem_statement'] ?? '').toString();
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
            subtitle: 'AI-formulated novel research directions, problem statements, and testable hypotheses.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preset Domain Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _presetDomains.map((preset) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          label: Text(preset.$1),
                          onPressed: () {
                            setState(() {
                              _domainController.text = preset.$2;
                              _subdomainController.text = preset.$3;
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

                if (_status.isNotEmpty)
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
                      _loading ? 'Generating Novel Proposals...' : 'Generate Research Proposals',
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

          // Generated Proposals
          if (_ideas.isNotEmpty) ...[
            Text(
              'Novel Research Proposals (${_ideas.length})',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
            ),
            const SizedBox(height: 12),
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
    final summary = (idea['summary'] ?? idea['problem_statement'] ?? idea['description'] ?? '').toString();
    final hypothesis = (idea['hypothesis'] ?? idea['core_hypothesis'] ?? '').toString();
    final isExpanded = _expandedIndex == index;
    final isExpanding = _expandingIndex == index;
    final details = _ideaDetails[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: SaaSTheme.glassCardDecoration(isDark: isDark, borderRadius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: SaaSTheme.accentMagenta.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lightbulb_rounded, color: SaaSTheme.accentMagenta, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(summary, style: TextStyle(fontSize: 13, height: 1.45, color: subtextColor)),

          if (hypothesis.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? SaaSTheme.bgDarkSecondary : SaaSTheme.bgLightSecondary,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
              ),
              child: Row(
                children: [
                  const Icon(Icons.science_rounded, size: 14, color: SaaSTheme.primaryTeal),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Hypothesis: $hypothesis',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (isExpanded && details != null) ...[
            const SizedBox(height: 14),
            Divider(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight, height: 1),
            const SizedBox(height: 14),
            Text('Expanded Methodology Brief', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 6),
            Text(
              (details['methodology'] ?? details['details'] ?? details['expanded'] ?? 'Detailed plan generated.').toString(),
              style: TextStyle(fontSize: 12, height: 1.5, color: subtextColor),
            ),
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
                label: Text(isExpanded ? 'Collapse' : 'Expand Brief'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
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
                  elevation: 0,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 60).ms, duration: 400.ms);
  }
}
