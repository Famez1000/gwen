import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyAnxietyLogs = 'anxiety_logs';
  static const String _keyReflections = 'reflections';
  static const String _keyDailyJournalEntries = 'daily_journal_entries';
  static const String _keyProgressAnalyses = 'progress_analyses';
  static const String _keyBreathingSessions = 'breathing_sessions';
  static const String _keyStreakCount = 'streak_count';
  static const String _keyLastActiveDate = 'last_active_date';
  static const String _keySoundEnabled = 'sound_enabled';
  static const String _keyHapticEnabled = 'haptic_enabled';
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyEmergencyContact = 'emergency_contact';
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyOnboardingTrack = 'onboarding_track';
  static const String _keyPendingOnboardingPlan =
      'pending_onboarding_plan_type';
  static const String _keyUserName = 'user_name';
  static const String _keyProfileImageBase64 = 'profile_image_base64';
  static const String _keyAnxietyPersonaName = 'anxiety_persona_name';
  static const String _keyAnxietyPersonaDescription =
      'anxiety_persona_description';
  static const String _keyAnxietyPersonaImageBase64 =
      'anxiety_persona_image_base64';
  static const String _keyMoodRealityText = 'mood_reality_text';
  static const String _keyMoodFavoriteSongUrl = 'mood_favorite_song_url';
  static const String _keyHideMoodEntryPopup = 'hide_mood_entry_popup';
  static const String _keyHiddenMoodEntryPopups = 'hidden_mood_entry_popups';
  static const String _keyAffirmations = 'affirmations';
  static const String _keyRecentGwynJokes = 'recent_gwen_jokes';
  static const String _keyHealDisclaimerAccepted = 'heal_disclaimer_accepted';
  static const String _keyHideHealMethodsMessage = 'hide_heal_methods_message';
  static const String _keyHideUnderstandMethodsMessage =
      'hide_understand_methods_message';
  static const String _keyHideCopeMethodsMessage = 'hide_cope_methods_message';
  static const String _keyPlanningHintSeen = 'planning_hint_seen';
  static const String _keyReminderSwipeHintSeen = 'reminder_swipe_hint_seen';
  static const String _keyProgressSwipeHintSeen = 'progress_swipe_hint_seen';
  static const String _keyCopeDailyActivityDates = 'cope_daily_activity_dates';
  static const String _keyUnderstandDailyActivityDates =
      'understand_daily_activity_dates';
  static const String _keyHealDailyActivityDates = 'heal_daily_activity_dates';
  static const String _keyCopePlanName = 'cope_plan_name';
  static const String _keyCopePlanNames = 'cope_plan_names';
  static const String _keyUnderstandPlanNames = 'understand_plan_names';
  static const String _keyUnderstandPlanFeeling = 'understand_plan_feeling';
  static const String _keyHealPlanNames = 'heal_plan_names';
  static const String _keyHasCopePlan = 'has_cope_plan';
  static const String _keyActivePlanId = 'active_plan_id';
  static const String _keyGroundingObjects = 'grounding_objects';
  static const String _keyGroundingTouchObjects = 'grounding_touch_objects';
  static const String _keyGroundingSoundObjects = 'grounding_sound_objects';
  static const String _keyGroundingSmellObjects = 'grounding_smell_objects';
  static const String _keyGroundingTasteObjects = 'grounding_taste_objects';
  static const String _keyDebugSubscriptionActive = 'debug_subscription_active';
  static const String _keyStoreSubscriptionActive = 'store_subscription_active';
  static const String _keyDrawingGuessFreeRequestUsed =
      'drawing_guess_free_request_used';

  late final SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Anxiety logs storage
  List<Map<String, dynamic>> getAnxietyLogs() {
    final String? jsonStr = _prefs.getString(_keyAnxietyLogs);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAnxietyLogs(List<Map<String, dynamic>> logs) async {
    await _prefs.setString(_keyAnxietyLogs, jsonEncode(logs));
  }

  // Reflections storage
  List<Map<String, dynamic>> getReflections() {
    final String? jsonStr = _prefs.getString(_keyReflections);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveReflections(List<Map<String, dynamic>> reflections) async {
    await _prefs.setString(_keyReflections, jsonEncode(reflections));
  }

  List<Map<String, dynamic>> getDailyJournalEntries() {
    final String? jsonStr = _prefs.getString(_keyDailyJournalEntries);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDailyJournalEntries(
    List<Map<String, dynamic>> entries,
  ) async {
    await _prefs.setString(_keyDailyJournalEntries, jsonEncode(entries));
  }

  List<Map<String, dynamic>> getProgressAnalyses() {
    final String? jsonStr = _prefs.getString(_keyProgressAnalyses);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveProgressAnalyses(List<Map<String, dynamic>> analyses) async {
    await _prefs.setString(_keyProgressAnalyses, jsonEncode(analyses));
  }

  // Breathing sessions count
  int getBreathingSessionsCount() {
    return _prefs.getInt(_keyBreathingSessions) ?? 0;
  }

  Future<void> incrementBreathingSessionsCount() async {
    int current = getBreathingSessionsCount();
    await _prefs.setInt(_keyBreathingSessions, current + 1);
  }

  // Streak Count
  int getStreakCount() {
    return _prefs.getInt(_keyStreakCount) ?? 0;
  }

  Future<void> setStreakCount(int val) async {
    await _prefs.setInt(_keyStreakCount, val);
  }

  // Last Active Date
  String? getLastActiveDate() {
    return _prefs.getString(_keyLastActiveDate);
  }

  Future<void> setLastActiveDate(String dateStr) async {
    await _prefs.setString(_keyLastActiveDate, dateStr);
  }

  // Sound & Haptics preferences
  bool getSoundEnabled() {
    return _prefs.getBool(_keySoundEnabled) ?? false;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    await _prefs.setBool(_keySoundEnabled, enabled);
  }

  bool getHapticEnabled() {
    return _prefs.getBool(_keyHapticEnabled) ?? true;
  }

  Future<void> setHapticEnabled(bool enabled) async {
    await _prefs.setBool(_keyHapticEnabled, enabled);
  }

  // Theme mode preference (0 = System, 1 = Light, 2 = Dark)
  int getThemeMode() {
    return _prefs.getInt(_keyThemeMode) ?? 0;
  }

  Future<void> setThemeMode(int mode) async {
    await _prefs.setInt(_keyThemeMode, mode);
  }

  // Emergency contact (Format: "Name|Number")
  String getEmergencyContact() {
    return _prefs.getString(_keyEmergencyContact) ?? "Therapist|911";
  }

  Future<void> setEmergencyContact(String name, String phone) async {
    await _prefs.setString(_keyEmergencyContact, "$name|$phone");
  }

  bool getOnboardingCompleted() {
    return _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_keyOnboardingCompleted, completed);
  }

  String? getOnboardingTrack() {
    return _prefs.getString(_keyOnboardingTrack);
  }

  Future<void> setOnboardingTrack(String track) async {
    await _prefs.setString(_keyOnboardingTrack, track);
  }

  String? getPendingOnboardingPlan() {
    return _prefs.getString(_keyPendingOnboardingPlan);
  }

  Future<void> setPendingOnboardingPlan(String? planType) async {
    if (planType == null || planType.trim().isEmpty) {
      await _prefs.remove(_keyPendingOnboardingPlan);
      return;
    }
    await _prefs.setString(_keyPendingOnboardingPlan, planType);
  }

  String getUserName() {
    return _prefs.getString(_keyUserName) ?? '';
  }

  Future<void> setUserName(String name) async {
    await _prefs.setString(_keyUserName, name);
  }

  String getProfileImageBase64() {
    return _prefs.getString(_keyProfileImageBase64) ?? '';
  }

  Future<void> setProfileImageBase64(String imageBase64) async {
    await _prefs.setString(_keyProfileImageBase64, imageBase64);
  }

  String getAnxietyPersonaName() {
    return _prefs.getString(_keyAnxietyPersonaName) ?? '';
  }

  String getAnxietyPersonaDescription() {
    return _prefs.getString(_keyAnxietyPersonaDescription) ?? '';
  }

  String getAnxietyPersonaImageBase64() {
    return _prefs.getString(_keyAnxietyPersonaImageBase64) ?? '';
  }

  Future<void> setAnxietyPersona({
    required String name,
    required String description,
    required String imageBase64,
  }) async {
    await Future.wait([
      _prefs.setString(_keyAnxietyPersonaName, name),
      _prefs.setString(_keyAnxietyPersonaDescription, description),
      _prefs.setString(_keyAnxietyPersonaImageBase64, imageBase64),
    ]);
  }

  String getMoodRealityText() {
    return _prefs.getString(_keyMoodRealityText) ?? '';
  }

  Future<void> setMoodRealityText(String text) async {
    await _prefs.setString(_keyMoodRealityText, text);
  }

  String getMoodFavoriteSongUrl() {
    return _prefs.getString(_keyMoodFavoriteSongUrl) ?? '';
  }

  Future<void> setMoodFavoriteSongUrl(String url) async {
    await _prefs.setString(_keyMoodFavoriteSongUrl, url);
  }

  bool getHideMoodEntryPopup() {
    return _prefs.getBool(_keyHideMoodEntryPopup) ?? false;
  }

  Future<void> setHideMoodEntryPopup(bool hidden) async {
    await _prefs.setBool(_keyHideMoodEntryPopup, hidden);
  }

  Set<int> getHiddenMoodEntryPopups() {
    final savedIndexes = _prefs.getStringList(_keyHiddenMoodEntryPopups) ?? [];

    return savedIndexes
        .map(int.tryParse)
        .whereType<int>()
        .where((index) => index >= 1 && index <= 3)
        .toSet();
  }

  Future<void> setHiddenMoodEntryPopups(Set<int> indexes) async {
    final normalized =
        indexes
            .where((index) => index >= 1 && index <= 3)
            .map((index) => '$index')
            .toList()
          ..sort();

    await _prefs.setStringList(_keyHiddenMoodEntryPopups, normalized);
  }

  List<List<String>> getAffirmations() {
    final String? jsonStr = _prefs.getString(_keyAffirmations);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded
          .map(
            (category) =>
                (category as List<dynamic>).map((item) => '$item').toList(),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> setAffirmations(List<List<String>> affirmations) async {
    await _prefs.setString(_keyAffirmations, jsonEncode(affirmations));
  }

  List<String> getRecentGwynJokes() {
    return _prefs.getStringList(_keyRecentGwynJokes) ?? [];
  }

  Future<void> setRecentGwynJokes(List<String> jokes) async {
    await _prefs.setStringList(_keyRecentGwynJokes, jokes);
  }

  bool getHealDisclaimerAccepted() {
    return _prefs.getBool(_keyHealDisclaimerAccepted) ?? false;
  }

  Future<void> setHealDisclaimerAccepted(bool accepted) async {
    await _prefs.setBool(_keyHealDisclaimerAccepted, accepted);
  }

  bool getHideHealMethodsMessage() {
    return _prefs.getBool(_keyHideHealMethodsMessage) ?? false;
  }

  Future<void> setHideHealMethodsMessage(bool hidden) async {
    await _prefs.setBool(_keyHideHealMethodsMessage, hidden);
  }

  bool getHideUnderstandMethodsMessage() {
    return _prefs.getBool(_keyHideUnderstandMethodsMessage) ?? false;
  }

  Future<void> setHideUnderstandMethodsMessage(bool hidden) async {
    await _prefs.setBool(_keyHideUnderstandMethodsMessage, hidden);
  }

  bool getHideCopeMethodsMessage() {
    return _prefs.getBool(_keyHideCopeMethodsMessage) ?? false;
  }

  Future<void> setHideCopeMethodsMessage(bool hidden) async {
    await _prefs.setBool(_keyHideCopeMethodsMessage, hidden);
  }

  bool getPlanningHintSeen() {
    return _prefs.getBool(_keyPlanningHintSeen) ?? false;
  }

  Future<void> setPlanningHintSeen(bool seen) async {
    await _prefs.setBool(_keyPlanningHintSeen, seen);
  }

  bool getReminderSwipeHintSeen() {
    return _prefs.getBool(_keyReminderSwipeHintSeen) ?? false;
  }

  Future<void> setReminderSwipeHintSeen(bool seen) async {
    await _prefs.setBool(_keyReminderSwipeHintSeen, seen);
  }

  bool getProgressSwipeHintSeen() {
    return _prefs.getBool(_keyProgressSwipeHintSeen) ?? false;
  }

  Future<void> setProgressSwipeHintSeen(bool seen) async {
    await _prefs.setBool(_keyProgressSwipeHintSeen, seen);
  }

  Map<String, List<String>> getCopeDailyActivityDates() {
    final jsonText = _prefs.getString(_keyCopeDailyActivityDates);
    if (jsonText == null) return {};

    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(jsonText) as Map);
      return decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((date) => date.toString()).toList(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> setCopeDailyActivityDates(
    Map<String, List<String>> activityDates,
  ) async {
    await _prefs.setString(
      _keyCopeDailyActivityDates,
      jsonEncode(activityDates),
    );
  }

  Map<String, List<String>> getUnderstandDailyActivityDates() {
    final jsonText = _prefs.getString(_keyUnderstandDailyActivityDates);
    if (jsonText == null) return {};

    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(jsonText) as Map);
      return decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((date) => date.toString()).toList(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> setUnderstandDailyActivityDates(
    Map<String, List<String>> activityDates,
  ) async {
    await _prefs.setString(
      _keyUnderstandDailyActivityDates,
      jsonEncode(activityDates),
    );
  }

  Map<String, List<String>> getHealDailyActivityDates() {
    final jsonText = _prefs.getString(_keyHealDailyActivityDates);
    if (jsonText == null) return {};

    try {
      final decoded = Map<String, dynamic>.from(jsonDecode(jsonText) as Map);
      return decoded.map(
        (key, value) => MapEntry(
          key,
          (value as List<dynamic>).map((date) => date.toString()).toList(),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> setHealDailyActivityDates(
    Map<String, List<String>> activityDates,
  ) async {
    await _prefs.setString(
      _keyHealDailyActivityDates,
      jsonEncode(activityDates),
    );
  }

  String getCopePlanName() {
    return _prefs.getString(_keyCopePlanName) ?? 'Cope plan';
  }

  List<String> getCopePlanNames() {
    return _prefs.getStringList(_keyCopePlanNames) ?? [];
  }

  Future<void> setCopePlanNames(List<String> names) async {
    await _prefs.setStringList(_keyCopePlanNames, names);
  }

  List<String> getUnderstandPlanNames() {
    return _prefs.getStringList(_keyUnderstandPlanNames) ?? [];
  }

  Future<void> setUnderstandPlanNames(List<String> names) async {
    await _prefs.setStringList(_keyUnderstandPlanNames, names);
  }

  String getUnderstandPlanFeeling() {
    return _prefs.getString(_keyUnderstandPlanFeeling) ?? '';
  }

  Future<void> setUnderstandPlanFeeling(String feeling) async {
    await _prefs.setString(_keyUnderstandPlanFeeling, feeling);
  }

  List<String> getHealPlanNames() {
    return _prefs.getStringList(_keyHealPlanNames) ?? [];
  }

  Future<void> setHealPlanNames(List<String> names) async {
    await _prefs.setStringList(_keyHealPlanNames, names);
  }

  bool hasStoredCopePlanName() {
    return _prefs.containsKey(_keyCopePlanName);
  }

  Future<void> setCopePlanName(String name) async {
    await _prefs.setString(_keyCopePlanName, name);
  }

  bool getHasCopePlan() {
    return _prefs.getBool(_keyHasCopePlan) ?? false;
  }

  Future<void> setHasCopePlan(bool hasPlan) async {
    await _prefs.setBool(_keyHasCopePlan, hasPlan);
  }

  String getActivePlanId() {
    return _prefs.getString(_keyActivePlanId) ?? '';
  }

  Future<void> setActivePlanId(String planId) async {
    await _prefs.setString(_keyActivePlanId, planId);
  }

  bool getDrawingGuessFreeRequestUsed() {
    return _prefs.getBool(_keyDrawingGuessFreeRequestUsed) ?? false;
  }

  Future<void> setDrawingGuessFreeRequestUsed(bool used) async {
    await _prefs.setBool(_keyDrawingGuessFreeRequestUsed, used);
  }

  List<String> getGroundingObjects() {
    return _prefs.getStringList(_keyGroundingObjects) ?? [];
  }

  Future<void> setGroundingObjects(List<String> objects) async {
    await _prefs.setStringList(_keyGroundingObjects, objects);
  }

  List<String> getGroundingTouchObjects() {
    return _prefs.getStringList(_keyGroundingTouchObjects) ?? [];
  }

  Future<void> setGroundingTouchObjects(List<String> objects) async {
    await _prefs.setStringList(_keyGroundingTouchObjects, objects);
  }

  List<String> getGroundingSoundObjects() {
    return _prefs.getStringList(_keyGroundingSoundObjects) ?? [];
  }

  Future<void> setGroundingSoundObjects(List<String> objects) async {
    await _prefs.setStringList(_keyGroundingSoundObjects, objects);
  }

  List<String> getGroundingSmellObjects() {
    return _prefs.getStringList(_keyGroundingSmellObjects) ?? [];
  }

  Future<void> setGroundingSmellObjects(List<String> objects) async {
    await _prefs.setStringList(_keyGroundingSmellObjects, objects);
  }

  List<String> getGroundingTasteObjects() {
    return _prefs.getStringList(_keyGroundingTasteObjects) ?? [];
  }

  Future<void> setGroundingTasteObjects(List<String> objects) async {
    await _prefs.setStringList(_keyGroundingTasteObjects, objects);
  }

  bool getDebugSubscriptionActive() {
    return _prefs.getBool(_keyDebugSubscriptionActive) ?? false;
  }

  Future<void> setDebugSubscriptionActive(bool active) async {
    await _prefs.setBool(_keyDebugSubscriptionActive, active);
  }

  bool getStoreSubscriptionActive() {
    return _prefs.getBool(_keyStoreSubscriptionActive) ?? false;
  }

  Future<void> setStoreSubscriptionActive(bool active) async {
    await _prefs.setBool(_keyStoreSubscriptionActive, active);
  }
}
