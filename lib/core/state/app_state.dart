import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/review_prompt_service.dart';
import '../services/storage_service.dart';

enum OnboardingTrack { classic, personalized }

class AppState extends ChangeNotifier {
  static const int maxDailyJournalEntries = 90;
  static const String copeAffirmationsActivity = 'affirmations';
  static const String copeGroundingActivity = 'grounding';
  static const String copeMeditationsActivity = 'meditations';
  static const String copeLeafActivity = 'leaf_exercise';

  final StorageService _storage = StorageService();
  static const String copePlanId = 'cope_plan_1';
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
  OnboardingTrack _onboardingTrack = OnboardingTrack.classic;
  String _userName = '';
  String _profileImageBase64 = '';
  String _moodRealityText = '';
  String _moodFavoriteSongUrl = '';
  bool _hideMoodEntryPopup = false;
  Set<int> _hiddenMoodEntryPopups = {};
  bool _healDisclaimerAccepted = false;
  bool _hideHealMethodsMessage = false;
  bool _hideUnderstandMethodsMessage = false;
  bool _hideCopeMethodsMessage = false;
  bool _planningHintSeen = false;
  bool _reminderSwipeHintSeen = false;
  bool _progressSwipeHintSeen = false;
  Map<String, List<String>> _copeDailyActivityDates = {};
  String _copePlanName = 'Cope plan';
  List<String> _copePlanNames = [];
  List<String> _understandPlanNames = [];
  List<String> _healPlanNames = [];
  bool _hasCopePlan = false;
  String _activePlanId = '';
  bool _storeSubscriptionActive = false;
  bool _debugSubscriptionActive = false;
  bool _drawingGuessFreeRequestUsed = false;
  List<String> _recentGwynJokes = [];
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
  OnboardingTrack get onboardingTrack => _onboardingTrack;
  String get userName => _userName;
  String get profileImageBase64 => _profileImageBase64;
  String get moodRealityText => _moodRealityText;
  String get moodFavoriteSongUrl => _moodFavoriteSongUrl;
  bool get hideMoodEntryPopup => _hideMoodEntryPopup;
  bool isMoodEntryPopupHidden(int moodIndex) =>
      _hiddenMoodEntryPopups.contains(moodIndex);
  bool get healDisclaimerAccepted => _healDisclaimerAccepted;
  bool get hideHealMethodsMessage => _hideHealMethodsMessage;
  bool get hideUnderstandMethodsMessage => _hideUnderstandMethodsMessage;
  bool get hideCopeMethodsMessage => _hideCopeMethodsMessage;
  bool get planningHintSeen => _planningHintSeen;
  bool get reminderSwipeHintSeen => _reminderSwipeHintSeen;
  bool get progressSwipeHintSeen => _progressSwipeHintSeen;
  String get copePlanName => _copePlanName;
  List<String> get copePlanNames => List.unmodifiable(_copePlanNames);
  List<String> get understandPlanNames =>
      List.unmodifiable(_understandPlanNames);
  List<String> get healPlanNames => List.unmodifiable(_healPlanNames);
  bool get hasCopePlan => _hasCopePlan;
  bool get hasUnderstandPlan => _understandPlanNames.isNotEmpty;
  bool get hasHealPlan => _healPlanNames.isNotEmpty;
  bool get hasAnyPlan => _hasCopePlan || hasUnderstandPlan || hasHealPlan;
  String get activePlanId => _activePlanId;
  bool get isCopePlanActive => isPlanActive(_copePlanName);
  String get nextCopePlanName =>
      _copePlanNames.isEmpty ? 'Cope plan' : _copePlanNames.first;

  String get nextUnderstandPlanName => _understandPlanNames.isEmpty
      ? 'Understand plan'
      : _understandPlanNames.first;

  String get nextHealPlanName =>
      _healPlanNames.isEmpty ? 'Heal plan' : _healPlanNames.first;

