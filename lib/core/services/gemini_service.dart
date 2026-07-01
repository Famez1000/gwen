import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GeminiService {
  GeminiService._();

  static final GeminiService instance = GeminiService._();

  static const String _model = 'gemini-2.5-flash';
  static const String _apiKeyFromEnvironment = String.fromEnvironment(
    'GEMINI_API_KEY',
  );
  static const bool _debugGemini = bool.fromEnvironment(
    'DEBUG_GEMINI',
    defaultValue: true,
  );
  static const String _secureStorageApiKeyName = 'gemini_api_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  String? _cachedApiKey;

  Future<void> initializeApiKey() async {
    await _loadApiKey();
  }

  Future<String> generateGwenResponse(String userMessage) async {
    return _generateContent({
      'system_instruction': {
        'parts': [
          {
            'text':
                'You are Gwen, a warm anxiety-support companion in a Flutter app. '
                'Answer with kindness, practical grounding suggestions, and light encouragement. '
                'Do not claim to diagnose or replace professional care. '
                'If the user sounds in immediate danger, encourage them to contact local emergency help or a trusted person now. '
                'Keep replies concise: 2 short paragraphs maximum.',
          },
        ],
      },
      'contents': [
        {
          'parts': [
            {'text': userMessage},
          ],
        },
      ],
      'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.8},
    });
  }

  Future<String> generateContextualGwenResponse({
    required String userMessage,
    required String pageTitle,
    required String pageContext,
  }) async {
    return _generateContent({
      'system_instruction': {
        'parts': [
          {
            'text':
                'You are Gwen, a warm anxiety-support companion in a Flutter app. '
                'The user opened Gwen from the "$pageTitle" page, so tailor the answer to that page context. '
                'Page context: $pageContext '
                'Answer with kindness, practical grounding suggestions, and light encouragement. '
                'Do not claim to diagnose or replace professional care. '
                'If the user sounds in immediate danger, encourage them to contact local emergency help or a trusted person now. '
                'Keep replies concise: 2 short paragraphs maximum.',
          },
        ],
      },
      'contents': [
        {
          'parts': [
            {'text': userMessage},
          ],
        },
      ],
      'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.8},
    });
  }

  Future<String> summarizeJournalEntries(String journalEntries) async {
    return _generateContent({
      'system_instruction': {
        'parts': [
          {
            'text':
                'You are Gwen, a warm anxiety-support companion in a Flutter app. '
                'Summarize the user journal entries with care and emotional sensitivity. '
                'Do not diagnose, do not overstate patterns, and do not replace professional care. '
                'Focus on recurring feelings, possible triggers, coping strengths, and one gentle next step. '
                'Use the user-provided journal text only. '
                'Keep the response concise: 4 short bullet points maximum.',
          },
        ],
      },
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Please summarize these journal entries as Gwen:\n\n$journalEntries',
            },
          ],
        },
      ],
      'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.5},
    });
  }

  Future<String> respondToJournalSummaryQuestion({
    required String journalEntries,
    required String summary,
    required String question,
  }) async {
    return _generateContent({
      'system_instruction': {
        'parts': [
          {
            'text':
                'You are Gwen, a warm anxiety-support companion in a Flutter app. '
                'Answer follow-up questions about the user journal summary with care and emotional sensitivity. '
                'Use only the supplied journal entries and summary as context. '
                'Do not diagnose, do not overstate patterns, and do not replace professional care. '
                'If the user sounds in immediate danger, encourage them to contact local emergency help or a trusted person now. '
                'Keep replies concise: 2 short paragraphs maximum.',
          },
        ],
      },
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Journal entries:\n$journalEntries\n\nGwen summary:\n$summary\n\nUser question:\n$question',
            },
          ],
        },
      ],
      'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.7},
    });
  }

  Future<String> guessDrawing(Uint8List pngBytes) async {
    return _generateContent({
      'system_instruction': {
        'parts': [
          {
            'text':
                'You are Gwen, a playful anxiety-support companion. '
                'The user drew a picture for a light stress-relief game. '
                'Guess what the drawing is with warmth and humor. '
                'If it is unclear, make one cheerful best guess. '
                'Reply with exactly one complete sentence under 20 words. '
                'End the sentence with punctuation.',
          },
        ],
      },
      'contents': [
        {
          'parts': [
            {
              'text':
                  'What do you think this drawing is? Reply as Gwen with one complete playful sentence.',
            },
            {
              'inline_data': {
                'mime_type': 'image/png',
                'data': base64Encode(pngBytes),
              },
            },
          ],
        },
      ],
      'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.8},
    });
  }

  Future<String> respondToDrawingGuess({
    required String guess,
    required String userReply,
  }) async {
    return _generateContent({
      'system_instruction': {
        'parts': [
          {
            'text':
                'You are Gwen, a playful anxiety-support companion in a drawing guessing game. '
                'React to the user in a warm, funny way. '
                'If they correct your guess, happily accept the correction. '
                'If they say you were right, celebrate briefly. '
                'Keep the reply to 1 or 2 short sentences.',
          },
        ],
      },
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Gwen guessed: "$guess"\nThe user replied: "$userReply"\nRespond as Gwen.',
            },
          ],
        },
      ],
      'generationConfig': {'maxOutputTokens': 1024, 'temperature': 0.8},
    });
  }

  Future<String> generateRelaxingJoke({
    List<String> recentJokes = const [],
  }) async {
    const topics = [
      'tea',
      'clouds',
      'plants',
      'blankets',
      'socks',
      'stars',
      'books',
      'rain',
      'pillows',
      'sunlight',
    ];
    final topic = topics[DateTime.now().millisecondsSinceEpoch % topics.length];
    final recentJokesText = recentJokes.isEmpty
        ? 'No previous jokes yet.'
        : recentJokes.map((joke) => '- $joke').join('\n');

    return _generateContent({
      'system_instruction': {
        'parts': [
          {
            'text':
                'You are Gwen, a warm anxiety-support companion in a Flutter app. '
                'Tell exactly one gentle, relaxing joke that is light, kind, and suitable for someone feeling anxious. '
                'Avoid dark humor, insults, medical jokes, emergency themes, and anything mean. '
                'Do not repeat or closely paraphrase any recent jokes provided by the user. '
                'Keep it short: 1 or 2 sentences maximum.',
          },
        ],
      },
      'contents': [
        {
          'parts': [
            {
              'text':
                  'Please tell me one calming joke to help someone soften a tense moment. '
                  'Use this loose theme to keep it fresh: $topic.\n\n'
                  'Recent jokes to avoid:\n$recentJokesText',
            },
          ],
        },
      ],
      'generationConfig': {
        'maxOutputTokens': 512,
        'temperature': 0.9,
        'thinkingConfig': {'thinkingBudget': 0},
      },
    });
  }

  Future<String> _generateContent(Map<String, dynamic> body) async {
    final apiKey = await _loadApiKey();
    if (apiKey.isEmpty) {
      throw const GeminiServiceException('Gemini API key is missing.');
    }

    final uri = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/$_model:generateContent',
    );

    final requestBody = jsonEncode(body);

    final client = HttpClient();
    try {
      _debugLog('POST $uri');
      _debugLog('Request body chars: ${requestBody.length}');

      final request = await client
          .postUrl(uri)
          .timeout(const Duration(seconds: 10));
      request.headers.contentType = ContentType.json;
      request.headers.set('x-goog-api-key', apiKey);
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
          'Gemini request failed with status ${response.statusCode}.',
        );
      }

      return _extractText(responseText);
    } finally {
      client.close(force: true);
    }
  }

  String _extractText(String responseText) {
    final decoded = jsonDecode(responseText) as Map<String, dynamic>;
    final candidates = decoded['candidates'] as List<dynamic>?;
    _debugLog('Candidate count: ${candidates?.length ?? 0}');

    Map<String, dynamic>? firstCandidate;
    if (candidates != null &&
        candidates.isNotEmpty &&
        candidates.first is Map<String, dynamic>) {
      firstCandidate = candidates.first as Map<String, dynamic>;
    }
    _debugLog('Finish reason: ${firstCandidate?['finishReason']}');
    _debugLog('Safety ratings: ${firstCandidate?['safetyRatings']}');

    Map<String, dynamic>? content;
    final rawContent = firstCandidate == null
        ? null
        : firstCandidate['content'];
    if (rawContent is Map<String, dynamic>) {
      content = rawContent;
    }

    List<dynamic>? parts;
    final rawParts = content == null ? null : content['parts'];
    if (rawParts is List<dynamic>) {
      parts = rawParts;
    }
    _debugLog('Text part count: ${parts?.length ?? 0}');

    final text = parts
        ?.map((part) => part is Map<String, dynamic> ? part['text'] : null)
        .whereType<String>()
        .join('\n')
        .trim();
    final parsedTextLineCount = text == null ? 0 : text.split('\n').length;
    _debugLog('Parsed text chars: ${text?.length ?? 0}');
    _debugLog('Parsed text lines: $parsedTextLineCount');
    _debugLog('Parsed text preview: ${_preview(text ?? '', 700)}');

    if (text == null || text.trim().isEmpty) {
      throw const GeminiServiceException('Gemini returned an empty response.');
    }

    return text.trim();
  }

  Future<String> _loadApiKey() async {
    if (_cachedApiKey != null) return _cachedApiKey!;

    final storedApiKey = await _secureStorage.read(
      key: _secureStorageApiKeyName,
    );
    if (storedApiKey != null && storedApiKey.trim().isNotEmpty) {
      _cachedApiKey = storedApiKey.trim();
      return _cachedApiKey!;
    }

    if (_apiKeyFromEnvironment.trim().isNotEmpty) {
      _cachedApiKey = _apiKeyFromEnvironment.trim();
      await _secureStorage.write(
        key: _secureStorageApiKeyName,
        value: _cachedApiKey,
      );
      return _cachedApiKey!;
    }

    return '';
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
