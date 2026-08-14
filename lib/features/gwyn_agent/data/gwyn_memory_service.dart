import 'dart:convert';

import '../domain/gwyn_memory.dart';
import 'gwyn_secure_store.dart';

class GwynMemoryService {
  GwynMemoryService({required GwynSecureStore store, DateTime Function()? now})
    : _store = store,
      _now = now ?? DateTime.now;

  factory GwynMemoryService.secure() {
    return GwynMemoryService(store: FlutterSecureGwynStore());
  }

  static const int schemaVersion = 1;
  static const int maxMemories = 200;
  static const int maxTextLength = 1000;

  final GwynSecureStore _store;
  final DateTime Function() _now;
  int _idSequence = 0;

  Future<List<GwynMemory>> getAll() async {
    final encoded = await _store.read();
    if (encoded == null || encoded.trim().isEmpty) return const [];

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Memory payload must be an object.');
      }
      if (decoded['schemaVersion'] != schemaVersion) {
        throw FormatException(
          'Unsupported Gwyn memory schema: ${decoded['schemaVersion']}',
        );
      }
      final rawMemories = decoded['memories'];
      if (rawMemories is! List<dynamic>) {
        throw const FormatException('Memory list is missing.');
      }
      return rawMemories
          .map(
            (item) => GwynMemory.fromJson(
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      throw GwynMemoryStorageException(
        'Stored Gwyn knowledge could not be read.',
        cause: error,
      );
    }
  }

  Future<GwynMemory> saveApprovedCandidate(
    GwynMemoryCandidate candidate,
  ) async {
    final type = candidate.type;
    final phase = candidate.sourcePhase;
    final text = candidate.text?.trim();
    final importance = candidate.importance;

    if (!candidate.shouldSave ||
        type == null ||
        phase == null ||
        text == null ||
        text.isEmpty ||
        importance == null) {
      throw const GwynMemoryValidationException(
        'The proposed Gwyn knowledge is incomplete.',
      );
    }
    if (text.length > maxTextLength) {
      throw const GwynMemoryValidationException(
        'The proposed Gwyn knowledge is too long.',
      );
    }
    if (importance < 0 || importance > 1) {
      throw const GwynMemoryValidationException(
        'The proposed Gwyn knowledge has invalid importance.',
      );
    }

    final memories = (await getAll()).toList();
    final normalizedText = _normalize(text);
    final existingIndex = memories.indexWhere(
      (memory) =>
          memory.type == type && _normalize(memory.text) == normalizedText,
    );
    final timestamp = _now().toUtc();
    late final GwynMemory saved;

    if (existingIndex >= 0) {
      final existing = memories[existingIndex];
      saved = existing.copyWith(
        text: text,
        sourcePhase: phase,
        importance: importance > existing.importance
            ? importance
            : existing.importance,
        updatedAt: timestamp,
      );
      memories[existingIndex] = saved;
    } else {
      if (memories.length >= maxMemories) {
        throw const GwynMemoryValidationException(
          'The on-device Gwyn knowledge limit has been reached.',
        );
      }
      saved = GwynMemory(
        id: 'gwyn_${timestamp.microsecondsSinceEpoch}_${_idSequence++}',
        type: type,
        text: text,
        sourcePhase: phase,
        importance: importance,
        createdAt: timestamp,
        updatedAt: timestamp,
      );
      memories.add(saved);
    }

    await _writeAll(memories);
    return saved;
  }

  Future<void> markUsed(Iterable<String> memoryIds) async {
    final ids = memoryIds.toSet();
    if (ids.isEmpty) return;

    final timestamp = _now().toUtc();
    final memories = await getAll();
    var changed = false;
    final updated = memories
        .map((memory) {
          if (!ids.contains(memory.id)) return memory;
          changed = true;
          return memory.copyWith(
            lastUsedAt: timestamp,
            useCount: memory.useCount + 1,
          );
        })
        .toList(growable: false);

    if (changed) await _writeAll(updated);
  }

  Future<void> delete(String memoryId) async {
    final memories = await getAll();
    final retained = memories
        .where((memory) => memory.id != memoryId)
        .toList(growable: false);
    if (retained.length == memories.length) return;
    await _writeAll(retained);
  }

  Future<void> clearAll() => _store.delete();

  Future<void> _writeAll(List<GwynMemory> memories) {
    final payload = jsonEncode({
      'schemaVersion': schemaVersion,
      'memories': memories.map((memory) => memory.toJson()).toList(),
    });
    return _store.write(payload);
  }

  String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class GwynMemoryStorageException implements Exception {
  const GwynMemoryStorageException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class GwynMemoryValidationException implements Exception {
  const GwynMemoryValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
