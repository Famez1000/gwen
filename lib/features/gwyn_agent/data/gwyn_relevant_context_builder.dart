import '../domain/gwyn_memory.dart';

enum GwynContextCategory {
  knownTriggers('known_triggers'),
  recentInsights('recent_insights'),
  helpfulExercises('helpful_exercises'),
  currentPlanSteps('current_plan_steps'),
  recentExerciseResults('recent_exercise_results');

  const GwynContextCategory(this.wireName);

  final String wireName;

  static GwynContextCategory fromWireName(String value) {
    return values.firstWhere(
      (category) => category.wireName == value,
      orElse: () =>
          throw FormatException('Unknown Gwyn context category: $value'),
    );
  }
}

class GwynContextItem {
  const GwynContextItem({
    required this.localMemoryId,
    required this.type,
    required this.text,
  });

  final String localMemoryId;
  final GwynMemoryType type;
  final String text;

  Map<String, dynamic> toRequestJson() {
    return {'type': type.wireName, 'text': text};
  }
}

class GwynRelevantContext {
  const GwynRelevantContext(this.itemsByCategory);

  final Map<GwynContextCategory, List<GwynContextItem>> itemsByCategory;

  bool get isEmpty => itemsByCategory.values.every((items) => items.isEmpty);

  Iterable<String> get localMemoryIds sync* {
    for (final items in itemsByCategory.values) {
      for (final item in items) {
        yield item.localMemoryId;
      }
    }
  }

  Map<String, dynamic> toRequestJson() {
    return {
      for (final entry in itemsByCategory.entries)
        if (entry.value.isNotEmpty)
          entry.key.wireName: entry.value
              .map((item) => item.toRequestJson())
              .toList(growable: false),
    };
  }
}

class GwynRelevantContextBuilder {
  GwynRelevantContextBuilder({DateTime Function()? now})
    : _now = now ?? DateTime.now;

  static const int defaultMaxItems = 6;
  static const int defaultMaxItemsPerCategory = 2;

  final DateTime Function() _now;

  GwynRelevantContext build({
    required String userMessage,
    required List<GwynMemory> memories,
    required Iterable<GwynContextCategory> requestedCategories,
    int maxItems = defaultMaxItems,
    int maxItemsPerCategory = defaultMaxItemsPerCategory,
  }) {
    if (maxItems <= 0 || maxItemsPerCategory <= 0) {
      return const GwynRelevantContext({});
    }

    final requested = requestedCategories.toSet();
    if (requested.isEmpty || memories.isEmpty) {
      return const GwynRelevantContext({});
    }

    final messageTerms = _terms(userMessage);
    final now = _now().toUtc();
    final selected = <GwynContextCategory, List<_ScoredMemory>>{};

    for (final category in requested) {
      final matches =
          memories
              .where((memory) => _categoryFor(memory.type) == category)
              .map(
                (memory) => _ScoredMemory(
                  memory,
                  _score(memory, messageTerms: messageTerms, now: now),
                ),
              )
              .toList()
            ..sort(_compareScored);
      selected[category] = matches
          .take(maxItemsPerCategory)
          .toList(growable: false);
    }

    final flattened = selected.values.expand((items) => items).toList()
      ..sort(_compareScored);
    final retainedIds = flattened
        .take(maxItems)
        .map((item) => item.memory.id)
        .toSet();

    return GwynRelevantContext({
      for (final category in requested)
        category: (selected[category] ?? const [])
            .where((item) => retainedIds.contains(item.memory.id))
            .map(
              (item) => GwynContextItem(
                localMemoryId: item.memory.id,
                type: item.memory.type,
                text: item.memory.text,
              ),
            )
            .toList(growable: false),
    });
  }

  int _compareScored(_ScoredMemory a, _ScoredMemory b) {
    final scoreComparison = b.score.compareTo(a.score);
    if (scoreComparison != 0) return scoreComparison;
    final importanceComparison = b.memory.importance.compareTo(
      a.memory.importance,
    );
    if (importanceComparison != 0) return importanceComparison;
    return b.memory.updatedAt.compareTo(a.memory.updatedAt);
  }

  double _score(
    GwynMemory memory, {
    required Set<String> messageTerms,
    required DateTime now,
  }) {
    final overlap = _terms(memory.text).intersection(messageTerms).length;
    final age = now.difference(memory.updatedAt.toUtc());
    final recency = age.isNegative || age.inDays <= 7
        ? 0.75
        : age.inDays <= 30
        ? 0.5
        : age.inDays <= 180
        ? 0.25
        : 0.0;
    return (overlap * 2.0) + (memory.importance * 2.0) + recency;
  }

  Set<String> _terms(String value) {
    return value
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((term) => term.length >= 3 && !_stopWords.contains(term))
        .toSet();
  }

  GwynContextCategory _categoryFor(GwynMemoryType type) {
    return switch (type) {
      GwynMemoryType.trigger => GwynContextCategory.knownTriggers,
      GwynMemoryType.surfaceFear ||
      GwynMemoryType.underlyingFear ||
      GwynMemoryType.belief ||
      GwynMemoryType.pattern => GwynContextCategory.recentInsights,
      GwynMemoryType.helpfulExercise => GwynContextCategory.helpfulExercises,
      GwynMemoryType.exerciseResult =>
        GwynContextCategory.recentExerciseResults,
      GwynMemoryType.planStep => GwynContextCategory.currentPlanSteps,
    };
  }
}

class _ScoredMemory {
  const _ScoredMemory(this.memory, this.score);

  final GwynMemory memory;
  final double score;
}

const Set<String> _stopWords = {
  'and',
  'are',
  'but',
  'for',
  'from',
  'has',
  'have',
  'that',
  'the',
  'this',
  'was',
  'were',
  'with',
  'you',
  'your',
};
