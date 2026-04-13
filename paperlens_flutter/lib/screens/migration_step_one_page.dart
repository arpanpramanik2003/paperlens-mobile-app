import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clerk_flutter/clerk_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import 'post_signin/feature_sections/analyzer_section.dart';
import 'post_signin/app_header.dart';
import 'post_signin/feature_sections/citation_intelligence_tab.dart';
import 'post_signin/feature_sections/dashboard_section.dart';
import 'post_signin/feature_sections/dataset_benchmark_tab.dart';
import 'post_signin/feature_sections/gap_detection_tab.dart';
import 'post_signin/feature_sections/planner_section.dart';
import 'post_signin/feature_sections/problem_generator_tab.dart';
import 'post_signin/feature_sections/settings_tab.dart';

class MigrationStepOnePage extends StatefulWidget {
  const MigrationStepOnePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<MigrationStepOnePage> createState() => _MigrationStepOnePageState();
}

class _MigrationStepOnePageState extends State<MigrationStepOnePage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _productionBaseUrl = 'https://paperlens-ai.onrender.com';
  static const _chatThreadsCacheKey = 'paperlens.chat_threads_by_doc.v1';

  final _topicController = TextEditingController();
  final _questionController = TextEditingController();

  String _difficulty = 'intermediate';
  String _jwtToken = '';
  late final TabController _tabController;
  int _activeSectionIndex = 0;
  Timer? _tokenAutoRefreshTimer;
  DateTime? _lastTokenSyncAt;

  bool _syncingToken = false;
  bool _loadingDashboard = false;
  bool _loadingAnalyze = false;
  bool _loadingAsk = false;
  bool _loadingPlanner = false;

  Map<String, dynamic>? _dashboard;
  String _analysisText = '';
  String _docId = '';
  List<Map<String, String>> _chatMessages = const [];
  final Map<String, List<Map<String, String>>> _chatThreadsByDoc = {};
  List<dynamic> _planSteps = const [];

  List<Map<String, String>> _threadForDoc(String docId) {
    return List<Map<String, String>>.from(_chatThreadsByDoc[docId] ?? const []);
  }

  void _persistThreadForDoc(String docId, List<Map<String, String>> thread) {
    if (docId.isEmpty) return;
    _chatThreadsByDoc[docId] = List<Map<String, String>>.from(thread);
    unawaited(_saveThreadCache());
  }

  Future<void> _loadThreadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_chatThreadsCacheKey);
      if (raw == null || raw.trim().isEmpty) {
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return;
      }

      final next = <String, List<Map<String, String>>>{};
      for (final entry in decoded.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (key.isEmpty || value is! List) {
          continue;
        }

        final messages = <Map<String, String>>[];
        for (final row in value) {
          if (row is! Map) continue;
          final role = (row['role'] ?? '').toString().trim();
          final content = (row['content'] ?? '').toString();
          if (role.isEmpty || content.isEmpty) continue;
          messages.add({'role': role, 'content': content});
        }
        if (messages.isNotEmpty) {
          next[key] = messages;
        }
      }

      if (!mounted) return;
      setState(() {
        _chatThreadsByDoc
          ..clear()
          ..addAll(next);
        if (_docId.isNotEmpty) {
          _chatMessages = _threadForDoc(_docId);
        }
      });
    } catch (_) {
      // Ignore malformed cache; app can continue with fresh in-memory state.
    }
  }

  Future<void> _saveThreadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _chatThreadsCacheKey,
        jsonEncode(_chatThreadsByDoc),
      );
    } catch (_) {
      // Persist failure is non-fatal; in-memory thread still works.
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 8, vsync: this)
      ..addListener(() {
        if (_tabController.indexIsChanging) return;
        if (!mounted) return;
        if (_activeSectionIndex != _tabController.index) {
          setState(() {
            _activeSectionIndex = _tabController.index;
          });
        }
        _syncClerkToken();
      });

    _tokenAutoRefreshTimer = Timer.periodic(
      const Duration(minutes: 2),
      (_) => _syncClerkToken(),
    );

    unawaited(_loadThreadCache());

    // Load dashboard once so the section does not feel empty on first open.
    _loadDashboard();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncClerkToken();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncClerkToken();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tokenAutoRefreshTimer?.cancel();
    _topicController.dispose();
    _questionController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncClerkToken();
    }
  }

  ApiService _api() {
    return ApiService(baseUrl: _productionBaseUrl, jwtToken: _jwtToken);
  }

  String _currentJwtToken() => _jwtToken;

  Future<void> _ensureTokenForTabs({bool force = false}) {
    return _syncClerkTokenIfStale(
      maxAge: force ? Duration.zero : const Duration(seconds: 45),
      force: force,
    );
  }

  Future<void> _syncClerkToken() async {
    if (_syncingToken || !mounted) {
      return;
    }

    _syncingToken = true;
    try {
      final auth = ClerkAuth.of(context, listen: false);
      if (!auth.isSignedIn) {
        if (mounted && _jwtToken.isNotEmpty) {
          setState(() {
            _jwtToken = '';
          });
        }
        return;
      }

      final sessionToken = await auth.sessionToken();
      final jwt = sessionToken.jwt.trim();
      if (!mounted) return;
      if (jwt.isNotEmpty && jwt != _jwtToken) {
        setState(() {
          _jwtToken = jwt;
        });
      }
      _lastTokenSyncAt = DateTime.now();
    } catch (_) {
      // A stale session can fail token fetch; UI will ask user to sign in again.
    } finally {
      _syncingToken = false;
    }
  }

  Future<void> _syncClerkTokenIfStale({
    required Duration maxAge,
    bool force = false,
  }) async {
    if (force ||
        _lastTokenSyncAt == null ||
        DateTime.now().difference(_lastTokenSyncAt!) > maxAge) {
      await _syncClerkToken();
    }
  }

  Future<T?> _withValidToken<T>(Future<T> Function() work) async {
    await _syncClerkTokenIfStale(maxAge: const Duration(seconds: 45));
    if (_jwtToken.isEmpty) {
      _showError('Session token not ready. Please wait or sign in again.');
      return null;
    }

    try {
      return await work();
    } on ApiException catch (e) {
      if (e.statusCode != 401) rethrow;
      await _syncClerkTokenIfStale(maxAge: Duration.zero, force: true);
      if (_jwtToken.isEmpty) {
        _showError('Session expired. Please sign in again.');
        return null;
      }
      return work();
    }
  }

  Future<void> _loadDashboard() async {
    setState(() => _loadingDashboard = true);
    try {
      final data = await _withValidToken(() => _api().getDashboard());
      if (data == null) return;
      setState(() {
        _dashboard = data;
      });
    } catch (e) {
      _showError(_friendlyError(e, action: 'Dashboard load'));
    } finally {
      if (mounted) {
        setState(() => _loadingDashboard = false);
      }
    }
  }

  Future<void> _analyzePaper() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'docx'],
      withData: false,
    );
    if (result == null || result.files.single.path == null) {
      return;
    }

    final file = File(result.files.single.path!);
    setState(() {
      _loadingAnalyze = true;
      _analysisText = '';
      _docId = '';
      _chatMessages = const [];
    });

    try {
      final data = await _withValidToken(() => _api().analyzePaper(file));
      if (data == null) return;
      final nextDocId = (data['doc_id'] ?? '').toString();
      final restoredThread = _threadForDoc(nextDocId);
      setState(() {
        _analysisText = (data['result'] ?? '').toString();
        _docId = nextDocId;
        _chatMessages = restoredThread;
      });
    } catch (e) {
      _showError(_friendlyError(e, action: 'Analysis'));
    } finally {
      if (mounted) {
        setState(() => _loadingAnalyze = false);
      }
    }
  }

  Future<void> _askQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _docId.isEmpty) {
      _showError('Analyze a paper first, then ask a question.');
      return;
    }

    final historyForBackend = _threadForDoc(_docId);
    final pendingThread = [
      ...historyForBackend,
      {'role': 'user', 'content': question},
    ];

    setState(() {
      _loadingAsk = true;
      _chatMessages = pendingThread;
    });
    _persistThreadForDoc(_docId, pendingThread);
    _questionController.clear();

    try {
      final data = await _withValidToken(
        () => _api().askQuestion(
          question: question,
          docId: _docId,
          history: historyForBackend,
        ),
      );
      if (data == null) return;
      final answer = (data['answer'] ?? '').toString();
      final completedThread = [
        ...pendingThread,
        {'role': 'assistant', 'content': answer},
      ];
      _persistThreadForDoc(_docId, completedThread);
      setState(() {
        _chatMessages = completedThread;
      });
    } catch (e) {
      final failedThread = [
        ...pendingThread,
        {
          'role': 'assistant',
          'content':
              'I ran into a temporary issue while answering. Please try again in a moment.',
        },
      ];
      _persistThreadForDoc(_docId, failedThread);
      setState(() {
        _chatMessages = failedThread;
      });
      _showError(_friendlyError(e, action: 'Question answer'));
    } finally {
      if (mounted) {
        setState(() => _loadingAsk = false);
      }
    }
  }

  Future<void> _planExperiment() async {
    if (_topicController.text.trim().isEmpty) {
      _showError('Enter a topic first.');
      return;
    }

    setState(() => _loadingPlanner = true);
    try {
      final data = await _withValidToken(
        () => _api().planExperiment(
          topic: _topicController.text.trim(),
          difficulty: _difficulty,
        ),
      );
      if (data == null) return;
      setState(() {
        _planSteps = (data['steps'] as List<dynamic>? ?? const []);
      });
    } catch (e) {
      _showError(_friendlyError(e, action: 'Plan generation'));
    } finally {
      if (mounted) {
        setState(() => _loadingPlanner = false);
      }
    }
  }

  String _friendlyError(Object error, {required String action}) {
    if (error is ApiException) {
      final raw = error.message.trim();
      final lower = raw.toLowerCase();

      final docxRelationshipIssue =
          lower.contains('officedocument/2006/relationships/officedocument') ||
          (lower.contains('relationship') && lower.contains('officedocument'));
      if (docxRelationshipIssue) {
        return 'This DOCX file could not be parsed. Please re-save it as a standard .docx in Microsoft Word, or upload a PDF instead.';
      }

      if (error.statusCode == 401) {
        return 'Your session expired. Please sign in again.';
      }

      if (error.statusCode == 413) {
        return 'The file is too large. Please upload a smaller file.';
      }

      if (error.statusCode == 415) {
        return 'Unsupported file type. Please upload a PDF or DOCX file.';
      }

      if (error.statusCode >= 500) {
        return '$action failed due to a server issue. Please try again.';
      }

      return '$action failed. $raw';
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your network and try again.';
    }

    if (error is TimeoutException) {
      return '$action timed out. Please try again.';
    }

    return '$action failed. Please try again.';
  }

  Future<void> _savePlan() async {
    if (_planSteps.isEmpty) {
      throw Exception('Generate a plan first.');
    }

    final topic = _topicController.text.trim();
    final summary = 'Difficulty: $_difficulty • ${_planSteps.length} steps';

    final data = await _withValidToken(
      () => _api().createSavedItem(
        section: 'experiment_planner',
        title: topic.isEmpty ? 'Experiment Plan' : topic,
        summary: summary,
        payload: {
          'topic': topic,
          'difficulty': _difficulty,
          'steps': _planSteps,
        },
      ),
    );

    if (data == null) {
      throw Exception('Could not save your plan right now. Please retry.');
    }
  }

  Future<void> _signOut() async {
    final auth = ClerkAuth.of(context, listen: false);
    await auth.signOut();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PostSigninHeader(
              sectionIndex: _activeSectionIndex,
              onRefreshToken: _syncClerkToken,
            ),
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
                Tab(icon: Icon(Icons.description_rounded), text: 'Analyzer'),
                Tab(icon: Icon(Icons.science_rounded), text: 'Planner'),
                Tab(icon: Icon(Icons.lightbulb_rounded), text: 'Ideas'),
                Tab(icon: Icon(Icons.search_rounded), text: 'Gaps'),
                Tab(icon: Icon(Icons.dataset_rounded), text: 'Datasets'),
                Tab(icon: Icon(Icons.auto_graph_rounded), text: 'Citations'),
                Tab(icon: Icon(Icons.settings_rounded), text: 'Settings'),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _scrollWrap(
                    PostSigninDashboardSection(
                      dashboard: _dashboard,
                      loadingDashboard: _loadingDashboard,
                      onLoadDashboard: _loadDashboard,
                    ),
                  ),
                  _scrollWrap(
                    PostSigninAnalyzerSection(
                      loadingAnalyze: _loadingAnalyze,
                      onAnalyzePaper: _analyzePaper,
                      docId: _docId,
                      analysisText: _analysisText,
                      questionController: _questionController,
                      loadingAsk: _loadingAsk,
                      onAskQuestion: _askQuestion,
                      chatMessages: _chatMessages,
                    ),
                  ),
                  _scrollWrap(
                    PostSigninPlannerSection(
                      topicController: _topicController,
                      difficulty: _difficulty,
                      onDifficultyChanged: (value) {
                        setState(() => _difficulty = value);
                      },
                      loadingPlanner: _loadingPlanner,
                      onPlanExperiment: _planExperiment,
                      onSavePlan: _savePlan,
                      planSteps: _planSteps,
                    ),
                  ),
                  ProblemGeneratorTab(
                    baseUrl: _productionBaseUrl,
                    jwtToken: _jwtToken,
                    getJwtToken: _currentJwtToken,
                    ensureToken: _ensureTokenForTabs,
                  ),
                  GapDetectionTab(
                    baseUrl: _productionBaseUrl,
                    jwtToken: _jwtToken,
                    getJwtToken: _currentJwtToken,
                    ensureToken: _ensureTokenForTabs,
                  ),
                  DatasetBenchmarkTab(
                    baseUrl: _productionBaseUrl,
                    jwtToken: _jwtToken,
                    getJwtToken: _currentJwtToken,
                    ensureToken: _ensureTokenForTabs,
                  ),
                  CitationIntelligenceTab(
                    baseUrl: _productionBaseUrl,
                    jwtToken: _jwtToken,
                    getJwtToken: _currentJwtToken,
                    ensureToken: _ensureTokenForTabs,
                  ),
                  SettingsTab(
                    baseUrl: _productionBaseUrl,
                    jwtToken: _jwtToken,
                    getJwtToken: _currentJwtToken,
                    ensureToken: _ensureTokenForTabs,
                    isDarkMode: widget.isDarkMode,
                    onThemeChanged: widget.onThemeChanged,
                    onSignOut: _signOut,
                    onSyncToken: _syncClerkToken,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scrollWrap(Widget child) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: [child],
    );
  }
}
