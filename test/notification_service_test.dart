import 'package:flutter_test/flutter_test.dart';
import 'package:gwen/core/services/notification_service.dart';

void main() {
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
