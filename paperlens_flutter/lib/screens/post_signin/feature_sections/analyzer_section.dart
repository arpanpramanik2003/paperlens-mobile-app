import 'package:flutter/material.dart';
import '../../landing/landing_theme.dart';
import '../shared_widgets.dart';

class _StructuredTextView extends StatelessWidget {
  const _StructuredTextView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headingColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final bodyColor = isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight;

    final lines = text.split('\n');
    final spans = <TextSpan>[];

    for (final line in lines) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('##') || trimmed.startsWith('#')) {
        final heading = trimmed.replaceAll(RegExp(r'^#+\s*'), '').trim();
        spans.add(
          TextSpan(
            text: '\n$heading\n',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: headingColor,
              height: 1.5,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: '$line\n',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: bodyColor,
              height: 1.55,
            ),
          ),
        );
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.start,
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
        ? (isDark ? SaaSTheme.primaryTeal.withValues(alpha: 0.2) : SaaSTheme.primaryTealDark.withValues(alpha: 0.15))
        : (isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary);
    final textColor = isDark ? SaaSTheme.textPrimaryDark : SaaSTheme.textPrimaryLight;
    final borderColor = isUser
        ? (isDark ? SaaSTheme.primaryTeal.withValues(alpha: 0.4) : SaaSTheme.primaryTealDark)
        : (isDark ? SaaSTheme.borderDark : SaaSTheme.borderLight);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
          child: SelectableText(
            text,
            style: TextStyle(
              color: textColor,
              height: 1.45,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
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
          // Section Card Header
          PostSigninSectionCard(
            title: 'Paper Analyzer Studio',
            subtitle: 'Upload any academic paper PDF or DOCX to extract key equations, methodologies, and context-aware Q&A.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upload Dropzone Box
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
                        Column(
                          children: [
                            LinearProgressIndicator(
                              color: isDark ? SaaSTheme.primaryTeal : SaaSTheme.primaryTealDark,
                              backgroundColor: isDark ? SaaSTheme.bgDarkSecondary : SaaSTheme.bgLightSecondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Analyzing paper equations & findings...',
                              style: TextStyle(fontSize: 12, color: subtextColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
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

          // Main Dual-Pane Output
          if (hasAnalysis)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 720;

                return Flex(
                  direction: isWide ? Axis.horizontal : Axis.vertical,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Analysis Summary Box
                    Expanded(
                      flex: isWide ? 1 : 0,
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
                              ],
                            ),
                            const SizedBox(height: 14),
                            _StructuredTextView(text: widget.analysisText),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(width: isWide ? 16 : 0, height: isWide ? 0 : 20),

                    // Contextual Q&A Chat Box
                    Expanded(
                      flex: isWide ? 1 : 0,
                      child: Container(
                        height: 520,
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

                            // Suggested prompt chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _promptChip('Explain core equations', isDark),
                                  _promptChip('What are key datasets?', isDark),
                                  _promptChip('Summarize limitations', isDark),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Chat message list
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
                                                  Text('AI is thinking...', style: TextStyle(fontSize: 12, color: SaaSTheme.textMutedDark)),
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

                            // Ask Question Input Bar
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
      ),
    );
  }

  Widget _promptChip(String prompt, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(prompt),
        onPressed: () {
          widget.questionController.text = prompt;
          widget.onAskQuestion();
        },
        backgroundColor: isDark ? SaaSTheme.surfaceDark : SaaSTheme.bgLightSecondary,
        labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? SaaSTheme.textMutedDark : SaaSTheme.textMutedLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }
}