  bool get hasActiveSubscription =>
      _storeSubscriptionActive || (kDebugMode && _debugSubscriptionActive);
  bool get hasStoreSubscription => _storeSubscriptionActive;
  bool get hasDebugSubscription => kDebugMode && _debugSubscriptionActive;
  bool get drawingGuessFreeRequestUsed => _drawingGuessFreeRequestUsed;
  List<String> get recentGwynJokes => List.unmodifiable(_recentGwynJokes);
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
    if (_dailyJournalEntries.length > maxDailyJournalEntries) {
      _dailyJournalEntries = _dailyJournalEntries
          .take(maxDailyJournalEntries)
          .toList();
      await _storage.saveDailyJournalEntries(_dailyJournalEntries);
    }
    _progressAnalyses = _storage.getProgressAnalyses();
    _sortProgressAnalyses();
    _breathingSessionsCompleted = _storage.getBreathingSessionsCount();
    _streakCount = _storage.getStreakCount();
    _soundEnabled = _storage.getSoundEnabled();
    _hapticEnabled = _storage.getHapticEnabled();
    _themeModeIndex = _storage.getThemeMode();
    _onboardingCompleted = _storage.getOnboardingCompleted();
    final storedOnboardingTrack = _storage.getOnboardingTrack();
    const usePersonalizedByDefault = bool.fromEnvironment(
      'PERSONALIZED_ONBOARDING',
      defaultValue: false,
    );
    _onboardingTrack =
        storedOnboardingTrack == 'personalized' ||
            (storedOnboardingTrack == null && usePersonalizedByDefault)
        ? OnboardingTrack.personalized
        : OnboardingTrack.classic;
    _userName = _storage.getUserName();
    _profileImageBase64 = _storage.getProfileImageBase64();
    _moodRealityText = _storage.getMoodRealityText();
    _moodFavoriteSongUrl = _storage.getMoodFavoriteSongUrl();
    _hideMoodEntryPopup = _storage.getHideMoodEntryPopup();
    _hiddenMoodEntryPopups = _storage.getHiddenMoodEntryPopups();
    _recentGwynJokes = _storage.getRecentGwynJokes();
    _healDisclaimerAccepted = _storage.getHealDisclaimerAccepted();
    _hideHealMethodsMessage = _storage.getHideHealMethodsMessage();
    _hideUnderstandMethodsMessage = _storage.getHideUnderstandMethodsMessage();
    _hideCopeMethodsMessage = _storage.getHideCopeMethodsMessage();
    _planningHintSeen = _storage.getPlanningHintSeen();
    _reminderSwipeHintSeen = _storage.getReminderSwipeHintSeen();
    _progressSwipeHintSeen = _storage.getProgressSwipeHintSeen();
    _copeDailyActivityDates = _storage.getCopeDailyActivityDates();
    _copePlanName = _storage.getCopePlanName();
    _copePlanNames = _storage.getCopePlanNames();
    _understandPlanNames = _storage.getUnderstandPlanNames();
    _healPlanNames = _storage.getHealPlanNames();
    _hasCopePlan = _storage.getHasCopePlan();
    if (!_hasCopePlan && _storage.hasStoredCopePlanName()) {
      _hasCopePlan = true;
      await _storage.setHasCopePlan(true);
    }
    if (_copePlanNames.isEmpty && _hasCopePlan) {
      _copePlanNames = [_copePlanName];
      await _storage.setCopePlanNames(_copePlanNames);
    }
    _activePlanId = _storage.getActivePlanId();
    await _migrateLegacyDefaultPlanNames();
    if (_hasCopePlan && _activePlanId.isEmpty) {
      _activePlanId = _copePlanId(_copePlanName);
      await _storage.setActivePlanId(_activePlanId);
    } else if (_hasCopePlan &&
        _activePlanId == copePlanId &&
        _copePlanNames.isNotEmpty) {
      _activePlanId = _copePlanId(_copePlanNames.first);
      await _storage.setActivePlanId(_activePlanId);
    }
    _storeSubscriptionActive = _storage.getStoreSubscriptionActive();
    _debugSubscriptionActive = _storage.getDebugSubscriptionActive();
    _drawingGuessFreeRequestUsed = _storage.getDrawingGuessFreeRequestUsed();
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
    await ReviewPromptService.instance.recordPositiveMoment();
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
    if (_dailyJournalEntries.length > maxDailyJournalEntries) {
      _dailyJournalEntries = _dailyJournalEntries
          .take(maxDailyJournalEntries)
          .toList();
    }
    await _storage.saveDailyJournalEntries(_dailyJournalEntries);
    await _markActivityToday();
    await ReviewPromptService.instance.recordPositiveMoment();
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

  Future<void> rememberGwynJoke(String joke) async {
    final trimmed = joke.trim();
    if (trimmed.isEmpty) return;

    _recentGwynJokes
      ..removeWhere(
        (existing) => existing.trim().toLowerCase() == trimmed.toLowerCase(),
      )
      ..insert(0, trimmed);

    if (_recentGwynJokes.length > 10) {
      _recentGwynJokes = _recentGwynJokes.sublist(0, 10);
    }

    await _storage.setRecentGwynJokes(_recentGwynJokes);
    notifyListeners();
  }

