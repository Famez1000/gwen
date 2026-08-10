import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const List<DailyReminderSchedule> defaultDailyReminders = [
    DailyReminderSchedule(
      id: 1001,
      title: 'Gwyn reminder',
      body: 'Pause. Breathe. You are safer than the worry says.',
      hour: 9,
      minute: 0,
      isEnabled: true,
    ),
  ];

  static const String _channelId = 'daily_calm_reminders';
  static const String _channelName = 'Daily calm reminders';
  static const String _channelDescription =
      'Daily reminders to pause, breathe, and check in.';
  static const String _reminderSchedulesKey = 'daily_reminder_schedules';
  static const String _planReminderSchedulesKeyPrefix =
      'plan_reminder_schedules';
  static const String _dailyGwynReminderMigrationKey =
      'daily_gwyn_reminder_migrated';
  static const String _dailyGwynReminderAssetPath =
      'assets/data/gwyn_daily_reminders.json';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/launcher_icon'),
      iOS: DarwinInitializationSettings(),
      macOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings: initializationSettings);

    _isInitialized = true;
  }

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    var granted = true;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      granted =
          await androidPlugin?.requestNotificationsPermission() ?? granted;
    } else if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      final darwinPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      granted =
          await darwinPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          granted;

      final macPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      granted =
          await macPlugin?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          granted;
    }

    return granted;
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    await init();
    await requestPermissions();

    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextDailyInstance(hour, minute),
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> schedulePlanReminder(
    DailyReminderSchedule reminder, {
    required int position,
  }) async {
    await init();
    await requestPermissions();

    final frequency = reminder.frequency.trim().toLowerCase();
    final (scheduledDate, matchComponents) = switch (frequency) {
      'several times a week' => (
        _nextWeeklyInstance(
          reminder.hour,
          reminder.minute,
          const [
            DateTime.monday,
            DateTime.wednesday,
            DateTime.friday,
          ][position % 3],
        ),
        DateTimeComponents.dayOfWeekAndTime,
      ),
      'occasionally' => (
        _nextWeeklyInstance(reminder.hour, reminder.minute, DateTime.monday),
        DateTimeComponents.dayOfWeekAndTime,
      ),
      _ => (
        _nextDailyInstance(reminder.hour, reminder.minute),
        DateTimeComponents.time,
      ),
    };

    await _plugin.zonedSchedule(
      id: reminder.id,
      title: reminder.title,
      body: reminder.body,
      scheduledDate: scheduledDate,
      notificationDetails: _notificationDetails(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: matchComponents,
    );
  }

  Future<void> scheduleDefaultDailyReminders() async {
    final reminders = await loadDailyReminderSchedules();
    final randomGwynReminder = await _randomGwynReminderText();

    for (final reminder in reminders) {
      if (reminder.isEnabled) {
        await scheduleDailyReminder(
          id: reminder.id,
          title: reminder.title,
          body: reminder.id == 1001 ? randomGwynReminder : reminder.body,
          hour: reminder.hour,
          minute: reminder.minute,
        );
      } else {
        await cancelReminder(reminder.id);
      }
    }
  }

  Future<List<DailyReminderSchedule>> loadDailyReminderSchedules() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonText = prefs.getString(_reminderSchedulesKey);
    if (jsonText == null) {
      return [_dailyGwynReminder(body: await _randomGwynReminderText())];
    }

    try {
      final decoded = jsonDecode(jsonText) as List<dynamic>;
      final reminders = decoded
          .map(
            (item) =>
                DailyReminderSchedule.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      if (reminders.isEmpty) {
        return [_dailyGwynReminder(body: await _randomGwynReminderText())];
      }

      final migrated = prefs.getBool(_dailyGwynReminderMigrationKey) ?? false;
      if (!migrated) {
        final migratedReminders = [
          _dailyGwynReminder(body: await _randomGwynReminderText()),
          ...reminders.where(
            (reminder) =>
                reminder.id != 1001 &&
                reminder.id != 1002 &&
                reminder.id != 1003,
          ),
        ];
        await saveDailyReminderSchedules(migratedReminders);
        await prefs.setBool(_dailyGwynReminderMigrationKey, true);
        return migratedReminders;
      }

      return reminders;
    } catch (error) {
      debugPrint('Reminder schedule fallback to defaults: $error');
      return [_dailyGwynReminder(body: await _randomGwynReminderText())];
    }
  }

  Future<List<String>> loadDailyGwynReminderTexts() async {
    try {
      final jsonText = await rootBundle.loadString(_dailyGwynReminderAssetPath);
      final decoded = jsonDecode(jsonText) as List<dynamic>;
      return decoded
          .map((item) => '$item'.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    } catch (error) {
      debugPrint('Gwyn reminder text fallback to defaults: $error');
      return defaultDailyReminders.map((reminder) => reminder.body).toList();
    }
  }

  Future<String> _randomGwynReminderText() async {
    final reminders = await loadDailyGwynReminderTexts();
    if (reminders.isEmpty) return defaultDailyReminders.first.body;

    return reminders[Random().nextInt(reminders.length)];
  }

  DailyReminderSchedule _dailyGwynReminder({required String body}) {
    return DailyReminderSchedule(
      id: 1001,
      title: 'Gwyn reminder',
      body: body,
      hour: 9,
      minute: 0,
      isEnabled: true,
    );
  }

  Future<void> saveDailyReminderSchedules(
    List<DailyReminderSchedule> reminders,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _reminderSchedulesKey,
      jsonEncode(reminders.map((reminder) => reminder.toJson()).toList()),
    );
  }

  List<DailyReminderSchedule> defaultPlanReminderSchedules(String planType) {
    final normalizedType = planType.trim().toLowerCase();
    final baseId = switch (normalizedType) {
      'cope' => 2100,
      'understand' => 2200,
      'heal' => 2300,
      _ => 2400,
    };
    final planLabel = switch (normalizedType) {
      'cope' => 'Cope',
      'understand' => 'Understand',
      'heal' => 'Heal',
      _ => 'Daily',
    };

    return [
      DailyReminderSchedule(
        id: baseId + 1,
        title: '$planLabel plan: Morning',
        body: 'Start your morning activity in the $planLabel plan.',
        hour: 9,
        minute: 0,
        isEnabled: true,
      ),
      DailyReminderSchedule(
        id: baseId + 2,
        title: '$planLabel plan: Noon',
        body: 'Take a moment for your noon $planLabel activity.',
        hour: 12,
        minute: 0,
        isEnabled: true,
      ),
      DailyReminderSchedule(
        id: baseId + 3,
        title: '$planLabel plan: Evening',
        body: 'Complete your evening activity in the $planLabel plan.',
        hour: 19,
        minute: 0,
        isEnabled: true,
      ),
    ];
  }

  List<DailyReminderSchedule> copePlanReminderSchedules({
    required String frequency,
    required List<String> feelings,
    required String trigger,
    String additionalInfo = '',
  }) {
    final normalizedFrequency = frequency.trim().isEmpty
        ? 'Daily'
        : frequency.trim();
    final normalizedFeelings = feelings
        .map((feeling) => feeling.trim())
        .where((feeling) => feeling.isNotEmpty)
        .toList();
    final feelingsText = normalizedFeelings.isEmpty
        ? 'Notice what you feel when anxiety appears.'
        : 'When anxiety appears, you may feel ${normalizedFeelings.join(', ')}.';
    final normalizedTrigger = trigger.trim().isEmpty
        ? 'your usual trigger'
        : trigger.trim();
    final normalizedAdditionalInfo = additionalInfo.trim();
    final combinedText = [
      feelingsText,
      'Your trigger is $normalizedTrigger.',
      if (normalizedAdditionalInfo.isNotEmpty) normalizedAdditionalInfo,
    ].join(' ');
    final times = switch (normalizedFrequency.toLowerCase()) {
      'multiple times every day' || 'multiple times a day' => const [
        (8, 0),
        (10, 0),
        (12, 0),
        (14, 0),
        (17, 0),
        (20, 0),
      ],
      'daily' => const [(9, 0), (14, 0), (19, 0)],
      'several times a week' => const [(9, 0), (9, 0), (9, 0)],
      _ => const [(9, 0)],
    };

    return times.indexed
        .map(
          (entry) => DailyReminderSchedule(
            id: 2101 + entry.$1,
            title: 'Cope reminder',
            body: combinedText,
            hour: entry.$2.$1,
            minute: entry.$2.$2,
            isEnabled: true,
            frequency: normalizedFrequency,
          ),
        )
        .toList();
  }

  Future<List<DailyReminderSchedule>> loadPlanReminderSchedules(
    String planType,
  ) async {
    final normalizedType = planType.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final key = '${_planReminderSchedulesKeyPrefix}_$normalizedType';
    final jsonText = prefs.getString(key);
    if (jsonText == null) {
      final defaults = defaultPlanReminderSchedules(normalizedType);
      await savePlanReminderSchedules(normalizedType, defaults);
      return defaults;
    }

    try {
      final decoded = jsonDecode(jsonText) as List<dynamic>;
      final schedules = decoded
          .map(
            (item) =>
                DailyReminderSchedule.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      return schedules;
    } catch (error) {
      debugPrint('Plan reminder schedule fallback to defaults: $error');
      return defaultPlanReminderSchedules(normalizedType);
    }
  }

  Future<void> savePlanReminderSchedules(
    String planType,
    List<DailyReminderSchedule> reminders,
  ) async {
    final normalizedType = planType.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final key = '${_planReminderSchedulesKeyPrefix}_$normalizedType';
    await prefs.setString(
      key,
      jsonEncode(reminders.map((reminder) => reminder.toJson()).toList()),
    );
  }

  Future<void> cancelReminder(int id) async {
    await init();
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> pendingNotifications() async {
    await init();
    return _plugin.pendingNotificationRequests();
  }

  Future<void> _configureLocalTimeZone() async {
    if (kIsWeb) return;

    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (error) {
      debugPrint('Notification timezone fallback to UTC: $error');
      tz.setLocalLocation(tz.UTC);
    }
  }

  tz.TZDateTime _nextDailyInstance(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  tz.TZDateTime _nextWeeklyInstance(int hour, int minute, int weekday) {
    final now = tz.TZDateTime.now(tz.local);
    final daysAhead = (weekday - now.weekday) % 7;
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysAhead,
      hour,
      minute,
    );
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }
    return scheduledDate;
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Gwyn reminder',
    );

    const darwinDetails = DarwinNotificationDetails();

    return const NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );
  }
}

List<DailyReminderSchedule> enableAllReminderSchedules(
  Iterable<DailyReminderSchedule> reminders,
) {
  return reminders
      .map(
        (reminder) => DailyReminderSchedule(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
          hour: reminder.hour,
          minute: reminder.minute,
          isEnabled: true,
          frequency: reminder.frequency,
        ),
      )
      .toList();
}

class DailyReminderSchedule {
  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final bool isEnabled;
  final String frequency;

  const DailyReminderSchedule({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.isEnabled = false,
    this.frequency = 'Daily',
  });

  factory DailyReminderSchedule.fromJson(Map<String, dynamic> json) {
    return DailyReminderSchedule(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Reminder',
      body: json['body'] as String? ?? '',
      hour: json['hour'] as int? ?? 9,
      minute: json['minute'] as int? ?? 0,
      isEnabled: json['isEnabled'] as bool? ?? false,
      frequency: json['frequency'] as String? ?? 'Daily',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'hour': hour,
      'minute': minute,
      'isEnabled': isEnabled,
      'frequency': frequency,
    };
  }
}
