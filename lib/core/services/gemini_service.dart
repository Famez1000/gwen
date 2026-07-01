import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

class GeminiService {
  GeminiService._();

  static final GeminiService instance = GeminiService._();

  static const String _functionUrl = String.fromEnvironment(
    'GWEN_AI_FUNCTION_URL',
  );
  static const bool _debugGemini = bool.fromEnvironment(
    'DEBUG_GEMINI',
    defaultValue: true,
  );

  Future<void> initializeApiKey() async {}

  Future<String> generateGwenResponse(String userMessage) async {
    return _callGwenFunction('generateGwenResponse', {
      'userMessage': userMessage,
    });
  }

  Future<String> generateContextualGwenResponse({
    required String userMessage,
    required String pageTitle,
    required String pageContext,
  }) async {
    return _callGwenFunction('generateContextualGwenResponse', {
      'userMessage': userMessage,
      'pageTitle': pageTitle,
      'pageContext': pageContext,
    });
  }

  Future<String> summarizeJournalEntries(String journalEntries) async {
    return _callGwenFunction('summarizeJournalEntries', {
      'journalEntries': journalEntries,
    });
  }

  Future<String> respondToJournalSummaryQuestion({
    required String journalEntries,
    required String summary,
    required String question,
  }) async {
    return _callGwenFunction('respondToJournalSummaryQuestion', {
      'journalEntries': journalEntries,
      'summary': summary,
      'question': question,
    });
  }

  Future<String> guessDrawing(Uint8List pngBytes) async {
    return _callGwenFunction('guessDrawing', {
      'pngBase64': base64Encode(pngBytes),
    });
  }

  Future<String> respondToDrawingGuess({
    required String guess,
    required String userReply,
  }) async {
    return _callGwenFunction('respondToDrawingGuess', {
      'guess': guess,
      'userReply': userReply,
    });
  }

  Future<String> generateRelaxingJoke({
    List<String> recentJokes = const [],
  }) async {
    return _callGwenFunction('generateRelaxingJoke', {
      'recentJokes': recentJokes,
    });
  }

  Future<String> _callGwenFunction(
    String operation,
    Map<String, dynamic> payload,
  ) async {
    if (_functionUrl.trim().isEmpty) {
      throw const GeminiServiceException('Gwen AI function URL is missing.');
    }

    final uri = Uri.parse(_functionUrl.trim());

    final requestBody = jsonEncode({
      'operation': operation,
      'payload': payload,
    });

    final client = HttpClient();
    try {
      _debugLog('POST $uri');
      _debugLog('Operation: $operation');
      _debugLog('Request body chars: ${requestBody.length}');

      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 10));
      request.headers.contentType = ContentType.json;
      request.write(requestBody);

      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final responseText = await response.transform(utf8.decoder).join();
      _debugLog('HTTP status: ${response.statusCode}');
      _debugLog('Raw response chars: ${responseText.length}');
      _debugLog('Raw response preview: ${_preview(responseText, 700)}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw GeminiServiceException(
          'Gwen AI request failed with status ${response.statusCode}.',
        );
      }

      return _extractFunctionText(responseText);
    } finally {
      client.close(force: true);
    }
  }

  String _extractFunctionText(String responseText) {
    final decoded = jsonDecode(responseText) as Map<String, dynamic>;
    final text = decoded['text'] is String
        ? (decoded['text'] as String).trim()
        : null;
    final parsedTextLineCount = text == null ? 0 : text.split('\n').length;
    _debugLog('Parsed text chars: ${text?.length ?? 0}');
    _debugLog('Parsed text lines: $parsedTextLineCount');
    _debugLog('Parsed text preview: ${_preview(text ?? '', 700)}');

    if (text == null || text.trim().isEmpty) {
      throw const GeminiServiceException('Gemini returned an empty response.');
    }

    return text.trim();
  }

  void _debugLog(String message) {
    if (_debugGemini) {
      debugPrint('[GeminiService] $message');
    }
  }

  String _preview(String value, int maxChars) {
    final safeValue = value.replaceAll('\n', r'\n');
    if (safeValue.length <= maxChars) return safeValue;
    return '${safeValue.substring(0, maxChars)}...';
  }
}

class GeminiServiceException implements Exception {
  final String message;

  const GeminiServiceException(this.message);

  @override
  String toString() => message;
}
