import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Requests native store feedback only after sustained, meaningful app use.
///
/// Apple and Google ultimately decide whether their review sheet is shown, so
/// callers must never assume that [requestIfEligible] displays a prompt.
class ReviewPromptService {
  ReviewPromptService._();

  static final ReviewPromptService instance = ReviewPromptService._();

  static const _firstSeenKey = 'review_first_seen_at';
  static const _positiveDaysKey = 'review_positive_activity_days';
  static const _lastRequestKey = 'review_last_request_at';
  static const _requestCountKey = 'review_request_count';

  static const _minimumAppAge = Duration(days: 7);
  static const _requestCooldown = Duration(days: 120);
  static const _minimumPositiveDays = 3;
  static const _maximumRequests = 3;

  late final SharedPreferences _prefs;
  final InAppReview _inAppReview = InAppReview.instance;
  bool _initialized = false;
  bool _requestInProgress = false;

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;

    if (!_prefs.containsKey(_firstSeenKey)) {
      await _prefs.setString(
        _firstSeenKey,
        DateTime.now().toUtc().toIso8601String(),
      );
    }
  }

  /// Records at most one positive milestone per calendar day.
  Future<void> recordPositiveMoment() async {
    await init();
    final now = DateTime.now();
    final day =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final days = _prefs.getStringList(_positiveDaysKey) ?? <String>[];
    if (days.contains(day)) return;

    await _prefs.setStringList(
      _positiveDaysKey,
      [...days, day].take(_minimumPositiveDays).toList(),
    );
  }

  /// Requests the platform-owned review sheet when the user is eligible.
  Future<void> requestIfEligible() async {
    final supportedPlatform =
        defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    if (_requestInProgress || kIsWeb || !supportedPlatform) {
      return;
    }

    await init();
    final now = DateTime.now().toUtc();
    final firstSeen = DateTime.tryParse(_prefs.getString(_firstSeenKey) ?? '');
    final lastRequest = DateTime.tryParse(
      _prefs.getString(_lastRequestKey) ?? '',
    );
    final positiveDays = _prefs.getStringList(_positiveDaysKey) ?? <String>[];
    final requestCount = _prefs.getInt(_requestCountKey) ?? 0;

    if (firstSeen == null ||
        now.difference(firstSeen) < _minimumAppAge ||
        positiveDays.length < _minimumPositiveDays ||
        requestCount >= _maximumRequests ||
        (lastRequest != null &&
            now.difference(lastRequest) < _requestCooldown)) {
      return;
    }

    _requestInProgress = true;
    try {
      if (!await _inAppReview.isAvailable()) return;

      // Persist before requesting because the stores intentionally do not tell
      // apps whether the sheet was displayed or whether feedback was submitted.
      await _prefs.setString(_lastRequestKey, now.toIso8601String());
      await _prefs.setInt(_requestCountKey, requestCount + 1);
      await _inAppReview.requestReview();
    } catch (error, stackTrace) {
      debugPrint('Native review request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      _requestInProgress = false;
    }
  }
}
