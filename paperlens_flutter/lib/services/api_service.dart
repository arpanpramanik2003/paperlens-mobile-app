import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ApiService {
  ApiService({
    required this.baseUrl,
    required this.jwtToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final String jwtToken;
  final http.Client _client;

  String _normalizedJwtToken() {
    var token = jwtToken.trim();
    if (token.toLowerCase().startsWith('bearer ')) {
      token = token.substring(7);
    }
    while (token.length >= 2 &&
        ((token.startsWith('"') && token.endsWith('"')) ||
            (token.startsWith("'") && token.endsWith("'")))) {
      token = token.substring(1, token.length - 1).trim();
    }
    token = token.replaceAll(RegExp(r'\s+'), '');
    return token;
  }

  bool _looksLikeJwt(String token) {
    final parts = token.split('.');
    return parts.length == 3 && parts.every((part) => part.isNotEmpty);
  }

  String _authHeaderValue() {
    final token = _normalizedJwtToken();
    if (token.isEmpty) {
      throw ApiException(
        message:
            'Missing Clerk JWT token. Paste a valid Clerk session token in Setup.',
        statusCode: 401,
      );
    }
    if (!_looksLikeJwt(token)) {
      throw ApiException(
        message:
            'Invalid Clerk JWT format. Paste only the raw token (without "Bearer ").',
        statusCode: 401,
      );
    }
    return 'Bearer $token';
  }

  Map<String, String> _jsonHeaders({bool withAuth = true}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (withAuth) {
      headers['Authorization'] = _authHeaderValue();
    }
    return headers;
  }

  Uri _uri(String path) {
    final cleanedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$cleanedPath');
  }

  Future<Map<String, dynamic>> getHealth() async {
    final response = await _client.get(_uri('/health'));
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _client.get(
      _uri('/api/dashboard'),
      headers: _jsonHeaders(),
    );
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> analyzePaper(File file) async {
    final request = http.MultipartRequest('POST', _uri('/api/analyze'));
    request.headers['Authorization'] = _authHeaderValue();
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> askQuestion({
    required String question,
    required String docId,
    required List<Map<String, String>> history,
  }) async {
    final response = await _client.post(
      _uri('/api/ask'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'question': question,
        'doc_id': docId,
        'history': history,
      }),
    );
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> planExperiment({
    required String topic,
    required String difficulty,
  }) async {
    final response = await _client.post(
      _uri('/api/plan-experiment'),
      headers: _jsonHeaders(),
      body: jsonEncode({'topic': topic, 'difficulty': difficulty}),
    );
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> generateProblems({
    required String domain,
    required String subdomain,
    required String complexity,
  }) async {
    final response = await _client.post(
      _uri('/api/generate-problems'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'domain': domain,
        'subdomain': subdomain,
        'complexity': complexity,
      }),
    );
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> expandProblem({
    required String domain,
    required String subdomain,
    required String complexity,
    required Map<String, dynamic> idea,
  }) async {
    final response = await _client.post(
      _uri('/api/expand-problem'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'domain': domain,
        'subdomain': subdomain,
        'complexity': complexity,
        'idea': idea,
      }),
    );
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> detectGapsFromText({
    required String text,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/detect-gaps'));
    request.headers['Authorization'] = _authHeaderValue();
    request.fields['text'] = text;

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> detectGapsFromFile(File file) async {
    final request = http.MultipartRequest('POST', _uri('/api/detect-gaps'));
    request.headers['Authorization'] = _authHeaderValue();
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> findDatasetsBenchmarks({
    required String projectTitle,
    required String projectPlan,
  }) async {
    final response = await _client.post(
      _uri('/api/find-datasets-benchmarks'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'project_title': projectTitle,
        'project_plan': projectPlan,
      }),
    );
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> runCitationIntelligence(File file) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/citation-intelligence'),
    );
    request.headers['Authorization'] = _authHeaderValue();
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decodeOrThrow(response);
  }

  Stream<Map<String, dynamic>> streamCitationIntelligence(File file) async* {
    final request = http.MultipartRequest(
      'POST',
      _uri('/api/citation-intelligence/stream'),
    );
    request.headers['Authorization'] = _authHeaderValue();
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamed = await request.send();
    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      final bodyText = await streamed.stream.bytesToString();
      dynamic decoded;
      try {
        decoded = bodyText.isEmpty ? <String, dynamic>{} : jsonDecode(bodyText);
      } catch (_) {
        decoded = <String, dynamic>{'error': bodyText};
      }

      final message = decoded is Map<String, dynamic>
          ? (decoded['error']?.toString() ??
                decoded['detail']?.toString() ??
                'Request failed')
          : 'Request failed';

      throw ApiException(message: message, statusCode: streamed.statusCode);
    }

    await for (final line
        in streamed.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('data:')) {
        continue;
      }

      final raw = trimmed.substring(5).trim();
      if (raw.isEmpty) {
        continue;
      }

      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          yield decoded;
        }
      } catch (_) {
        // Ignore malformed SSE lines and keep stream alive.
      }
    }
  }

  Future<Map<String, dynamic>> discoverCitations({
    required String projectTitle,
    required String basicDetails,
    int limit = 35,
    String? topicPreset,
  }) async {
    final response = await _client.post(
      _uri('/api/citation-intelligence/discover'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'project_title': projectTitle,
        'basic_details': basicDetails,
        'limit': limit,
        if (topicPreset != null && topicPreset.trim().isNotEmpty)
          'topic_preset': topicPreset.trim(),
      }),
    );
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> citationRecommendations({
    required String paperContext,
    required List<dynamic> topCited,
    required List<String> missingReferences,
    required String recommendationMode,
    String? projectTitle,
    String? basicDetails,
  }) async {
    final response = await _client.post(
      _uri('/api/citation-intelligence/recommendations'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'paper_context': paperContext,
        'top_cited': topCited,
        'missing_references': missingReferences,
        'recommendation_mode': recommendationMode,
        'project_title': projectTitle,
        'basic_details': basicDetails,
      }),
    );
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> getSavedItems({String? section}) async {
    final path = (section == null || section.trim().isEmpty)
        ? '/api/saved-items'
        : '/api/saved-items?section=${Uri.encodeQueryComponent(section.trim())}';
    final response = await _client.get(_uri(path), headers: _jsonHeaders());
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> createSavedItem({
    required String section,
    required String title,
    String? summary,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _client.post(
      _uri('/api/saved-items'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'section': section,
        'title': title,
        'summary': summary,
        'payload': payload,
      }),
    );
    return _decodeOrThrow(response);
  }

  Future<Map<String, dynamic>> deleteSavedItem(int itemId) async {
    final response = await _client.delete(
      _uri('/api/saved-items/$itemId'),
      headers: _jsonHeaders(),
    );
    return _decodeOrThrow(response);
  }

  Map<String, dynamic> _decodeOrThrow(http.Response response) {
    final bodyText = utf8.decode(response.bodyBytes);
    final dynamic decoded = bodyText.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(bodyText);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    }

    final message = decoded is Map<String, dynamic>
        ? (decoded['error']?.toString() ??
              decoded['detail']?.toString() ??
              'Request failed')
        : 'Request failed';
    throw ApiException(message: message, statusCode: response.statusCode);
  }
}

class ApiException implements Exception {
  ApiException({required this.message, required this.statusCode});

  final String message;
  final int statusCode;

  @override
  String toString() =>
      'ApiException(statusCode: $statusCode, message: $message)';
}
