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
  static const String _keyUserName = 'user_name';
  static const String _keyMoodRealityText = 'mood_reality_text';
  static const String _keyMoodFavoriteSongUrl = 'mood_favorite_song_url';
  static const String _keyAffirmations = 'affirmations';
  static const String _keyRecentGwenJokes = 'recent_gwen_jokes';
  static const String _keyHealDisclaimerAccepted = 'heal_disclaimer_accepted';
  static const String _keyGroundingObjects = 'grounding_objects';
  static const String _keyGroundingTouchObjects = 'grounding_touch_objects';
  static const String _keyGroundingSoundObjects = 'grounding_sound_objects';
  static const String _keyGroundingSmellObjects = 'grounding_smell_objects';
  static const String _keyGroundingTasteObjects = 'grounding_taste_objects';

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
    return _prefs.getBool(_keySoundEnabled) ?? true;
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

  String getUserName() {
    return _prefs.getString(_keyUserName) ?? '';
  }

  Future<void> setUserName(String name) async {
    await _prefs.setString(_keyUserName, name);
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

  List<String> getRecentGwenJokes() {
    return _prefs.getStringList(_keyRecentGwenJokes) ?? [];
  }

  Future<void> setRecentGwenJokes(List<String> jokes) async {
    await _prefs.setStringList(_keyRecentGwenJokes, jokes);
  }

  bool getHealDisclaimerAccepted() {
    return _prefs.getBool(_keyHealDisclaimerAccepted) ?? false;
  }

  Future<void> setHealDisclaimerAccepted(bool accepted) async {
    await _prefs.setBool(_keyHealDisclaimerAccepted, accepted);
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
}
