import 'package:flutter_test/flutter_test.dart';
import 'package:gwen/features/gwyn_agent/data/gwyn_relevant_context_builder.dart';
import 'package:gwen/features/gwyn_agent/domain/gwyn_memory.dart';

void main() {
  final now = DateTime.utc(2026, 8, 14, 12);
  late GwynRelevantContextBuilder builder;

  setUp(() {
    builder = GwynRelevantContextBuilder(now: () => now);
  });

  test('includes only categories requested by the main agent', () {
    final context = builder.build(
      userMessage: 'I am worried about my manager meeting again',
      memories: [
        _memory(
          id: 'trigger',
          type: GwynMemoryType.trigger,
          text: 'Meetings with my manager',
          importance: 0.8,
          now: now,
        ),
        _memory(
          id: 'plan',
          type: GwynMemoryType.planStep,
          text: 'Write down one balanced thought',
          importance: 0.9,
          now: now,
        ),
      ],
      requestedCategories: const [GwynContextCategory.knownTriggers],
    );

    expect(context.localMemoryIds, ['trigger']);
    expect(context.toRequestJson().keys, ['known_triggers']);
    expect(context.toRequestJson().toString(), isNot(contains('plan')));
  });

  test(
    'ranks lexical relevance before unrelated high-importance knowledge',
    () {
      final context = builder.build(
        userMessage: 'My presentation at work is worrying me',
        memories: [
          _memory(
            id: 'presentation',
            type: GwynMemoryType.trigger,
            text: 'Work presentations',
            importance: 0.5,
            now: now.subtract(const Duration(days: 20)),
          ),
          _memory(
            id: 'travel',
            type: GwynMemoryType.trigger,
            text: 'Long-distance travel',
            importance: 1,
            now: now,
          ),
        ],
        requestedCategories: const [GwynContextCategory.knownTriggers],
        maxItemsPerCategory: 1,
      );

      expect(context.localMemoryIds, ['presentation']);
    },
  );

  test('bounds context and never sends local identifiers', () {
    final memories = List.generate(
      5,
      (index) => _memory(
        id: 'private-$index',
        type: GwynMemoryType.pattern,
        text: 'Pattern number $index around work',
        importance: 1 - (index / 10),
        now: now,
      ),
    );

    final context = builder.build(
      userMessage: 'work pattern',
      memories: memories,
      requestedCategories: const [GwynContextCategory.recentInsights],
      maxItems: 2,
      maxItemsPerCategory: 2,
    );
    final requestJson = context.toRequestJson();

    expect(context.localMemoryIds, hasLength(2));
    expect(requestJson['recent_insights'], hasLength(2));
    expect(requestJson.toString(), isNot(contains('private-')));
  });

  test('returns no context when no categories were requested', () {
    final context = builder.build(
      userMessage: 'anything',
      memories: [
        _memory(
          id: 'trigger',
          type: GwynMemoryType.trigger,
          text: 'Anything',
          importance: 1,
          now: now,
        ),
      ],
      requestedCategories: const [],
    );

    expect(context.isEmpty, isTrue);
    expect(context.toRequestJson(), isEmpty);
  });
}

GwynMemory _memory({
  required String id,
  required GwynMemoryType type,
  required String text,
  required double importance,
  required DateTime now,
}) {
  return GwynMemory(
    id: id,
    type: type,
    text: text,
    sourcePhase: GwynMemoryPhase.understand,
    importance: importance,
    createdAt: now,
    updatedAt: now,
  );
}
