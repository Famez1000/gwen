enum GwynMemoryType {
  trigger('trigger'),
  surfaceFear('surface_fear'),
  underlyingFear('underlying_fear'),
  belief('belief'),
  pattern('pattern'),
  helpfulExercise('helpful_exercise'),
  exerciseResult('exercise_result'),
  planStep('plan_step');

  const GwynMemoryType(this.wireName);

  final String wireName;

  static GwynMemoryType fromWireName(String value) {
    return values.firstWhere(
      (type) => type.wireName == value,
      orElse: () => throw FormatException('Unknown Gwyn memory type: $value'),
    );
  }
}

enum GwynMemoryPhase {
  cope('cope'),
  understand('understand'),
  heal('heal');

  const GwynMemoryPhase(this.wireName);

  final String wireName;

  static GwynMemoryPhase fromWireName(String value) {
    return values.firstWhere(
      (phase) => phase.wireName == value,
      orElse: () => throw FormatException('Unknown Gwyn memory phase: $value'),
    );
  }
}

class GwynMemoryCandidate {
  const GwynMemoryCandidate({
    required this.shouldSave,
    required this.type,
    required this.text,
    required this.sourcePhase,
    required this.importance,
  });

  final bool shouldSave;
  final GwynMemoryType? type;
  final String? text;
  final GwynMemoryPhase? sourcePhase;
  final double? importance;

  factory GwynMemoryCandidate.fromAgentJson(Map<String, dynamic> json) {
    final rawType = json['type'];
    final rawPhase = json['sourcePhase'];
    final rawImportance = json['importance'];

    return GwynMemoryCandidate(
      shouldSave: json['save'] == true,
      type: rawType is String ? GwynMemoryType.fromWireName(rawType) : null,
      text: json['text'] is String ? json['text'] as String : null,
      sourcePhase: rawPhase is String
          ? GwynMemoryPhase.fromWireName(rawPhase)
          : null,
      importance: rawImportance is num ? rawImportance.toDouble() : null,
    );
  }
}

class GwynMemory {
  const GwynMemory({
    required this.id,
    required this.type,
    required this.text,
    required this.sourcePhase,
    required this.importance,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
    this.useCount = 0,
  });

  final String id;
  final GwynMemoryType type;
  final String text;
  final GwynMemoryPhase sourcePhase;
  final double importance;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;
  final int useCount;

  GwynMemory copyWith({
    String? text,
    GwynMemoryPhase? sourcePhase,
    double? importance,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
    int? useCount,
  }) {
    return GwynMemory(
      id: id,
      type: type,
      text: text ?? this.text,
      sourcePhase: sourcePhase ?? this.sourcePhase,
      importance: importance ?? this.importance,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      useCount: useCount ?? this.useCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.wireName,
      'text': text,
      'sourcePhase': sourcePhase.wireName,
      'importance': importance,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      'lastUsedAt': lastUsedAt?.toUtc().toIso8601String(),
      'useCount': useCount,
    };
  }

  factory GwynMemory.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final type = json['type'];
    final text = json['text'];
    final sourcePhase = json['sourcePhase'];
    final importance = json['importance'];
    final createdAt = json['createdAt'];
    final updatedAt = json['updatedAt'];
    final lastUsedAt = json['lastUsedAt'];
    final useCount = json['useCount'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Gwyn memory id is invalid.');
    }
    if (type is! String || text is! String || text.trim().isEmpty) {
      throw const FormatException('Gwyn memory content is invalid.');
    }
    if (sourcePhase is! String || importance is! num) {
      throw const FormatException('Gwyn memory metadata is invalid.');
    }
    if (importance < 0 || importance > 1) {
      throw const FormatException('Gwyn memory importance is invalid.');
    }
    if (createdAt is! String || updatedAt is! String) {
      throw const FormatException('Gwyn memory timestamps are invalid.');
    }
    if (lastUsedAt != null && lastUsedAt is! String) {
      throw const FormatException('Gwyn memory usage timestamp is invalid.');
    }
    if (useCount is! int || useCount < 0) {
      throw const FormatException('Gwyn memory usage count is invalid.');
    }

    return GwynMemory(
      id: id,
      type: GwynMemoryType.fromWireName(type),
      text: text.trim(),
      sourcePhase: GwynMemoryPhase.fromWireName(sourcePhase),
      importance: importance.toDouble(),
      createdAt: DateTime.parse(createdAt).toUtc(),
      updatedAt: DateTime.parse(updatedAt).toUtc(),
      lastUsedAt: lastUsedAt == null
          ? null
          : DateTime.parse(lastUsedAt).toUtc(),
      useCount: useCount,
    );
  }
}
