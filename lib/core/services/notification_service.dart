import 'dart:convert';

import 'package:flutter/foundation.dart';
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
      title: 'Morning check-in',
      body: 'Pause, name your mood, and set one gentle intention.',
      hour: 8,
      minute: 30,
      isEnabled: true,
    ),
    DailyReminderSchedule(
      id: 1002,
      title: 'Breathing break',
      body: 'Take two minutes to loosen your jaw and slow your exhale.',
      hour: 13,
      minute: 0,
      isEnabled: true,
    ),
    DailyReminderSchedule(
      id: 1003,
      title: 'Evening reflection',
      body: 'Write one thing you handled today, even if it was small.',
      hour: 20,
      minute: 0,
    ),
  ];

  static const String _channelId = 'daily_calm_reminders';
  static const String _channelName = 'Daily calm reminders';
  static const String _channelDescription =
      'Gentle daily reminders to pause, breathe, and check in.';
  static const String _reminderSchedulesKey = 'daily_reminder_schedules';

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

  Future<void> scheduleDefaultDailyReminders() async {
    final reminders = await loadDailyReminderSchedules();

    for (final reminder in reminders) {
      if (reminder.isEnabled) {
        await scheduleDailyReminder(
          id: reminder.id,
          title: reminder.title,
          body: reminder.body,
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
    if (jsonText == null) return List.of(defaultDailyReminders);

    try {
      final decoded = jsonDecode(jsonText) as List<dynamic>;
      final reminders = decoded
          .map(
            (item) =>
                DailyReminderSchedule.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
      return reminders.isEmpty ? List.of(defaultDailyReminders) : reminders;
    } catch (error) {
      debugPrint('Reminder schedule fallback to defaults: $error');
      return List.of(defaultDailyReminders);
    }
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

class DailyReminderSchedule {
  final int id;
  final String title;
  final String body;
  final int hour;
  final int minute;
  final bool isEnabled;

  const DailyReminderSchedule({
    required this.id,
    required this.title,
    required this.body,
    required this.hour,
    required this.minute,
    this.isEnabled = false,
  });

  factory DailyReminderSchedule.fromJson(Map<String, dynamic> json) {
    return DailyReminderSchedule(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Reminder',
      body: json['body'] as String? ?? '',
      hour: json['hour'] as int? ?? 9,
      minute: json['minute'] as int? ?? 0,
      isEnabled: json['isEnabled'] as bool? ?? false,
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
    };
  }
}
