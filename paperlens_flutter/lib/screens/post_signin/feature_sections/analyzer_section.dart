import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../landing/landing_theme.dart';
import '../shared_widgets.dart';

class _StructuredTextView extends StatelessWidget {
  const _StructuredTextView({required this.text});

  final String text;

  TextSpan _parseRichText(String raw, TextStyle baseStyle, TextStyle boldStyle) {
    final spans = <TextSpan>[];
    final regExp = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final match in regExp.allMatches(raw)) {
      if (match.start > start) {
        spans.add(TextSpan(text: raw.substring(start, match.start), style: baseStyle));
      }
      spans.add(TextSpan(text: match.group(1), style: boldStyle));
      start = match.end;
    }

    if (start < raw.length) {
      spans.add(TextSpan(text: raw.substring(start), style: baseStyle));
    }

    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final bodyColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;
    final accentBoldColor = isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark;

    final baseStyle = TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 13.5,
      color: bodyColor,
      height: 1.6,
    );

    final boldStyle = TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 13.5,
      color: accentBoldColor,
      height: 1.6,
    );

    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Check for Headings (# Heading or ## Heading)
      if (trimmed.startsWith('#')) {
        final headingText = trimmed.replaceAll(RegExp(r'^#+\s*'), '').replaceAll(RegExp(r'\*\*'), '').trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 14, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    headingText,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: headingColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Check for Bullet Points (* item, - item, • item)
      final isBullet = trimmed.startsWith('* ') || trimmed.startsWith('- ') || trimmed.startsWith('• ');
      // Check for Numbered Points (1. item, 2. item)
      final numMatch = RegExp(r'^(\d+)\.\s+').firstMatch(trimmed);

      if (isBullet) {
        final content = trimmed.replaceFirst(RegExp(r'^[\*\-\•]\s*'), '');
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 7, right: 10),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark).withValues(alpha: 0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SelectableText.rich(
                    _parseRichText(content, baseStyle, boldStyle),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (numMatch != null) {
        final numStr = numMatch.group(1)!;
        final content = trimmed.substring(numMatch.end);
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2, right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    numStr,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                    ),
                  ),
                ),
                Expanded(
                  child: SelectableText.rich(
                    _parseRichText(content, baseStyle, boldStyle),
                    textAlign: TextAlign.justify,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        // Standard Paragraph (Justified alignment)
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: SelectableText.rich(
              _parseRichText(trimmed, baseStyle, boldStyle),
              textAlign: TextAlign.justify,
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

class _AnalysisProgressIndicator extends StatefulWidget {
  const _AnalysisProgressIndicator();

  @override
  State<_AnalysisProgressIndicator> createState() => _AnalysisProgressIndicatorState();
}

class _AnalysisProgressIndicatorState extends State<_AnalysisProgressIndicator> {
  int _step = 0;
  Timer? _timer;

  static const _steps = [
    'Uploading document & parsing PDF structure...',
    'Extracting methodologies, equations & proofs...',
    'Synthesizing core findings & literature context...',
    'Finalizing structured AI summary report...',
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1400), (_) {
      if (!mounted) return;
      setState(() => _step = (_step + 1) % _steps.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        LinearProgressIndicator(
          color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
          backgroundColor: isDark ? SaaSTheme.bgDarkSecondary : SaaSTheme.bgLightSecondary,
        ),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Row(
            key: ValueKey(_step),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _steps[_step],
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        double dotOpacity(double start) {
          final local = (t - start) * 3;
          if (local <= 0) return 0.25;
          if (local >= 1) return 1;
          return 0.25 + (0.75 * local);
        }

        Widget dot(double opacity) {
          return Opacity(
            opacity: opacity,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                shape: BoxShape.circle,
              ),
            ),
          );
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(dotOpacity(0.0)),
            const SizedBox(width: 4),
            dot(dotOpacity(0.2)),
            const SizedBox(width: 4),
            dot(dotOpacity(0.4)),
          ],
        );
      },
    );
  }
}

class PostSigninAnalyzerSection extends StatefulWidget {
  const PostSigninAnalyzerSection({
    super.key,
    required this.loadingAnalyze,
    required this.onAnalyzePaper,
    required this.docId,
    required this.analysisText,
    required this.questionController,
    required this.loadingAsk,
    required this.onAskQuestion,
    required this.chatMessages,
  });

  final bool loadingAnalyze;
  final VoidCallback onAnalyzePaper;
  final String docId;
  final String analysisText;
  final TextEditingController questionController;
  final bool loadingAsk;
  final VoidCallback onAskQuestion;
  final List<Map<String, String>> chatMessages;

  @override
  State<PostSigninAnalyzerSection> createState() => _PostSigninAnalyzerSectionState();
}

class _PostSigninAnalyzerSectionState extends State<PostSigninAnalyzerSection> {
  final ScrollController _chatScrollController = ScrollController();
  int _selectedViewTab = 0; // 0 = Dual View, 1 = Summary Only, 2 = Q&A Chat Only

  static const _quickPrompts = [
    'Summarize core contribution in 5 bullets',
    'What are key assumptions & limitations?',
    'List reproducibility risks in methodology',
    'Suggest 3 follow-up experiment ideas',
  ];

  @override
  void didUpdateWidget(covariant PostSigninAnalyzerSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatMessages.length != widget.chatMessages.length ||
        oldWidget.loadingAsk != widget.loadingAsk) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }
  }

  void _scrollToBottom() {
    if (!_chatScrollController.hasClients) return;
    final target = _chatScrollController.position.maxScrollExtent + 40;
    _chatScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _chatScrollController.dispose();
    super.dispose();
  }

  Widget _chatBubble({
    required BuildContext context,
    required bool isUser,
    required String text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = isUser
        ? (isDark ? SaaSTheme.primaryTeal.withValues(alpha: 0.18) : SaaSTheme.primaryTealDark.withValues(alpha: 0.12))
        : (isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary);
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final borderColor = isUser
        ? (isDark ? SaaSTheme.primaryTeal.withValues(alpha: 0.4) : SaaSTheme.primaryTealDark)
        : (isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isUser ? 16 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 16),
            ),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUser ? Icons.person_rounded : Icons.smart_toy_rounded,
                    size: 14,
                    color: isUser
                        ? (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)
                        : SaaSTheme.accentViolet,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isUser ? 'You' : 'PaperLens AI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isUser
                          ? (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark)
                          : SaaSTheme.accentViolet,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (isUser)
                SelectableText(
                  text,
                  style: TextStyle(color: textColor, height: 1.45, fontSize: 13),
                )
              else
                _StructuredTextView(text: text),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final subtextColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    final hasDocument = widget.docId.isNotEmpty;
    final hasAnalysis = widget.analysisText.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Upload Dropzone Card
          PostSigninSectionCard(
            title: 'Paper Analyzer Studio',
            subtitle: 'Upload any academic paper (PDF/DOCX) to synthesize methodology, equations, and interrogate context.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? SaaSTheme.surfaceDark.withValues(alpha: 0.6) : SaaSTheme.bgLightSecondary,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? SaaSTheme.borderDarkGlowing : SaaSTheme.borderLight,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_upload_rounded,
                          size: 28,
                          color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Upload PDF or DOCX Research Paper',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supports arXiv, IEEE, Springer, ACM, and custom PDF documents.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: subtextColor),
                      ),
                      const SizedBox(height: 16),

                      if (widget.loadingAnalyze)
                        const _AnalysisProgressIndicator()
                      else
                        ElevatedButton.icon(
                          onPressed: widget.onAnalyzePaper,
                          icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                          label: Text(
                            hasDocument ? 'Select Different Paper' : 'Choose Paper File',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                            foregroundColor: const Color(0xFF041814),
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                ),

                if (hasDocument) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: SaaSTheme.primaryTeal.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 14, color: SaaSTheme.primaryTeal),
                            const SizedBox(width: 6),
                            Text(
                              'ACTIVE DOC: ${widget.docId}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main Results Section (Dual-Pane / View Mode Switcher)
          if (hasAnalysis) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Paper Analysis & Interrogation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _viewTabChip(0, 'Dual View', Icons.view_column_rounded, isDark),
                      const SizedBox(width: 4),
                      _viewTabChip(1, 'Summary Only', Icons.article_rounded, isDark),
                      const SizedBox(width: 4),
                      _viewTabChip(2, 'Q&A Chat Only', Icons.chat_rounded, isDark),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;
                final showSummary = _selectedViewTab == 0 || _selectedViewTab == 1;
                final showChat = _selectedViewTab == 0 || _selectedViewTab == 2;

                return Flex(
                  direction: (isWide && _selectedViewTab == 0) ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Analysis Summary Box
                    if (showSummary)
                      Expanded(
                        flex: (isWide && _selectedViewTab == 0) ? 1 : 0,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: SaaSTheme.glassCardDecoration(
                            isDark: isDark,
                            borderRadius: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.summarize_rounded, color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'AI Synthesis Summary',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {
                                      Clipboard.setData(ClipboardData(text: widget.analysisText));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Copied synthesis summary to clipboard!')),
                                      );
                                    },
                                    icon: const Icon(Icons.copy_rounded, size: 16),
                                    tooltip: 'Copy Summary',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _StructuredTextView(text: widget.analysisText),
                            ],
                          ),
                        ),
                      ),

                    if (isWide && _selectedViewTab == 0) const SizedBox(width: 16),
                    if (!isWide && showSummary && showChat) const SizedBox(height: 20),

                    // Contextual Q&A Chat Box
                    if (showChat)
                      Expanded(
                        flex: (isWide && _selectedViewTab == 0) ? 1 : 0,
                        child: Container(
                          height: 540,
                          padding: const EdgeInsets.all(18),
                          decoration: SaaSTheme.glassCardDecoration(
                            isDark: isDark,
                            borderRadius: 20,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.chat_rounded, color: isDark ? SaaSTheme.accentViolet : SaaSTheme.primaryTealDark, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Contextual Paper Chat',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Quick Prompt Suggestions Chips
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                child: Row(
                                  children: _quickPrompts.map((prompt) {
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: ActionChip(
                                        label: Text(prompt),
                                        onPressed: () {
                                          widget.questionController.text = prompt;
                                          widget.onAskQuestion();
                                        },
                                        backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
                                        labelStyle: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight,
                                        ),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Chat Message Stream
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? SaaSTheme.bgDarkSecondary : SaaSTheme.bgLightSecondary,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight),
                                  ),
                                  child: widget.chatMessages.isEmpty
                                      ? Center(
                                          child: Text(
                                            'Ask any question about equations, proofs, or claims in this paper.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(fontSize: 12, color: subtextColor),
                                          ),
                                        )
                                      : ListView.builder(
                                          controller: _chatScrollController,
                                          itemCount: widget.chatMessages.length + (widget.loadingAsk ? 1 : 0),
                                          itemBuilder: (context, index) {
                                            if (index == widget.chatMessages.length) {
                                              return const Padding(
                                                padding: EdgeInsets.symmetric(vertical: 8),
                                                child: Row(
                                                  children: [
                                                    _TypingDots(),
                                                    SizedBox(width: 8),
                                                    Text('AI is analyzing paper context...', style: TextStyle(fontSize: 12, color: SaaSTheme.textMutedDark)),
                                                  ],
                                                ),
                                              );
                                            }
                                            final msg = widget.chatMessages[index];
                                            final role = (msg['role'] ?? 'user') == 'user';
                                            return _chatBubble(context: context, isUser: role, text: msg['content'] ?? '');
                                          },
                                        ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Ask Question Input Field Bar
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: widget.questionController,
                                      decoration: InputDecoration(
                                        hintText: 'Ask a question about this paper...',
                                        hintStyle: TextStyle(fontSize: 12, color: subtextColor),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      ),
                                      onSubmitted: (_) => widget.onAskQuestion(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton.filled(
                                    onPressed: widget.loadingAsk ? null : widget.onAskQuestion,
                                    style: IconButton.styleFrom(
                                      backgroundColor: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                                      foregroundColor: const Color(0xFF041814),
                                    ),
                                    icon: const Icon(Icons.send_rounded, size: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _viewTabChip(int index, String label, IconData icon, bool isDark) {
    final isSelected = _selectedViewTab == index;
    final activeColor = isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: isSelected ? (isDark ? const Color(0xFF041814) : Colors.white) : (isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight)),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedViewTab = index),
      selectedColor: activeColor,
      backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
        color: isSelected ? (isDark ? const Color(0xFF041814) : Colors.white) : (isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight),
      ),
    );
  }
}
