import 'package:flutter/material.dart';

import '../shared_widgets.dart';

class _StructuredTextView extends StatelessWidget {
  const _StructuredTextView({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final spans = <TextSpan>[];

    for (final line in lines) {
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('##')) {
        final heading = trimmed.replaceFirst(RegExp(r'^##\s*'), '').trim();
        spans.add(
          TextSpan(
            text: '$heading\n',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF0E3C36),
              height: 1.45,
            ),
          ),
        );
      } else {
        spans.add(
          TextSpan(
            text: '$line\n',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Color(0xFF2E4742),
              height: 1.45,
            ),
          ),
        );
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.justify,
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              decoration: const BoxDecoration(
                color: Color(0xFF2A4A44),
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
  State<PostSigninAnalyzerSection> createState() =>
      _PostSigninAnalyzerSectionState();
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
    final bubbleColor = isUser
        ? const Color(0xFF0E5D52)
        : const Color(0xFFF2F7F6);
    final textColor = isUser ? Colors.white : const Color(0xFF1F3A35);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isUser ? 14 : 4),
              bottomRight: Radius.circular(isUser ? 4 : 14),
            ),
            border: isUser
                ? null
                : Border.all(color: const Color(0xFFDDE8E5), width: 1),
          ),
          child: SelectableText(
            text,
            style: TextStyle(
              color: textColor,
              height: 1.42,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questionAnchorKey = GlobalKey();
    const readableTitleColor = Color(0xFF163A34);
    const readableBodyColor = Color(0xFF2B4A44);
    const inputBorderColor = Color(0xFFBFD3CF);
    final currentLineCount =
        '\n'.allMatches(widget.questionController.text).length + 1;
    final inputMinHeight = 48.0;
    final inputHeight = (inputMinHeight + ((currentLineCount - 1) * 18.0))
        .clamp(inputMinHeight, 120.0);

    return PostSigninSectionCard(
      title: 'Paper Analyzer Studio',
      icon: Icons.auto_awesome_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0E5D52), Color(0xFF197567)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.summarize_rounded, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'Analyze and Ask',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Upload a paper, get a structured summary, then ask focused questions to clarify methods, results, and limitations.',
                  style: TextStyle(color: Colors.white70, height: 1.38),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: widget.loadingAnalyze
                      ? null
                      : widget.onAnalyzePaper,
                  icon: widget.loadingAnalyze
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        )
                      : const Icon(Icons.upload_file_rounded),
                  label: Text(
                    widget.loadingAnalyze
                        ? 'Analyzing document...'
                        : 'Pick and Analyze PDF/DOCX',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0E5D52),
                  ),
                ),
              ],
            ),
          ),
          if (widget.docId.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Active document: ${widget.docId}',
                style: const TextStyle(
                  color: Color(0xFF0D4D44),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (widget.analysisText.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Analysis Summary',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FBFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE0E8E8)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10004D40),
                    blurRadius: 9,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: _StructuredTextView(text: widget.analysisText),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F8F7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDCE9E6)),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Need to ask a follow-up quickly?',
                      style: TextStyle(
                        color: Color(0xFF2B4E48),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      final targetContext = questionAnchorKey.currentContext;
                      if (targetContext == null) return;
                      Scrollable.ensureVisible(
                        targetContext,
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                        alignment: 0.08,
                      );
                    },
                    icon: const Icon(Icons.south_rounded),
                    label: const Text('Question Assistant'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFDCE6E4)),
          ],
          const SizedBox(height: 12),
          Container(
            key: questionAnchorKey,
            width: double.infinity,
            height: 460,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFCFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCE8E5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conversation',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: readableTitleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: widget.chatMessages.isEmpty && !widget.loadingAsk
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Start a conversation by asking your first question about the analyzed paper.',
                              style: TextStyle(
                                color: Color(0xFF607D78),
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView(
                          controller: _chatScrollController,
                          children: [
                            ...widget.chatMessages.map((message) {
                              final role = (message['role'] ?? '')
                                  .toLowerCase();
                              final content = (message['content'] ?? '').trim();
                              if (content.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return _chatBubble(
                                context: context,
                                isUser: role == 'user',
                                text: content,
                              );
                            }),
                            if (widget.loadingAsk)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF4F2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Assistant is typing',
                                        style: TextStyle(
                                          color: Color(0xFF2A4A44),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(width: 6),
                                      _TypingDots(),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1, color: Color(0xFFDCE6E4)),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        curve: Curves.easeOut,
                        constraints: BoxConstraints(minHeight: inputHeight),
                        child: TextField(
                          controller: widget.questionController,
                          minLines: 1,
                          maxLines: 4,
                          style: const TextStyle(
                            color: readableBodyColor,
                            fontWeight: FontWeight.w500,
                          ),
                          cursorColor: const Color(0xFF0E5D52),
                          decoration: const InputDecoration(
                            hintText:
                                'Example: What are the main limitations and future directions?',
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            hintStyle: TextStyle(color: Color(0xFF6D8A84)),
                            filled: true,
                            fillColor: Color(0xFFFFFFFF),
                            border: OutlineInputBorder(),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: inputBorderColor),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Color(0xFF0E5D52),
                                width: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: widget.loadingAsk
                          ? null
                          : widget.onAskQuestion,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(72, 48),
                      ),
                      child: Text(widget.loadingAsk ? '...' : 'Send'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
