import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:routine/domain/routine_item.dart';
import 'package:routine/services/reminder_notification_service.dart';

void main() {
  RoutineItem reminder({
    String date = '2026-07-20',
    String time = '08:00 AM',
    String recurrence = 'none',
    int? prepOffset,
    List<int>? repeatDays,
  }) {
    return RoutineItem(
      id: 'reminder-1',
      title: 'Clock in',
      itemType: 'reminder',
      category: 'work',
      timeOfDay: 'morning',
      scheduledTime: time,
      scheduledDate: date,
      recurrenceRule: recurrence,
      notificationsEnabled: true,
      prepOffsetMinutes: prepOffset,
      repeatDays: repeatDays,
    );
  }

  test('creates a one-time reminder for a future scheduled item', () {
    final schedule = ReminderNotificationService.scheduleFor(
      reminder(),
      now: DateTime(2026, 7, 20, 7),
    );

    expect(schedule, isNotNull);
    expect(schedule!.dateTime, DateTime(2026, 7, 20, 8));
    expect(schedule.recurrenceComponents, isNull);
  });

  test('does not schedule an expired one-time reminder', () {
    final schedule = ReminderNotificationService.scheduleFor(
      reminder(),
      now: DateTime(2026, 7, 20, 9),
    );

    expect(schedule, isNull);
  });

  test('advances daily and weekly reminders to their next occurrence', () {
    final daily = ReminderNotificationService.scheduleFor(
      reminder(recurrence: 'daily'),
      now: DateTime(2026, 7, 22, 9),
    );
    final weekly = ReminderNotificationService.scheduleFor(
      reminder(recurrence: 'weekly'),
      now: DateTime(2026, 7, 21, 9),
    );

    expect(daily!.dateTime, DateTime(2026, 7, 23, 8));
    expect(daily.recurrenceComponents, DateTimeComponents.time);
    expect(weekly!.dateTime, DateTime(2026, 7, 27, 8));
    expect(weekly.recurrenceComponents, DateTimeComponents.dayOfWeekAndTime);
  });

  test('daily repeat with selected days skips unselected weekdays', () {
    // 2026-07-20 is a Monday. Repeat Tue(2), Thu(4), Sat(6).
    final schedule = ReminderNotificationService.scheduleFor(
      reminder(recurrence: 'daily', repeatDays: [2, 4, 6]),
      now: DateTime(2026, 7, 22, 9),
    );

    expect(schedule!.dateTime, DateTime(2026, 7, 23, 8));
    expect(schedule.recurrenceComponents, isNull);
  });

  test('daily repeat with all days selected uses a repeating component', () {
    final schedule = ReminderNotificationService.scheduleFor(
      reminder(recurrence: 'daily', repeatDays: [1, 2, 3, 4, 5, 6, 7]),
      now: DateTime(2026, 7, 22, 9),
    );

    expect(schedule!.recurrenceComponents, DateTimeComponents.time);
  });

  test('advances monthly reminders to the same day next month', () {
    final schedule = ReminderNotificationService.scheduleFor(
      reminder(recurrence: 'monthly'),
      now: DateTime(2026, 8, 5, 9),
    );

    expect(schedule!.dateTime, DateTime(2026, 8, 20, 8));
    expect(schedule.recurrenceComponents, DateTimeComponents.dayOfMonthAndTime);
  });

  test('monthly reminder skips months that lack the anchor day', () {
    // Anchor day 31 has no occurrence in February.
    final schedule = ReminderNotificationService.scheduleFor(
      reminder(date: '2026-01-31', recurrence: 'monthly'),
      now: DateTime(2026, 2, 10, 9),
    );

    expect(schedule!.dateTime, DateTime(2026, 3, 31, 8));
  });

  test('maps daily and monthly actions to their closest occurrence', () {
    final daily = reminder(recurrence: 'daily', repeatDays: [2, 4, 6]);
    final monthly = reminder(recurrence: 'monthly');

    expect(
      ReminderNotificationService.occurrenceDateForAction(
        daily,
        now: DateTime(2026, 7, 23, 8),
      ),
      '2026-07-23',
    );
    expect(
      ReminderNotificationService.occurrenceDateForAction(
        monthly,
        now: DateTime(2026, 8, 20, 8),
      ),
      '2026-08-20',
    );
  });

  test('maps a cross-midnight preparation action to its target date', () {
    final item = reminder(
      date: '2026-07-20',
      time: '12:05 AM',
      recurrence: 'daily',
      prepOffset: 10,
    );

    expect(
      ReminderNotificationService.occurrenceDateForAction(
        item,
        now: DateTime(2026, 7, 20, 23, 55),
      ),
      '2026-07-21',
    );
  });

  test('applies preparation lead time and creates stable notification IDs', () {
    final schedule = ReminderNotificationService.scheduleFor(
      reminder(prepOffset: 10),
      now: DateTime(2026, 7, 20, 7),
    );

    expect(schedule!.dateTime, DateTime(2026, 7, 20, 7, 50));
    expect(
      ReminderNotificationService.notificationIdFor('reminder-1'),
      ReminderNotificationService.notificationIdFor('reminder-1'),
    );
    expect(
      ReminderNotificationService.notificationIdFor('reminder-1'),
      isNot(ReminderNotificationService.notificationIdFor('reminder-2')),
    );
    expect(
      ReminderNotificationService.snoozeNotificationIdFor('reminder-1'),
      isNot(ReminderNotificationService.notificationIdFor('reminder-1')),
    );
  });
}
