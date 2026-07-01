import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService();
  static const List<String> defaultGroundingObjects = [
    'Window',
    'Plant',
    'Screen',
    'Lamp',
    'Book',
    'Chair',
    'Cup',
    'Sky',
  ];
  static const List<String> defaultGroundingTouchObjects = [
    'Feet on floor',
    'Fabric of shirt',
    'Cool desk surface',
    'Chair support',
  ];
  static const List<String> defaultGroundingSoundObjects = [
    'Hum of a fan',
    'Distant traffic',
    'Birds chirping',
    'Your breathing',
  ];
  static const List<String> defaultGroundingSmellObjects = [
    'Fresh air',
    'Soap scent',
  ];
  static const List<String> defaultGroundingTasteObjects = ['Cool water'];

  // Temporary UI States
  int _currentAnxietyLevel = 5;
  final Set<String> _selectedSymptoms = {};

  // Persisted States
  List<Map<String, dynamic>> _anxietyLogs = [];
  List<Map<String, dynamic>> _reflections = [];
  List<Map<String, dynamic>> _dailyJournalEntries = [];
  List<Map<String, dynamic>> _progressAnalyses = [];
  int _breathingSessionsCompleted = 0;
  int _streakCount = 0;
  bool _soundEnabled = true;
  bool _hapticEnabled = true;
  int _themeModeIndex = 0; // 0: System, 1: Light, 2: Dark
  String _emergencyContactName = 'Caregiver';
  String _emergencyContactPhone = '911';
  bool _onboardingCompleted = false;
  String _userName = '';
  String _moodRealityText = '';
  String _moodFavoriteSongUrl = '';
  bool _healDisclaimerAccepted = false;
  List<String> _recentGwenJokes = [];
  List<String> _groundingObjects = List.of(defaultGroundingObjects);
  List<String> _groundingTouchObjects = List.of(defaultGroundingTouchObjects);
  List<String> _groundingSoundObjects = List.of(defaultGroundingSoundObjects);
  List<String> _groundingSmellObjects = List.of(defaultGroundingSmellObjects);
  List<String> _groundingTasteObjects = List.of(defaultGroundingTasteObjects);

  // Getters
  int get currentAnxietyLevel => _currentAnxietyLevel;
  Set<String> get selectedSymptoms => _selectedSymptoms;
  List<Map<String, dynamic>> get anxietyLogs => _anxietyLogs;
  List<Map<String, dynamic>> get reflections => _reflections;
  List<Map<String, dynamic>> get dailyJournalEntries =>
      List.unmodifiable(_dailyJournalEntries);
  List<Map<String, dynamic>> get progressAnalyses =>
      List.unmodifiable(_progressAnalyses);
  int get breathingSessionsCompleted => _breathingSessionsCompleted;
  int get streakCount => _streakCount;
  bool get soundEnabled => _soundEnabled;
  bool get hapticEnabled => _hapticEnabled;
  int get themeModeIndex => _themeModeIndex;
  String get emergencyContactName => _emergencyContactName;
  String get emergencyContactPhone => _emergencyContactPhone;
  bool get onboardingCompleted => _onboardingCompleted;
  String get userName => _userName;
  String get moodRealityText => _moodRealityText;
  String get moodFavoriteSongUrl => _moodFavoriteSongUrl;
  bool get healDisclaimerAccepted => _healDisclaimerAccepted;
  List<String> get recentGwenJokes => List.unmodifiable(_recentGwenJokes);
  List<String> get groundingObjects => List.unmodifiable(_groundingObjects);
  List<String> get groundingTouchObjects =>
      List.unmodifiable(_groundingTouchObjects);
  List<String> get groundingSoundObjects =>
      List.unmodifiable(_groundingSoundObjects);
  List<String> get groundingSmellObjects =>
      List.unmodifiable(_groundingSmellObjects);
  List<String> get groundingTasteObjects =>
      List.unmodifiable(_groundingTasteObjects);

  ThemeMode get themeMode {
    if (_themeModeIndex == 1) return ThemeMode.light;
    if (_themeModeIndex == 2) return ThemeMode.dark;
    return ThemeMode.system;
  }

  // Initialize and load preferences
  Future<void> init() async {
    await _storage.init();

    _anxietyLogs = _storage.getAnxietyLogs();
    _reflections = _storage.getReflections();
    _dailyJournalEntries = _storage.getDailyJournalEntries();
    _sortDailyJournalEntries();
    _progressAnalyses = _storage.getProgressAnalyses();
    _sortProgressAnalyses();
    _breathingSessionsCompleted = _storage.getBreathingSessionsCount();
    _streakCount = _storage.getStreakCount();
    _soundEnabled = _storage.getSoundEnabled();
    _hapticEnabled = _storage.getHapticEnabled();
    _themeModeIndex = _storage.getThemeMode();
    _onboardingCompleted = _storage.getOnboardingCompleted();
    _userName = _storage.getUserName();
    _moodRealityText = _storage.getMoodRealityText();
    _moodFavoriteSongUrl = _storage.getMoodFavoriteSongUrl();
    _recentGwenJokes = _storage.getRecentGwenJokes();
    _healDisclaimerAccepted = _storage.getHealDisclaimerAccepted();
    final savedGroundingObjects = _storage.getGroundingObjects();
    _groundingObjects = _normalizeGroundingObjects(savedGroundingObjects);
    final savedGroundingTouchObjects = _storage.getGroundingTouchObjects();
    _groundingTouchObjects = _normalizeGroundingTouchObjects(
      savedGroundingTouchObjects,
    );
    final savedGroundingSoundObjects = _storage.getGroundingSoundObjects();
    _groundingSoundObjects = _normalizeGroundingSoundObjects(
      savedGroundingSoundObjects,
    );
    final savedGroundingSmellObjects = _storage.getGroundingSmellObjects();
    _groundingSmellObjects = _normalizeGroundingSmellObjects(
      savedGroundingSmellObjects,
    );
    final savedGroundingTasteObjects = _storage.getGroundingTasteObjects();
    _groundingTasteObjects = _normalizeGroundingTasteObjects(
      savedGroundingTasteObjects,
    );

    final contact = _storage.getEmergencyContact().split('|');
    if (contact.length == 2) {
      _emergencyContactName = contact[0];
      _emergencyContactPhone = contact[1];
    }

    _updateStreakIfNeeded();
    notifyListeners();
  }

  // Setters for UI controls
  void setAnxietyLevel(int val) {
    if (_currentAnxietyLevel != val) {
      _currentAnxietyLevel = val;
      notifyListeners();
    }
  }

  void toggleSymptom(String symptom) {
    if (_selectedSymptoms.contains(symptom)) {
      _selectedSymptoms.remove(symptom);
    } else {
      _selectedSymptoms.add(symptom);
    }
    notifyListeners();
  }

  void clearSymptoms() {
    _selectedSymptoms.clear();
    notifyListeners();
  }

  // Actions
  Future<void> addAnxietyLog(
    int preScore,
    int postScore,
    List<String> symptoms,
  ) async {
    final newLog = {
      'date': DateTime.now().toIso8601String(),
      'preScore': preScore,
      'postScore': postScore,
      'symptoms': symptoms,
    };
    _anxietyLogs.insert(0, newLog);
    // Keep max 50 logs to preserve storage size
    if (_anxietyLogs.length > 50) {
      _anxietyLogs = _anxietyLogs.sublist(0, 50);
    }
    await _storage.saveAnxietyLogs(_anxietyLogs);

    // Auto increment streak for taking action
    _markActivityToday();
    notifyListeners();
  }

  Future<void> addReflection(String text, List<String> triggers) async {
    final newReflection = {
      'date': DateTime.now().toIso8601String(),
      'note': text,
      'triggers': triggers,
    };
    _reflections.insert(0, newReflection);
    if (_reflections.length > 50) {
      _reflections = _reflections.sublist(0, 50);
    }
    await _storage.saveReflections(_reflections);

    _markActivityToday();
    notifyListeners();
  }

  Map<String, dynamic>? getDailyJournalEntryForDate(DateTime date) {
    final key = _dateKey(date);
    for (final entry in _dailyJournalEntries) {
      if (entry['date'] == key) return entry;
    }
    return null;
  }

  Future<void> saveDailyJournalEntry({
    required DateTime date,
    required int anxietyScore,
    required String feelings,
  }) async {
    final key = _dateKey(date);
    final now = DateTime.now().toIso8601String();
    final existingIndex = _dailyJournalEntries.indexWhere(
      (entry) => entry['date'] == key,
    );

    final entry = {
      'date': key,
      'createdAt': existingIndex == -1
          ? now
          : _dailyJournalEntries[existingIndex]['createdAt'] ?? now,
      'updatedAt': now,
      'anxietyScore': anxietyScore,
      'feelings': feelings.trim(),
    };

    if (existingIndex == -1) {
      _dailyJournalEntries.insert(0, entry);
    } else {
      _dailyJournalEntries[existingIndex] = entry;
    }

    _sortDailyJournalEntries();
    await _storage.saveDailyJournalEntries(_dailyJournalEntries);
    await _markActivityToday();
    notifyListeners();
  }

  Future<void> saveProgressAnalysis(String analysis) async {
    final trimmed = analysis.trim();
    if (trimmed.isEmpty) return;

    final entry = {
      'date': DateTime.now().toIso8601String(),
      'analysis': trimmed,
    };

    _progressAnalyses.insert(0, entry);
    if (_progressAnalyses.length > 50) {
      _progressAnalyses = _progressAnalyses.sublist(0, 50);
    }

    _sortProgressAnalyses();
    await _storage.saveProgressAnalyses(_progressAnalyses);
    await _markActivityToday();
    notifyListeners();
  }

  Future<void> rememberGwenJoke(String joke) async {
    final trimmed = joke.trim();
    if (trimmed.isEmpty) return;

    _recentGwenJokes
      ..removeWhere(
        (existing) => existing.trim().toLowerCase() == trimmed.toLowerCase(),
      )
      ..insert(0, trimmed);

    if (_recentGwenJokes.length > 10) {
      _recentGwenJokes = _recentGwenJokes.sublist(0, 10);
    }

    await _storage.setRecentGwenJokes(_recentGwenJokes);
    notifyListeners();
  }

  Future<void> completeBreathingSession() async {
    _breathingSessionsCompleted++;
    await _storage.incrementBreathingSessionsCount();
    _markActivityToday();
    notifyListeners();
  }

  // Settings configuration
  Future<void> toggleSound() async {
    _soundEnabled = !_soundEnabled;
    await _storage.setSoundEnabled(_soundEnabled);
    notifyListeners();
  }

  Future<void> toggleHaptic() async {
    _hapticEnabled = !_hapticEnabled;
    await _storage.setHapticEnabled(_hapticEnabled);
    notifyListeners();
  }

  Future<void> setThemeModeIndex(int index) async {
    _themeModeIndex = index;
    await _storage.setThemeMode(index);
    notifyListeners();
  }

  Future<void> saveEmergencyContact(String name, String phone) async {
    _emergencyContactName = name;
    _emergencyContactPhone = phone;
    await _storage.setEmergencyContact(name, phone);
    notifyListeners();
  }

  Future<void> completeOnboarding() async {
    _onboardingCompleted = true;
    await _storage.setOnboardingCompleted(true);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    _userName = name.trim();
    await _storage.setUserName(_userName);
    notifyListeners();
  }

  Future<void> setMoodRealityText(String text) async {
    if (_moodRealityText == text) return;

    _moodRealityText = text;
    await _storage.setMoodRealityText(text);
    notifyListeners();
  }

  Future<void> setMoodFavoriteSongUrl(String url) async {
    final trimmed = url.trim();
    if (_moodFavoriteSongUrl == trimmed) return;

    _moodFavoriteSongUrl = trimmed;
    await _storage.setMoodFavoriteSongUrl(trimmed);
    notifyListeners();
  }

  List<List<String>> getAffirmations(List<List<String>> defaultAffirmations) {
    return _normalizeNestedStrings(
      _storage.getAffirmations(),
      defaultAffirmations,
    );
  }

  Future<void> updateAffirmation({
    required List<List<String>> defaultAffirmations,
    required int categoryIndex,
    required int affirmationIndex,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty ||
        categoryIndex < 0 ||
        categoryIndex >= defaultAffirmations.length ||
        affirmationIndex < 0 ||
        affirmationIndex >= defaultAffirmations[categoryIndex].length) {
      return;
    }

    final affirmations = getAffirmations(defaultAffirmations);
    affirmations[categoryIndex][affirmationIndex] = trimmed;
    await _storage.setAffirmations(affirmations);
    notifyListeners();
  }

  Future<void> acceptHealDisclaimer() async {
    if (_healDisclaimerAccepted) return;

    _healDisclaimerAccepted = true;
    await _storage.setHealDisclaimerAccepted(true);
    notifyListeners();
  }

  Future<void> updateGroundingObject(int index, String object) async {
    final trimmed = object.trim();
    if (trimmed.isEmpty ||
        index < 0 ||
        index >= defaultGroundingObjects.length) {
      return;
    }

    _groundingObjects[index] = trimmed;
    await _storage.setGroundingObjects(_groundingObjects);
    notifyListeners();
  }

  Future<void> updateGroundingTouchObject(int index, String object) async {
    final trimmed = object.trim();
    if (trimmed.isEmpty ||
        index < 0 ||
        index >= defaultGroundingTouchObjects.length) {
      return;
    }

    _groundingTouchObjects[index] = trimmed;
    await _storage.setGroundingTouchObjects(_groundingTouchObjects);
    notifyListeners();
  }

  Future<void> updateGroundingSoundObject(int index, String object) async {
    final trimmed = object.trim();
    if (trimmed.isEmpty ||
        index < 0 ||
        index >= defaultGroundingSoundObjects.length) {
      return;
    }

    _groundingSoundObjects[index] = trimmed;
    await _storage.setGroundingSoundObjects(_groundingSoundObjects);
    notifyListeners();
  }

  Future<void> updateGroundingSmellObject(int index, String object) async {
    final trimmed = object.trim();
    if (trimmed.isEmpty ||
        index < 0 ||
        index >= defaultGroundingSmellObjects.length) {
      return;
    }

    _groundingSmellObjects[index] = trimmed;
    await _storage.setGroundingSmellObjects(_groundingSmellObjects);
    notifyListeners();
  }

  Future<void> updateGroundingTasteObject(int index, String object) async {
    final trimmed = object.trim();
    if (trimmed.isEmpty ||
        index < 0 ||
        index >= defaultGroundingTasteObjects.length) {
      return;
    }

    _groundingTasteObjects[index] = trimmed;
    await _storage.setGroundingTasteObjects(_groundingTasteObjects);
    notifyListeners();
  }

  // Streak tracking logic (focusing on gentle, positive streak increments)
  void _updateStreakIfNeeded() {
    final lastActiveStr = _storage.getLastActiveDate();
    if (lastActiveStr == null) {
      _streakCount = 0;
      return;
    }

    final today = _dateOnly(DateTime.now());
    final lastActive = DateTime.parse(lastActiveStr);
    final difference = today.difference(lastActive).inDays;

    if (difference > 1) {
      // Streak broken. But we do not show negative messages. Just set to 0.
      _streakCount = 0;
      _storage.setStreakCount(0);
    }
  }

  Future<void> _markActivityToday() async {
    final today = _dateOnly(DateTime.now());
    final lastActiveStr = _storage.getLastActiveDate();

    if (lastActiveStr == null) {
      _streakCount = 1;
      await _storage.setStreakCount(1);
    } else {
      final lastActive = DateTime.parse(lastActiveStr);
      final difference = today.difference(lastActive).inDays;
      if (difference == 1) {
        _streakCount++;
        await _storage.setStreakCount(_streakCount);
      } else if (difference > 1) {
        _streakCount = 1;
        await _storage.setStreakCount(1);
      }
    }
    await _storage.setLastActiveDate(today.toIso8601String());
  }

  DateTime _dateOnly(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  String _dateKey(DateTime dt) {
    final date = _dateOnly(dt);
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _sortDailyJournalEntries() {
    _dailyJournalEntries.sort(
      (a, b) =>
          (b['date'] as String? ?? '').compareTo(a['date'] as String? ?? ''),
    );
  }

  void _sortProgressAnalyses() {
    _progressAnalyses.sort(
      (a, b) =>
          (b['date'] as String? ?? '').compareTo(a['date'] as String? ?? ''),
    );
  }

  List<String> _normalizeGroundingObjects(List<String> savedObjects) {
    final normalized = List<String>.generate(defaultGroundingObjects.length, (
      index,
    ) {
      if (index >= savedObjects.length) return defaultGroundingObjects[index];

      final saved = savedObjects[index].trim();
      return saved.isEmpty ? defaultGroundingObjects[index] : saved;
    });

    return normalized;
  }

  List<String> _normalizeGroundingTouchObjects(List<String> savedObjects) {
    final normalized = List<String>.generate(
      defaultGroundingTouchObjects.length,
      (index) {
        if (index >= savedObjects.length) {
          return defaultGroundingTouchObjects[index];
        }

        final saved = savedObjects[index].trim();
        return saved.isEmpty ? defaultGroundingTouchObjects[index] : saved;
      },
    );

    return normalized;
  }

  List<String> _normalizeGroundingSoundObjects(List<String> savedObjects) {
    final normalized = List<String>.generate(
      defaultGroundingSoundObjects.length,
      (index) {
        if (index >= savedObjects.length) {
          return defaultGroundingSoundObjects[index];
        }

        final saved = savedObjects[index].trim();
        return saved.isEmpty ? defaultGroundingSoundObjects[index] : saved;
      },
    );

    return normalized;
  }

  List<String> _normalizeGroundingSmellObjects(List<String> savedObjects) {
    final normalized = List<String>.generate(
      defaultGroundingSmellObjects.length,
      (index) {
        if (index >= savedObjects.length) {
          return defaultGroundingSmellObjects[index];
        }

        final saved = savedObjects[index].trim();
        return saved.isEmpty ? defaultGroundingSmellObjects[index] : saved;
      },
    );

    return normalized;
  }

  List<String> _normalizeGroundingTasteObjects(List<String> savedObjects) {
    final normalized = List<String>.generate(
      defaultGroundingTasteObjects.length,
      (index) {
        if (index >= savedObjects.length) {
          return defaultGroundingTasteObjects[index];
        }

        final saved = savedObjects[index].trim();
        return saved.isEmpty ? defaultGroundingTasteObjects[index] : saved;
      },
    );

    return normalized;
  }

  List<List<String>> _normalizeNestedStrings(
    List<List<String>> savedValues,
    List<List<String>> defaultValues,
  ) {
    return List<List<String>>.generate(defaultValues.length, (categoryIndex) {
      final defaultCategory = defaultValues[categoryIndex];
      final savedCategory = categoryIndex < savedValues.length
          ? savedValues[categoryIndex]
          : const <String>[];

      return List<String>.generate(defaultCategory.length, (itemIndex) {
        if (itemIndex >= savedCategory.length) {
          return defaultCategory[itemIndex];
        }

        final saved = savedCategory[itemIndex].trim();
        return saved.isEmpty ? defaultCategory[itemIndex] : saved;
      });
    });
  }
}
