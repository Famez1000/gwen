import 'package:flutter_test/flutter_test.dart';
import 'package:gwen/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('enables every reminder when a plan is activated', () {
    const reminders = [
      DailyReminderSchedule(
        id: 1,
        title: 'First',
        body: 'First reminder',
        hour: 9,
        minute: 0,
      ),
      DailyReminderSchedule(
        id: 2,
        title: 'Second',
        body: 'Second reminder',
        hour: 15,
        minute: 30,
        isEnabled: true,
        frequency: 'Several times a week',
      ),
    ];

    final enabled = enableAllReminderSchedules(reminders);

    expect(enabled, hasLength(reminders.length));
    expect(enabled.every((reminder) => reminder.isEnabled), isTrue);
    expect(enabled.map((reminder) => reminder.id), [1, 2]);
    expect(enabled.last.frequency, 'Several times a week');
  });

  test('keeps a reduced reminder list after a reminder is deleted', () async {
    SharedPreferences.setMockInitialValues({});
    const remainingReminder = DailyReminderSchedule(
      id: 2201,
      title: 'Remaining reminder',
      body: 'This reminder was not deleted.',
      hour: 9,
      minute: 0,
      isEnabled: true,
    );

    await NotificationService.instance.savePlanReminderSchedules(
      'understand',
      [remainingReminder],
    );
    final loaded = await NotificationService.instance
        .loadPlanReminderSchedules('understand');

    expect(loaded, hasLength(1));
    expect(loaded.single.id, remainingReminder.id);
  });

  test('builds three personalized Cope reminders from planning answers', () {
    final reminders = NotificationService.instance.copePlanReminderSchedules(
      frequency: 'Several times a week',
      feelings: ['Racing thoughts', 'Tight chest'],
      trigger: 'Work',
      additionalInfo: 'Especially before presentations.',
    );

    expect(reminders, hasLength(3));
    expect(
      reminders.every(
        (reminder) => reminder.frequency == 'Several times a week',
      ),
      isTrue,
    );
    expect(
      reminders.every(
        (reminder) =>
            reminder.body.contains('Racing thoughts, Tight chest') &&
            reminder.body.contains('Work') &&
            reminder.body.contains('Especially before presentations.'),
      ),
      isTrue,
    );
  });

  test('omits optional context from the trigger reminder when unanswered', () {
    final reminders = NotificationService.instance.copePlanReminderSchedules(
      frequency: 'Daily',
      feelings: ['Dizziness'],
      trigger: 'Crowds',
    );

    expect(reminders, hasLength(3));
    expect(
      reminders.first.body,
      'When anxiety appears, you may feel Dizziness. Your trigger is Crowds.',
    );
    expect(
      DailyReminderSchedule.fromJson(reminders.first.toJson()).frequency,
      'Daily',
    );
  });

  test('maps Cope frequency answers to the required reminder count', () {
    List<DailyReminderSchedule> remindersFor(String frequency) {
      return NotificationService.instance.copePlanReminderSchedules(
        frequency: frequency,
        feelings: ['Racing thoughts'],
        trigger: 'Work',
      );
    }

    expect(remindersFor('Multiple times every day'), hasLength(6));
    expect(remindersFor('Daily'), hasLength(3));
    expect(remindersFor('Several times a week'), hasLength(3));
    expect(remindersFor('Occasionally'), hasLength(1));
  });
}