  Future<void> completeBreathingSession() async {
    _breathingSessionsCompleted++;
    await _storage.incrementBreathingSessionsCount();
    _markActivityToday();
    await ReviewPromptService.instance.recordPositiveMoment();
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

  Future<void> setOnboardingTrack(OnboardingTrack track) async {
    if (_onboardingTrack == track) return;

    _onboardingTrack = track;
    await _storage.setOnboardingTrack(track.name);
    notifyListeners();
  }

  Future<void> setPendingOnboardingPlan(String? planType) async {
    await _storage.setPendingOnboardingPlan(planType?.toLowerCase());
  }

  Future<void> setUserName(String name) async {
    _userName = name.trim();
    await _storage.setUserName(_userName);
    notifyListeners();
  }

  Future<void> setProfileImageBase64(String imageBase64) async {
    _profileImageBase64 = imageBase64;
    await _storage.setProfileImageBase64(imageBase64);
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

  Future<void> setHideMoodEntryPopup(bool hidden) async {
    if (_hideMoodEntryPopup == hidden) return;

    _hideMoodEntryPopup = hidden;
    await _storage.setHideMoodEntryPopup(hidden);
    notifyListeners();
  }

  Future<void> setMoodEntryPopupHidden(int moodIndex, bool hidden) async {
    if (moodIndex < 1 || moodIndex > 3) return;

    final nextHiddenMoodEntryPopups = Set<int>.of(_hiddenMoodEntryPopups);
    if (hidden) {
      nextHiddenMoodEntryPopups.add(moodIndex);
    } else {
      nextHiddenMoodEntryPopups.remove(moodIndex);
    }

    if (setEquals(_hiddenMoodEntryPopups, nextHiddenMoodEntryPopups)) return;

    _hiddenMoodEntryPopups = nextHiddenMoodEntryPopups;
    await _storage.setHiddenMoodEntryPopups(_hiddenMoodEntryPopups);
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

  Future<void> setHideHealMethodsMessage(bool hidden) async {
    if (_hideHealMethodsMessage == hidden) return;

    _hideHealMethodsMessage = hidden;
    await _storage.setHideHealMethodsMessage(hidden);
    notifyListeners();
  }

  Future<void> setHideUnderstandMethodsMessage(bool hidden) async {
    if (_hideUnderstandMethodsMessage == hidden) return;

    _hideUnderstandMethodsMessage = hidden;
    await _storage.setHideUnderstandMethodsMessage(hidden);
    notifyListeners();
  }

  Future<void> setHideCopeMethodsMessage(bool hidden) async {
    if (_hideCopeMethodsMessage == hidden) return;

    _hideCopeMethodsMessage = hidden;
    await _storage.setHideCopeMethodsMessage(hidden);
    notifyListeners();
  }

  Future<void> markPlanningHintSeen() async {
    if (_planningHintSeen) return;

    _planningHintSeen = true;
    await _storage.setPlanningHintSeen(true);
    notifyListeners();
  }

  Future<void> markReminderSwipeHintSeen() async {
    if (_reminderSwipeHintSeen) return;

    _reminderSwipeHintSeen = true;
    await _storage.setReminderSwipeHintSeen(true);
    notifyListeners();
  }

  Future<void> markProgressSwipeHintSeen() async {
    if (_progressSwipeHintSeen) return;

    _progressSwipeHintSeen = true;
    await _storage.setProgressSwipeHintSeen(true);
    notifyListeners();
  }

  bool isCopeActivityCompletedToday(String activity) {
    return (_copeDailyActivityDates[activity] ?? const <String>[]).contains(
      _dateKey(DateTime.now()),
    );
  }

  Future<void> setCopeActivityCompletedToday(
    String activity,
    bool completed,
  ) async {
    final today = _dateKey(DateTime.now());
    final dates = {...?_copeDailyActivityDates[activity]};
    if (completed) {
      dates.add(today);
    } else {
      dates.remove(today);
    }

    _copeDailyActivityDates = {
      ..._copeDailyActivityDates,
      activity: dates.toList()..sort(),
    };
    await _storage.setCopeDailyActivityDates(_copeDailyActivityDates);
    notifyListeners();
  }

  int copeActivityStreak(String activity) {
    final dates = (_copeDailyActivityDates[activity] ?? const <String>[])
        .toSet();
    if (dates.isEmpty) return 0;

    var cursor = _dateOnly(DateTime.now());
    if (!dates.contains(_dateKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    var streak = 0;
    while (dates.contains(_dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<void> setCopePlanName(String name) async {
    final trimmed = name.trim();
    final nextName = trimmed.isEmpty ? 'Cope plan' : trimmed;
    if (_copePlanName == nextName) return;

    final previousName = _copePlanName;
    final previousPlanId = _copePlanId(previousName);
    final activeIndex = _copePlanNames.indexOf(_copePlanName);
    if (activeIndex != -1) {
      _copePlanNames[activeIndex] = nextName;
    } else {
      _copePlanNames = [..._copePlanNames, nextName];
    }
    if (_copePlanNames.isNotEmpty) {
      await _storage.setCopePlanNames(_copePlanNames);
    }

    _copePlanName = nextName;
    await _storage.setCopePlanName(nextName);
    if (_activePlanId == previousPlanId) {
      _activePlanId = _copePlanId(nextName);
      await _storage.setActivePlanId(_activePlanId);
    }
    notifyListeners();
  }

  Future<void> saveCopePlan({String? name}) async {
    final nextName = (name?.trim().isNotEmpty ?? false)
        ? name!.trim()
        : nextCopePlanName;
    final alreadySaved = _copePlanNames.any(
      (savedName) => savedName.toLowerCase() == nextName.toLowerCase(),
    );

    if (!alreadySaved) {
      _copePlanNames = [..._copePlanNames, nextName];
      await _storage.setCopePlanNames(_copePlanNames);
    }

    _hasCopePlan = true;
    await _storage.setHasCopePlan(true);
    _copePlanName = nextName;
    await _storage.setCopePlanName(nextName);
    _activePlanId = _copePlanId(nextName);
    await _storage.setActivePlanId(_activePlanId);
    await ReviewPromptService.instance.recordPositiveMoment();
    notifyListeners();
  }

  Future<void> saveUnderstandPlan({String? name}) async {
    final nextName = (name?.trim().isNotEmpty ?? false)
        ? name!.trim()
        : nextUnderstandPlanName;
    final alreadySaved = _understandPlanNames.any(
      (savedName) => savedName.toLowerCase() == nextName.toLowerCase(),
    );

    if (!alreadySaved) {
      _understandPlanNames = [..._understandPlanNames, nextName];
      await _storage.setUnderstandPlanNames(_understandPlanNames);
    }

    _activePlanId = understandPlanIdForName(nextName);
    await _storage.setActivePlanId(_activePlanId);
    await ReviewPromptService.instance.recordPositiveMoment();
    notifyListeners();
  }

  Future<void> saveHealPlan({String? name}) async {
    final nextName = (name?.trim().isNotEmpty ?? false)
        ? name!.trim()
        : nextHealPlanName;
    final alreadySaved = _healPlanNames.any(
      (savedName) => savedName.toLowerCase() == nextName.toLowerCase(),
    );

    if (!alreadySaved) {
      _healPlanNames = [..._healPlanNames, nextName];
      await _storage.setHealPlanNames(_healPlanNames);
    }

    _activePlanId = healPlanIdForName(nextName);
    await _storage.setActivePlanId(_activePlanId);
    await ReviewPromptService.instance.recordPositiveMoment();
    notifyListeners();
  }

  Future<void> setActivePlan(String planId) async {
    if (planId.trim().isEmpty || _activePlanId == planId) return;

    _activePlanId = planId;
    await _storage.setActivePlanId(planId);
    String? activeName;
    for (final name in _copePlanNames) {
      if (_copePlanId(name) == planId) {
        activeName = name;
        break;
      }
    }
    if (activeName != null) {
      _copePlanName = activeName;
      await _storage.setCopePlanName(activeName);
    }
    notifyListeners();
  }

  Future<void> deactivateActivePlan() async {
    if (_activePlanId == 'none') return;

    _activePlanId = 'none';
    await _storage.setActivePlanId(_activePlanId);
    notifyListeners();
  }

  Future<bool> renamePlan(String planId, String name) async {
    final nextName = name.trim();
    if (nextName.isEmpty) return false;

    Future<bool> renameInList({
      required List<String> names,
      required String Function(String) idForName,
      required Future<void> Function(List<String>) saveNames,
      required void Function(List<String>) updateNames,
      Future<void> Function(String previousName, String nextName)? afterRename,
    }) async {
      final index = names.indexWhere(
        (savedName) => idForName(savedName) == planId,
      );
      if (index == -1) return false;

      final duplicateIndex = names.indexWhere(
        (savedName) => savedName.toLowerCase() == nextName.toLowerCase(),
      );
      if (duplicateIndex != -1 && duplicateIndex != index) return false;

      final previousName = names[index];
      final updatedNames = [...names]..[index] = nextName;
      updateNames(updatedNames);
      await saveNames(updatedNames);
      if (afterRename != null) {
        await afterRename(previousName, nextName);
      }

      if (_activePlanId == planId) {
        _activePlanId = idForName(nextName);
        await _storage.setActivePlanId(_activePlanId);
      }
      notifyListeners();
      return true;
    }

    if (planId.startsWith('cope_plan:')) {
      return renameInList(
        names: _copePlanNames,
        idForName: _copePlanId,
        saveNames: _storage.setCopePlanNames,
        updateNames: (names) => _copePlanNames = names,
        afterRename: (previousName, nextName) async {
          if (_copePlanName == previousName) {
            _copePlanName = nextName;
            await _storage.setCopePlanName(nextName);
          }
        },
      );
    }
    if (planId.startsWith('understand_plan:')) {
      return renameInList(
        names: _understandPlanNames,
        idForName: understandPlanIdForName,
        saveNames: _storage.setUnderstandPlanNames,
        updateNames: (names) => _understandPlanNames = names,
      );
    }
    if (planId.startsWith('heal_plan:')) {
      return renameInList(
        names: _healPlanNames,
        idForName: healPlanIdForName,
        saveNames: _storage.setHealPlanNames,
        updateNames: (names) => _healPlanNames = names,
      );
    }

    return false;
  }

  Future<void> deletePlan(String planId) async {
    var removed = false;

    final copePlanName = _copePlanNames.cast<String?>().firstWhere(
      (name) => name != null && _copePlanId(name) == planId,
      orElse: () => null,
    );
    if (copePlanName != null) {
      _copePlanNames = _copePlanNames
          .where((name) => name != copePlanName)
          .toList();
      _hasCopePlan = _copePlanNames.isNotEmpty;
      await _storage.setCopePlanNames(_copePlanNames);
      await _storage.setHasCopePlan(_hasCopePlan);

      if (_copePlanName == copePlanName) {
        _copePlanName = _copePlanNames.isEmpty
            ? 'Cope plan'
            : _copePlanNames.first;
        await _storage.setCopePlanName(_copePlanName);
      }
      removed = true;
    }

    if (!removed) {
      final understandPlanName = _understandPlanNames
          .cast<String?>()
          .firstWhere(
            (name) => name != null && understandPlanIdForName(name) == planId,
            orElse: () => null,
          );
      if (understandPlanName != null) {
        _understandPlanNames = _understandPlanNames
            .where((name) => name != understandPlanName)
            .toList();
        await _storage.setUnderstandPlanNames(_understandPlanNames);
        removed = true;
      }
    }

    if (!removed) {
      final healPlanName = _healPlanNames.cast<String?>().firstWhere(
        (name) => name != null && healPlanIdForName(name) == planId,
        orElse: () => null,
      );
      if (healPlanName != null) {
        _healPlanNames = _healPlanNames
            .where((name) => name != healPlanName)
            .toList();
        await _storage.setHealPlanNames(_healPlanNames);
        removed = true;
      }
    }

    if (!removed) return;

    if (_activePlanId == planId) {
      if (_copePlanNames.isNotEmpty) {
        _activePlanId = _copePlanId(_copePlanNames.first);
        _copePlanName = _copePlanNames.first;
        await _storage.setCopePlanName(_copePlanName);
      } else if (_understandPlanNames.isNotEmpty) {
        _activePlanId = understandPlanIdForName(_understandPlanNames.first);
      } else if (_healPlanNames.isNotEmpty) {
        _activePlanId = healPlanIdForName(_healPlanNames.first);
      } else {
        _activePlanId = '';
      }
      await _storage.setActivePlanId(_activePlanId);
    }

    notifyListeners();
  }

  bool isPlanActive(String planName) {
    return _activePlanId == _copePlanId(planName);
  }

  bool isUnderstandPlanActive(String planName) {
    return _activePlanId == understandPlanIdForName(planName);
  }

  bool isHealPlanActive(String planName) {
    return _activePlanId == healPlanIdForName(planName);
  }

  String copePlanIdForName(String planName) => _copePlanId(planName);

  String understandPlanIdForName(String planName) {
    return _typedPlanId('understand_plan', planName);
  }

  String healPlanIdForName(String planName) {
    return _typedPlanId('heal_plan', planName);
  }

  String _copePlanId(String planName) {
    return _typedPlanId('cope_plan', planName);
  }

  String _typedPlanId(String type, String planName) {
    return '$type:${planName.trim().toLowerCase()}';
  }

  Future<void> _migrateLegacyDefaultPlanNames() async {
    final activePlanReplacements = <String, String>{};

    List<String> migrateNames(
      List<String> names, {
      required String aspect,
      required String planType,
    }) {
      return names.map((name) {
        final migrated = _migrateLegacyDefaultPlanName(name, aspect);
        if (migrated != name) {
          activePlanReplacements[_typedPlanId(planType, name)] = _typedPlanId(
            planType,
            migrated,
          );
        }
        return migrated;
      }).toList();
    }

    final migratedCopeNames = migrateNames(
      _copePlanNames,
      aspect: 'Cope',
      planType: 'cope_plan',
    );
    final migratedUnderstandNames = migrateNames(
      _understandPlanNames,
      aspect: 'Understand',
      planType: 'understand_plan',
    );
    final migratedHealNames = migrateNames(
      _healPlanNames,
      aspect: 'Heal',
      planType: 'heal_plan',
    );
    final migratedCopePlanName = _migrateLegacyDefaultPlanName(
      _copePlanName,
      'Cope',
    );

    if (!listEquals(migratedCopeNames, _copePlanNames)) {
      _copePlanNames = migratedCopeNames;
      await _storage.setCopePlanNames(_copePlanNames);
    }
    if (!listEquals(migratedUnderstandNames, _understandPlanNames)) {
      _understandPlanNames = migratedUnderstandNames;
      await _storage.setUnderstandPlanNames(_understandPlanNames);
    }
    if (!listEquals(migratedHealNames, _healPlanNames)) {
      _healPlanNames = migratedHealNames;
      await _storage.setHealPlanNames(_healPlanNames);
    }
    if (migratedCopePlanName != _copePlanName) {
      _copePlanName = migratedCopePlanName;
      await _storage.setCopePlanName(_copePlanName);
    }

    final migratedActivePlanId = activePlanReplacements[_activePlanId];
    if (migratedActivePlanId != null) {
      _activePlanId = migratedActivePlanId;
      await _storage.setActivePlanId(_activePlanId);
    }
  }

  String _migrateLegacyDefaultPlanName(String name, String aspect) {
    final normalized = name.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    final legacyCompact = '${aspect.toLowerCase()} plan1';
    final legacySpaced = '${aspect.toLowerCase()} plan 1';
    if (normalized == legacyCompact || normalized == legacySpaced) {
      return '$aspect plan';
    }
    return name;
  }

  Future<void> useDrawingGuessFreeRequest() async {
    if (_drawingGuessFreeRequestUsed) return;

    _drawingGuessFreeRequestUsed = true;
    await _storage.setDrawingGuessFreeRequestUsed(true);
    notifyListeners();
  }

  Future<void> resetDrawingGuessFreeRequestForDebug() async {
    if (!kDebugMode || !_drawingGuessFreeRequestUsed) return;

    _drawingGuessFreeRequestUsed = false;
    await _storage.setDrawingGuessFreeRequestUsed(false);
    notifyListeners();
  }

  Future<void> activateDebugSubscription() async {
    if (!kDebugMode || _debugSubscriptionActive) return;

    _debugSubscriptionActive = true;
    await _storage.setDebugSubscriptionActive(true);
    await _unlockPendingOnboardingPlan();
    notifyListeners();
  }

  Future<void> activateStoreSubscription() async {
    if (_storeSubscriptionActive) return;

    _storeSubscriptionActive = true;
    await _storage.setStoreSubscriptionActive(true);
    await _unlockPendingOnboardingPlan();
    notifyListeners();
  }

  Future<void> _unlockPendingOnboardingPlan() async {
    final planType = _storage.getPendingOnboardingPlan();
    switch (planType) {
      case 'cope':
        await saveCopePlan();
        break;
      case 'understand':
        await saveUnderstandPlan();
        break;
      case 'heal':
        await saveHealPlan();
        break;
    }
    if (planType != null) {
      await _storage.setPendingOnboardingPlan(null);
    }
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
