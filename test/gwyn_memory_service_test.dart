import 'package:flutter_test/flutter_test.dart';
import 'package:gwen/features/gwyn_agent/data/gwyn_memory_service.dart';
import 'package:gwen/features/gwyn_agent/data/gwyn_secure_store.dart';
import 'package:gwen/features/gwyn_agent/domain/gwyn_memory.dart';

void main() {
  late _MemorySecureStore store;
  late DateTime now;
  late GwynMemoryService service;

  setUp(() {
    store = _MemorySecureStore();
    now = DateTime.utc(2026, 8, 14, 12);
    service = GwynMemoryService(store: store, now: () => now);
  });

  test(
    'saves approved knowledge and restores it from encrypted storage',
    () async {
      final saved = await service.saveApprovedCandidate(
        const GwynMemoryCandidate(
          shouldSave: true,
          type: GwynMemoryType.trigger,
          text: 'Meetings with my manager',
          sourcePhase: GwynMemoryPhase.understand,
          importance: 0.8,
        ),
      );

      final restored = await service.getAll();
      expect(restored, hasLength(1));
      expect(restored.single.id, saved.id);
      expect(restored.single.type, GwynMemoryType.trigger);
      expect(restored.single.text, 'Meetings with my manager');
      expect(store.value, contains('"schemaVersion":1'));
    },
  );

  test('does not save an unapproved or incomplete candidate', () async {
    expect(
      () => service.saveApprovedCandidate(
        const GwynMemoryCandidate(
          shouldSave: false,
          type: GwynMemoryType.belief,
          text: 'I must be perfect',
          sourcePhase: GwynMemoryPhase.understand,
          importance: 0.7,
        ),
      ),
      throwsA(isA<GwynMemoryValidationException>()),
    );
    expect(await service.getAll(), isEmpty);
  });

  test(
    'deduplicates matching knowledge and keeps the higher importance',
    () async {
      await service.saveApprovedCandidate(
        const GwynMemoryCandidate(
          shouldSave: true,
          type: GwynMemoryType.pattern,
          text: 'I check for reassurance',
          sourcePhase: GwynMemoryPhase.understand,
          importance: 0.4,
        ),
      );
      now = now.add(const Duration(days: 1));
      await service.saveApprovedCandidate(
        const GwynMemoryCandidate(
          shouldSave: true,
          type: GwynMemoryType.pattern,
          text: '  I check for reassurance  ',
          sourcePhase: GwynMemoryPhase.heal,
          importance: 0.9,
        ),
      );

      final memories = await service.getAll();
      expect(memories, hasLength(1));
      expect(memories.single.importance, 0.9);
      expect(memories.single.sourcePhase, GwynMemoryPhase.heal);
      expect(memories.single.updatedAt, now);
    },
  );

  test(
    'supports usage tracking, individual deletion, and clearing all',
    () async {
      final memory = await service.saveApprovedCandidate(
        const GwynMemoryCandidate(
          shouldSave: true,
          type: GwynMemoryType.helpfulExercise,
          text: 'Observe your thoughts helped',
          sourcePhase: GwynMemoryPhase.cope,
          importance: 0.7,
        ),
      );

      now = now.add(const Duration(hours: 1));
      await service.markUsed([memory.id]);
      var stored = await service.getAll();
      expect(stored.single.useCount, 1);
      expect(stored.single.lastUsedAt, now);

      await service.delete(memory.id);
      expect(await service.getAll(), isEmpty);

      await service.clearAll();
      expect(store.value, isNull);
    },
  );

  test(
    'surfaces corrupted storage instead of silently overwriting it',
    () async {
      store.value = '{not-json';

      expect(service.getAll, throwsA(isA<GwynMemoryStorageException>()));
    },
  );
}

class _MemorySecureStore implements GwynSecureStore {
  String? value;

  @override
  Future<void> delete() async {
    value = null;
  }

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String value) async {
    this.value = value;
  }
}
